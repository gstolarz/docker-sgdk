# Docker images with SGDK

## Building Docker images

### Building Docker image based on Ubuntu
```shell
make build
```

### Building Docker image based on Alpine
```shell
make build-alpine
```

### How to use

```shell
SGDK_VERSION=1.90
SGDK_PROJECT_PATH="~/my-sgdk-project"
SGDK_PROJECT_COMPILER_CMD="g++ main.cpp -o main -g `pkg-config --cflags --static --libs allegro`"
docker run -v $SGDK_PROJECT_PATH:/tmp/workdir \
-w /tmp/workdir \
-ti gstolarz/sgdk:$SGDK_VERSION \
bash -c "$SGDK_PROJECT_COMPILER_CMD"
```