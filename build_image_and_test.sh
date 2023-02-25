#!/bin/bash

IMAGE_NAME=icinga2_with_mms
IMAGE_TAG=latest
DIR_DATA="/tmp/test_data"

#docker volume rm -f icinga
docker volume create icinga
docker network rm --force icinga
docker network create icinga
docker image rm --force ${IMAGE_NAME}:${IMAGE_TAG}
rm -rf "${DIR_DATA}"

docker build -t ${IMAGE_NAME}:${IMAGE_TAG} . \
	&& docker run --rm -it \
		--network icinga \
		--name mms-master \
		-h mms-master \
		-p 5665:5665 \
		-v icinga:/data \
		-e ICINGA_MASTER=1 \
		${IMAGE_NAME}:${IMAGE_TAG} bash

#&& docker run --rm -it ${IMAGE_NAME}:${IMAGE_TAG} bash
