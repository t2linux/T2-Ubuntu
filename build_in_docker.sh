#!/bin/bash

set -eu -o pipefail

DOCKER_IMAGE=ubuntu:20.04

docker pull ${DOCKER_IMAGE}

VERSION=5
ALTERNATIVE=mbp
LATEST_BUILD=$(curl -s https://mbp-ubuntu-kernel.herokuapp.com/ -L |
           grep "linux-image-${VERSION}" | grep ${ALTERNATIVE} |
           grep a | cut -d'>' -f2 | cut -d'<' -f1 |sort -r | head -n 1 | cut -d'_' -f1 |
           cut -d'-' -f 3-20)
echo "Using kernel ${LATEST_BUILD}"

docker run \
  --privileged \
  --rm \
  -t \
  -v "$(pwd)":/repo \
  ${DOCKER_IMAGE} \
  /bin/bash -c "cd /repo && KERNEL_VERSION=${LATEST_BUILD} ./build.sh"
