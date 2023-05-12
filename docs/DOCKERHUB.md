### dockerhub 

- [https://hub.docker.com/r/gamindev/jvm-nx-dev](https://hub.docker.com/r/gamindev/jvm-nx-dev)

```bash
docker buildx build --no-cache --progress=plain --platform linux/amd64 -t jvm-nx-dev:latest .
docker tag jvm-nx-dev:latest gamindev/jvm-nx-dev:latest
docker tag jvm-nx-dev:latest gamindev/jvm-nx-dev:v1.0.0
docker push gamindev/jvm-nx-dev:latest
docker push gamindev/jvm-nx-dev:v1.0.0
git tag -af v1.0.0 -m "$( date '+%F_%H:%M:%S' )] gamindev/jvm-nx-dev:v1.0.0"
git push origin v1.0.0
```
