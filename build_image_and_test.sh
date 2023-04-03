#!/bin/bash

IMAGE_NAME=icinga2_with_mms
IMAGE_TAG=$(date +%Y%m%d-%H%M%S)
DIR_DATA="/tmp/test_data"

docker container rm -f mms-master
docker volume rm -f icinga
docker volume create icinga
docker network rm --force icinga
docker network create icinga
docker image rm --force ${IMAGE_NAME}:${IMAGE_TAG}
rm -rf "${DIR_DATA}"

docker build -t ${IMAGE_NAME}:${IMAGE_TAG} . \
	&& (docker image rm ${IMAGE_NAME}:latest || true) \
	&& docker image tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest \
	&& docker run -it \
		--network icinga \
		--name mms-master \
		-h mms-master \
		-p 5665:5665 \
		-v icinga:/data:rw \
		-e ICINGA_MASTER=1 \
		${IMAGE_NAME}:${IMAGE_TAG} bash

#&& docker run --rm -it ${IMAGE_NAME}:${IMAGE_TAG} bash
