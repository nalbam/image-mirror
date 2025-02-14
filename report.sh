#!/bin/bash

SHELL_DIR=$(dirname $0)

DEFAULT="opspresso/image-mirror"
REPOSITORY=${GITHUB_REPOSITORY:-$DEFAULT}

USERNAME=${GITHUB_ACTOR}
REPONAME=$(echo "${REPOSITORY}" | cut -d'/' -f2)

_init() {
  mkdir -p ${SHELL_DIR}/target
  mkdir -p ${SHELL_DIR}/versions
  mkdir -p ${SHELL_DIR}/.previous

  cp -rf ${SHELL_DIR}/versions/* ${SHELL_DIR}/.previous/
}

_check() {
  # check versions
  while read LINE; do
    _get_versions ${LINE}
  done <${SHELL_DIR}/checklist.txt
}

_get_versions() {
  NAME="$1"
  REPO="$2"
  BASE_IMAGE="${3}"
  IMAGE_NAME="${4}"
  STRIP="${5:-"false"}"
  PLATFORM="${6:-"linux/amd64,linux/arm64"}"
  BUILDX="${7:-"true"}"

  if [ "$NAME" == "#" ]; then
    return
  fi

  curl -sL https://api.github.com/repos/${REPO}/releases | jq '.[].tag_name' -r | grep -v '-' | head -10 \
    >${SHELL_DIR}/target/${NAME}

  COUNT=$(cat ${SHELL_DIR}/target/${NAME} | wc -l | xargs)

  if [ "x${COUNT}" != "x0" ]; then
    cp -rf ${SHELL_DIR}/target/${NAME} ${SHELL_DIR}/versions/${NAME}

    while read V1; do
      if [ -z "$V1" ]; then
        continue
      fi

      EXIST="false"
      if [ -f ${SHELL_DIR}/.previous/${NAME} ]; then
        while read V2; do
          if [ "$V1" == "$V2" ]; then
            EXIST="true"
            # echo "# ${NAME} ${V1} EXIST"
            continue
          fi
        done <${SHELL_DIR}/.previous/${NAME}
      fi

      echo "# version ${NAME} ${V1}"

      if [ "$EXIST" == "false" ]; then
        # send dispatch message
        if [ "$STRIP" == "true" ]; then
          _dispatch "${V1:1}"
        else
          _dispatch "${V1}"
        fi
      fi
    done <${SHELL_DIR}/versions/${NAME}
  fi
}

_dispatch() {
  if [ -z "${GITHUB_TOKEN}" ]; then
    return
  fi

  VERSION="$1"

  EVENT_TYPE="mirror"

  echo "# dispatch ${REPO} ${VERSION}"

  curl -sL -X POST \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -d "{\"event_type\":\"${EVENT_TYPE}\",\"client_payload\":{\"base_image\":\"${BASE_IMAGE}\",\"image_name\":\"${IMAGE_NAME}\",\"tag_name\":\"${VERSION}\",\"platform\":\"${PLATFORM}\",\"buildx\":\"${BUILDX}\"}}" \
    https://api.github.com/repos/${REPOSITORY}/dispatches
}

_message() {
  # commit message
  printf "$(date +%Y%m%d-%H%M)" >${SHELL_DIR}/target/commit_message.txt
}

_run() {
  _init

  _check

  _message
}

_run
