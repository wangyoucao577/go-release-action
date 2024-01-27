
FROM debian:buster-slim
ARG UPX_VER
ARG UPLOADER_VER
ENV UPX_VER=${UPX_VER:-4.0.0}
ENV UPLOADER_VER=${UPLOADER_VER:-v0.13.0}

RUN DEBIAN_FRONTEND=noninteractive apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
  curl \
  wget \
  git \
  build-essential \
  zip \
  xz-utils \
  jq \
  ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# install latest upx 3.96 by wget instead of `apt install upx-ucl`(only 3.95)
RUN export arch=$(dpkg --print-architecture) && wget --no-check-certificate --progress=dot:mega https://github.com/upx/upx/releases/download/v${UPX_VER}/upx-${UPX_VER}-${arch}_linux.tar.xz && \
  tar -Jxf upx-${UPX_VER}-${arch}_linux.tar.xz && \
  mv upx-${UPX_VER}-${arch}_linux /usr/local/ && \
  ln -s /usr/local/upx-${UPX_VER}-${arch}_linux/upx /usr/local/bin/upx && \
  rm upx-${UPX_VER}-${arch}_linux.tar.xz && \
  upx --version

# github-assets-uploader to provide robust github assets upload
RUN export arch=$(dpkg --print-architecture) && wget --no-check-certificate --progress=dot:mega https://github.com/wangyoucao577/assets-uploader/releases/download/${UPLOADER_VER}/github-assets-uploader-${UPLOADER_VER}-linux-${arch}.tar.gz -O github-assets-uploader.tar.gz && \
  tar -zxf github-assets-uploader.tar.gz && \
  mv github-assets-uploader /usr/sbin/ && \
  rm -f github-assets-uploader.tar.gz && \
  github-assets-uploader -version

COPY *.sh /
ENTRYPOINT ["/entrypoint.sh"]

LABEL maintainer = "Jay Zhang <wangyoucao577@gmail.com>"
LABEL org.opencontainers.image.source = "https://github.com/wangyoucao577/go-release-action"
