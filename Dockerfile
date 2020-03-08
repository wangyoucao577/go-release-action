
FROM debian:stretch-slim

RUN DEBIAN_FRONTEND=noninteractive apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
  curl \
  wget \
  git \
  zip \
  jq

COPY *.sh /
ENTRYPOINT ["/entrypoint.sh"]

LABEL maintainer="Jay Zhang <wangyoucao577@gmail.com>"

