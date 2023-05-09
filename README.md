# Gradle/JVM Backend + NX Frontend 

- [dockerhub](https://hub.docker.com/r/gamindev/jvm-nx-dev)

*_This is a public repository, so any packages and modifications should be generally available to any developer._*

### build it with debug output
```bash
docker buildx build --no-cache --progress=plain --platform linux/amd64 -t jvm-nx-dev:latest .
```

### test stuff
```bash
docker run --platform linux/amd64 -it jvm-nx-dev:latest
```

### start services when using the container
```bash
/etc/init.d/mysql start
/etc/init.d/redis-server start
```
