#!/bin/bash

IMAGE_NAME=icinga2_with_mms
IMAGE_TAG=latest

docker image rm --force ${IMAGE_NAME}:${IMAGE_TAG}

docker build -t ${IMAGE_NAME}:${IMAGE_TAG} . \
	&& docker run --rm -it ${IMAGE_NAME}:${IMAGE_TAG} bash

