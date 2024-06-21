
FROM debian:stretch-slim

RUN DEBIAN_FRONTEND=noninteractive apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
  curl \
  wget \
  git \
  build-essential \
  zip \
  jq \
  ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# install latest upx 3.96 by wget instead of `apt install upx-ucl`(only 3.95)
RUN wget --no-check-certificate --progress=dot:mega https://github.com/upx/upx/releases/download/v3.96/upx-3.96-amd64_linux.tar.xz && \
  tar -Jxf upx-3.96-amd64_linux.tar.xz && \
  mv upx-3.96-amd64_linux /usr/local/ && \
  ln -s /usr/local/upx-3.96-amd64_linux/upx /usr/local/bin/upx && \
  upx --version

# github-assets-uploader to provide robust github assets upload
RUN wget --no-check-certificate --progress=dot:mega https://github.com/wangyoucao577/assets-uploader/releases/download/v0.9.0/github-assets-uploader-v0.9.0-linux-amd64.tar.gz -O github-assets-uploader.tar.gz && \
  tar -zxf github-assets-uploader.tar.gz && \
  mv github-assets-uploader /usr/sbin/ && \
  rm -f github-assets-uploader.tar.gz && \
  github-assets-uploader -version

COPY *.sh /
ENTRYPOINT ["/entrypoint.sh"]

LABEL maintainer = "Jay Zhang <wangyoucao577@gmail.com>"
LABEL org.opencontainers.image.source = "https://github.com/wangyoucao577/go-release-action"
