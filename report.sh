#!/bin/bash

SHELL_DIR=$(dirname $0)

DEFAULT="nalbam/image-mirror"
REPOSITORY=${GITHUB_REPOSITORY:-$DEFAULT}

USERNAME=${GITHUB_ACTOR}
REPONAME=$(echo "${REPOSITORY}" | cut -d'/' -f2)

_init() {
  rm -rf ${SHELL_DIR}/.previous

  mkdir -p ${SHELL_DIR}/target
  mkdir -p ${SHELL_DIR}/versions
  mkdir -p ${SHELL_DIR}/.previous

  cp -rf ${SHELL_DIR}/versions ${SHELL_DIR}/.previous
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
  PLATFORM="${5:-"linux/amd64,linux/arm64"}"
  BUILDX="${6:-"true"}"

  curl -sL https://api.github.com/repos/${REPO}/releases | jq '.[].tag_name' -r | grep -v '-' | head -10 \
    >${SHELL_DIR}/versions/${NAME}

  while read V1; do
    if [ -z "$V1" ]; then
      continue
    fi

    EXIST="false"
    while read V2; do
      if [ "$V1" == "$V2" ]; then
        EXIST="true"
        # echo "# ${NAME} ${V1} EXIST"
        continue
      fi
    done <${SHELL_DIR}/.previous/${NAME}

    if [ "$EXIST" == "false" ]; then
      # send slack message
      _slack "$V1"
    fi
  done <${SHELL_DIR}/versions/${NAME}
}

_slack() {
  if [ -z "${SLACK_TOKEN}" ]; then
    return
  fi

  VERSION="$1"

  EVENT_TYPE="mirror"

  curl -sL -X POST \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -d "{\"event_type\":\"${EVENT_TYPE}\",\"client_payload\":{\"base_image\":\"${BASE_IMAGE}\",\"image_name\":\"${IMAGE_NAME}\",\"tag_name\":\"${VERSION}\",\"platform\":\"${PLATFORM}\",\"buildx\":\"${BUILDX}\"}}" \
    https://api.github.com/repos/${REPOSITORY}/dispatches

  echo "# dispatch ${REPO} ${VERSION}"
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
