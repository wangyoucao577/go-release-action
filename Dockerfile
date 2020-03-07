
ARG GOLANG_IMAGE_TAG=1.14-alpine
FROM golang:${GOLANG_IMAGE_TAG}

RUN if [ -x "$(command -v apk)" ]; then \
  apk add --no-cache curl jq git build-base \
  ;elif [ -x "$(command -v apt-get)" ]; then \
  apt-get install -y curl jq git \
  ;fi

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

LABEL maintainer="Jay Zhang <wangyoucao577@gmail.com>"

