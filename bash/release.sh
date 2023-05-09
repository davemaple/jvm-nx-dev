#!/bin/sh

# ensure this is being run from a git repository
[ -d ".git" ] || {
  echo "$(pwd) is not a git repository."
  exit 1
}

# ensure we have the supporting binaries installed
for binary in awk basename cat curl jq git touch; do
  command -v "${binary}" >/dev/null || {
    echo "${binary} is required to run this script. Install it and try again."
    exit 1
  }
done

# GitHub stuff
GITHUB_ORGANIZATION=$(awk '/url/{print $NF}' .git/config | rev | cut -d '/' -f 2 | rev)
GITHUB_REPOSITORY=$(basename -s .git "$(awk '/url/{print $NF}' .git/config)")
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
GIT_MAIN_BRANCH="main"


REGEX_CONVENTIONAL_COMMITS='^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test).*:*$'
REGEX_MAJOR='BREAKING.CHANGE'
REGEX_MINOR='^feat'
REGEX_PATCH='^fix'


# ---- VERIFY WE CAN PUSH ----
git push --dry-run origin || {
  echo "Github permissions issue -- can't push to ${GITHUB_REPOSITORY}."
  exit 1
}

# ---- INIT TAG ----
LATEST_TAG=""
NEXT_TAG=""
NEXT_VERSION=""
PRE_RELEASE_REGEX=$([ "${GIT_MAIN_BRANCH}" != "${GIT_BRANCH}" ] && echo "^true" || echo "^false")
PRE_RELEASE_BOOLEAN=$(echo "${PRE_RELEASE_REGEX}" | awk '{print substr($0,2,length($0)-1)}')
TAGS=$(curl --silent -H "Authorization: token ${GH_TOKEN}" "${GITHUB_REPOS_URL}/${GITHUB_ORGANIZATION}/${GITHUB_REPOSITORY}/releases" | jq -j '.[]| .name,"|",.prerelease,"\n"' | awk 'BEGIN{FS="|"}$1 ~ /^v[0-9]+\.[0-9]+\.[0-9]+$/{printf("%s,",$0)}')

[ -z "${TAGS}" ] && {
  echo "$(date)][INIT_TAG]: no previous semVer releases found."
  NEXT_VERSION="1.0.0"
  NEXT_TAG="v1.0.0"
  GIT_ARG=""
  echo "$(date)][INIT_TAG]: Next release version will be ${NEXT_VERSION} tagged: ${NEXT_TAG} ."
} || {
  LATEST_TAG=$(echo "${TAGS}" | awk -v preRelease="${PRE_RELEASE_REGEX}" 'BEGIN{FS="|";RS=","} $2 ~ preRelease {print $1; exit}')
  GIT_ARG="${LATEST_TAG}"..HEAD
  echo "$(date)][INIT_TAG]: previous semVer releases found, Lates tag : ${LATEST_TAG}"
}

# ---- INIT DATA ----
SHAS=$(git log ${GIT_ARG} --format="%H %s%b" | awk -v REGEX_CONVENTIONAL_COMMITS="${REGEX_CONVENTIONAL_COMMITS}" '$2 ~ REGEX_CONVENTIONAL_COMMITS {printf("%s|",$1)}')
COMMENTS=$(git log ${GIT_ARG} --format="%H %s%b" | awk -v REGEX_CONVENTIONAL_COMMITS="${REGEX_CONVENTIONAL_COMMITS}" '$2 ~ REGEX_CONVENTIONAL_COMMITS {for(i=2;i<=NF;++i)printf("%s ",$i); printf("|")}')

# ---- CALCULATING NEXT VERSION ----
CURRENT_MAJOR=$(echo "${LATEST_TAG}" | awk 'BEGIN{FS="."}{print substr($1,2,length($1)-1)}')
CURRENT_MINOR=$(echo "${LATEST_TAG}" | awk 'BEGIN{FS="."}{print $2}')
CURRENT_PATCH=$(echo "${LATEST_TAG}" | awk 'BEGIN{FS="."}{print $3}')
[ -z "${NEXT_VERSION}" ] && NEXT_VERSION=$(echo "${COMMENTS}" | awk -v REGEX_MINOR=${REGEX_MINOR} -v REGEX_MAJOR=${REGEX_MAJOR} -v REGEX_PATCH=${REGEX_PATCH} \
  -v CURRENT_MAJOR="${CURRENT_MAJOR}" -v CURRENT_MINOR="${CURRENT_MINOR}" -v CURRENT_PATCH="${CURRENT_PATCH}" '
BEGIN{RS="|"}
{
  if ($0 ~ REGEX_MAJOR){
    CURRENT_MAJOR++;
    CURRENT_MINOR=0;
    CURRENT_MINOR=0;
  }
  else if ($0 ~ REGEX_MINOR){
    CURRENT_MINOR++;
    CURRENT_PATCH=0;
  }
  else if ($0 ~ REGEX_PATCH){
    CURRENT_PATCH++
  }
}
END{printf("%s.%s.%s",CURRENT_MAJOR,CURRENT_MINOR,CURRENT_PATCH)}')
NEXT_TAG="v${NEXT_VERSION}"
[ "${LATEST_TAG}" = "${NEXT_TAG}" ] && {
  echo "[TAGS]: Nothing new to release."
  exit 0
}
echo "[TAGS]: Next release version will be ${NEXT_VERSION} tagged: ${NEXT_TAG} ."

# ---- GENERATE CHANGELOG ----
echo "[CHANGELOG]: generating CHANGELOG ."
CHANGE_LOG=$(echo "${COMMENTS}" | awk -v REGEX_MINOR="${REGEX_MINOR}" -v REGEX_MAJOR="${REGEX_MAJOR}" -v REGEX_PATCH="${REGEX_PATCH}" -v LATEST_TAG="${LATEST_TAG}" \
  -v NEXT_TAG="${NEXT_TAG}" -v NEXT_VERSION="${NEXT_VERSION}" -v SHAS="${SHAS}" -v DATE="$(date +%d-%m-%Y)" -v COMMIT_URL="${GITHUB_COMMIT_URL}" -v COMPARE_URL="${COMPARE_URL}" '
BEGIN{
  RS="|";
  FS=": ";
  split(SHAS,SHAS_TABLE,"|");
  i=1
  }
{
  if ($0 ~ REGEX_MAJOR){
    MAJOR_TABLE[SHAS_TABLE[i]]=$2
  }
  else if ($0 ~ REGEX_MINOR){
    MINOR_TABLE[SHAS_TABLE[i]]=$2
  }
  else if ($0 ~ REGEX_PATCH){
    PATCH_TABLE[SHAS_TABLE[i]]=$2
  }
  i++
}
END{
  if (NEXT_TAG == "v1.0.0"){
    printf("# %s (%s)|",NEXT_VERSION,DATE)
  } else{
    printf("# [%s](%s/%s..%s) (%s)|",NEXT_VERSION,COMPARE_URL,LATEST_TAG,NEXT_TAG,DATE)
  }
  if (length(MAJOR_TABLE)!=0){
    printf("### Breaking change|");
    for (e in MAJOR_TABLE){
      printf("* %s [%s](%s/%s)|",MAJOR_TABLE[e],substr(e,0,7),COMMIT_URL,e)
    }
  }
  if (length(MAJOR_TABLE)!=0){
    printf("### Features|");
    for (e in MINOR_TABLE){
      printf("* %s [%s](%s/%s)|",MINOR_TABLE[e],substr(e,0,7),COMMIT_URL,e)
    }
  }
  if (length(PATCH_TABLE)!=0){
    printf("### Bug Fixes|");
    for (e in PATCH_TABLE){
      printf("* %s [%s](%s/%s)|",PATCH_TABLE[e],substr(e,0,7),COMMIT_URL,e)
    }
  }
}')
echo "$(date)][CHANGELOG]: CHANGELOG generated."

# CREATE OR UPDATE CHANGELOG.md
echo "$(date)][CHANGELOG]: Pushing CHANGELOG to ${GITHUB_REPOSITORY}."
RELEASE_COMMIT_COMMENT="chore(release): ${NEXT_VERSION} [skip ci]"
[ ! -f CHANGELOG.md ] && touch CHANGELOG.md
echo "${CHANGE_LOG}" | awk 'BEGIN{RS="|"}{print $0}' | cat -s - CHANGELOG.md >CHANGELOG.md.tmp && mv CHANGELOG.md.tmp CHANGELOG.md
git add CHANGELOG.md
git commit -m "${RELEASE_COMMIT_COMMENT}" -m "$(echo "${CHANGE_LOG}" | awk 'BEGIN{RS="|"}{print $0}')"
git push https://"${GH_TOKEN}":"${GH_TOKEN}"@github.com/"${GITHUB_ORGANIZATION}"/"${GITHUB_REPOSITORY}"

# ---- CREATE/PUSH TAG ----
echo "$(date)][TAGS]: Pushing new tag ${NEXT_TAG}."
git tag -a "${NEXT_TAG}" -m ""
git push --tags https://"${GH_TOKEN}":"${GH_TOKEN}"@github.com/"${GITHUB_ORGANIZATION}"/"${GITHUB_REPOSITORY}"

# ---- CREATE/PUSH RELEASE ----
cat <<SCRIPT >data.json.tmp
{
"tag_name":"${NEXT_TAG}",
"name":"${NEXT_TAG}",
"body": "$(echo "${CHANGE_LOG}" | awk 'BEGIN{RS="|"}{print $0"\\n"}')",
"draft":false,
"prerelease": ${PRE_RELEASE_BOOLEAN}
}
SCRIPT

echo "$(date)][RELEASE]: Pushing new release ${NEXT_VERSION}."
curl --silent -d "@data.json.tmp" -H "Authorization: token ${GH_TOKEN}" "${GITHUB_REPOS_URL}/${GITHUB_ORGANIZATION}/${GITHUB_REPOSITORY}/releases"

# ---- CLEANING-UP ----
rm -f data.json.tmp
