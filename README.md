# Docker images with SGDK

## Building Docker images

### Building Docker image based on Ubuntu
```shell-script
docker build -t gstolarz/sgdk -t gstolarz/sgdk:1.62 \
  --build-arg SGDK_VERSION=1.62 .
```

### Building Docker image based on Alpine
```shell-script
docker build -t gstolarz/sgdk:alpine -t gstolarz/sgdk:1.62-alpine \
  --build-arg SGDK_VERSION=1.62 -f Dockerfile-alpine .
```
