
ARG GOLANG_IMAGE_TAG=1.14-alpine
FROM golang:${GOLANG_IMAGE_TAG}

RUN if [ ${GOLANG_IMAGE_TAG} == *alpine* ]; then \
    apk add --no-cache curl jq git build-base \
    ;else \
    apt-get install -y  curl jq git \
    ;fi

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

LABEL maintainer="Jay Zhang <wangyoucao577@gmail.com>"

