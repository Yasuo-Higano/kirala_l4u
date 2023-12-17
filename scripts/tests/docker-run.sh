#!/bin/bash

IMAGE_NAME=${IMAGE_NAME:-l4u-test-ubuntu-utopic}
GIT_TOP=$(git rev-parse --show-toplevel)
 
docker run -it --rm -u ${EUID} \
    --volume=${GIT_TOP}:/l4u \
    ${IMAGE_NAME} \
    "${@}"
