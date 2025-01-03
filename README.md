# image-mirror

## config

### checklist.txt

* 최신 버전을 확인 하는 이미지

### images.txt

* 버전을 지정하여 미러링 하는 이미지

## github action repository_dispatch

```bash
GITHUB_TOKEN=""

BASE_IMAGE="gcr.io/istio-release/proxyv2"
IMAGE_NAME="mirror/istio/proxyv2"
TAG_NAME="1.22.7"
PLATFORM="linux/amd64,linux/arm64"

PAYLOAD="{\"event_type\":\"mirror\","
PAYLOAD="${PAYLOAD}\"client_payload\":{"
PAYLOAD="${PAYLOAD}\"base_image\":\"${BASE_IMAGE}\","
PAYLOAD="${PAYLOAD}\"image_name\":\"${IMAGE_NAME}\","
PAYLOAD="${PAYLOAD}\"tag_name\":\"${TAG_NAME}\","
PAYLOAD="${PAYLOAD}\"platform\":\"${PLATFORM}\""
PAYLOAD="${PAYLOAD}}}"

curl -sL -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -d "${PAYLOAD}" \
  https://api.github.com/repos/opspresso/image-mirror/dispatches
```
