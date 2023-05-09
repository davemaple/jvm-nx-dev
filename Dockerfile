FROM ubuntu:22.10

# set versions here
ENV NVM_VERSION 19.8.1
ENV GRADLE_VERSION 7.6.1
ENV GRAALVM_VERSION 22.3.1

# set paths here
ENV NVM_DIR /opt/nvm
ENV GRADLE_HOME=/opt/gradle

ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C.UTF-8

RUN echo 'Setting up .bash_profile ...'
RUN touch /root/.bash_profile
RUN chmod 600 /root/.bash_profile
RUN echo -n ". /root/.bashrc\n" >> /root/.bash_profile
RUN exec bash && . /root/.bash_profile

RUN echo 'updating and installing apt packages ...'
RUN apt-get update --fix-missing

RUN echo 'Installing apt packages ...'
RUN apt-get install -y \
  apt-utils \
  apt-transport-https \
  jq \
  git \
  lsof \
  curl \
  wget \
  nano \
  zip \
  unzip \
  redis \
  zsh \
  openjdk-11-jdk \
  redis \
  mysql-client \
  ca-certificates \
  curl \
  gnupg

RUN echo 'Add github.com to known hosts ...'
RUN mkdir $HOME/.ssh/
RUN touch $HOME/.ssh/known_hosts
RUN ssh-keyscan -t rsa github.com >> $HOME/.ssh/known_hosts

RUN echo 'Installing the official Docker key ...'
RUN install -m 0755 -d /etc/apt/keyrings
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
RUN chmod a+r /etc/apt/keyrings/docker.gpg

RUN echo 'Installing Docker ...'
RUN apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

RUN echo 'installing GraalVM ...'
RUN cd /root && wget https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-$GRAALVM_VERSION/graalvm-ce-java11-linux-amd64-$GRAALVM_VERSION.tar.gz
RUN cd /root && tar -xvzf graalvm-ce-*
RUN cd /root && ls -al
RUN mv /root/graalvm-ce-java11-$GRAALVM_VERSION /usr/lib/jvm/graalvm
RUN update-alternatives --install "/usr/bin/java" "java" "/usr/lib/jvm/graalvm/bin/java" 1
RUN update-alternatives --install "/usr/bin/javac" "javac" "/usr/lib/jvm/graalvm/bin/javac" 1
RUN update-alternatives --set java /usr/lib/jvm/graalvm/bin/java
RUN update-alternatives --set javac /usr/lib/jvm/graalvm/bin/javac
ENV JAVA_HOME=/usr/lib/jvm/graalvm
ENV PATH=/usr/lib/jvm/graalvm/bin:$PATH
RUN echo 'java -version'
RUN java -version

RUN echo 'Installing gradle ...'
RUN cd /root && wget -c https://services.gradle.org/distributions/gradle-$GRADLE_VERSION-bin.zip \
    && unzip "/root/gradle-$GRADLE_VERSION-bin.zip" -d /opt \
    && ln -s "/opt/gradle-$GRADLE_VERSION" /opt/gradle \
    && rm "/root/gradle-$GRADLE_VERSION-bin.zip" \
    && mkdir -p /root/.gradle
ENV PATH=$GRADLE_HOME/bin:$PATH
RUN echo 'gradle --version'
RUN gradle --version

RUN echo 'Installing nvm ...'
RUN echo -n "\nexport NVM_DIR=/opt/nvm\n" >> /root/.bashrc
RUN mkdir -p $NVM_DIR
RUN curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install $NVM_VERSION \
    && nvm alias default $NVM \
    && nvm use default \
    && npm install -g npm \
    && npm install -g yarn \
    && npm install -g nx \
    && npm install -g aws-cdk
ENV NODE_PATH $NVM_DIR/versions/node/$NODE_VERSION/bin
ENV PATH $NODE_PATH:$PATH

RUN echo 'Installing ohmyzsh ...'
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
RUN chsh -s /bin/zsh
RUN echo 'zsh --version'
RUN zsh --version

RUN echo 'Install MySQL ...'
RUN echo "mysql-server mysql-server/root_password password password" | debconf-set-selections
RUN echo "mysql-server mysql-server/root_password_again password password" | debconf-set-selections
RUN apt-get -y install mysql-server
RUN usermod -d /var/lib/mysql/ mysql
RUN /etc/init.d/mysql start \
    && mysql --user root --password=password -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'password';"

# Run zsh on container start
SHELL ["/bin/zsh", "--login", "-c"]
