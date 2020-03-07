
FROM golang:1.14-alpine

RUN apk add --no-cache curl jq git build-base 

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

LABEL maintainer="Jay Zhang <wangyoucao577@gmail.com>"

