
ARG GOLANG_IMAGE_TAG=1.14-alpine
FROM golang:${GOLANG_IMAGE_TAG}

RUN case \"${GOLANG_IMAGE_TAG}\" in \
    *alpine*) apk add --no-cache curl jq git build-base ;; \
    *) apt-get install -y  curl jq git ;; \
    esac

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

LABEL maintainer="Jay Zhang <wangyoucao577@gmail.com>"

