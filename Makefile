SGDK_VERSION=1.90

BINUTILS_VERSION=2.41
GCC_VERSION=13.2.0
NEWLIB_VERSION=4.1.0

DOCKER_USERNAME=gstolarz
TAG_NAME=sgdk:${SGDK_VERSION}


build:
	docker build . \
	-t sgdk:${SGDK_VERSION} \
  	--build-arg SGDK_VERSION=${SGDK_VERSION} \
  	--build-arg BINUTILS_VERSION=${BINUTILS_VERSION} \
  	--build-arg GCC_VERSION=${GCC_VERSION} \
  	--build-arg NEWLIB_VERSION=${NEWLIB_VERSION}

build-alpine:
	docker build . \
	-t sgdk:${SGDK_VERSION}-alpine \
  	--build-arg SGDK_VERSION=${SGDK_VERSION} \
	--build-arg BINUTILS_VERSION=${BINUTILS_VERSION} \
  	--build-arg GCC_VERSION=${GCC_VERSION} \
  	--build-arg NEWLIB_VERSION=${NEWLIB_VERSION} \
	-f Dockerfile-alpine

tag:
	docker tag ${TAG_NAME} ${DOCKER_USERNAME}/${TAG_NAME}

push: 	tag
	docker push ${DOCKER_USERNAME}/${TAG_NAME}