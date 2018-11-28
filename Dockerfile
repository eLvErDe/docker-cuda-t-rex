FROM debian:stretch

MAINTAINER Adam Cecile <acecile@le-vert.net>

ENV TERM xterm
ENV HOSTNAME t-rex.local
ENV DEBIAN_FRONTEND=noninteractive
ENV VERSION 0.7.4
ENV CUDA_VERSION 9.1
ENV URL https://github.com/trexminer/T-Rex/releases/download/${VERSION}/t-rex-${VERSION}-linux-cuda${CUDA_VERSION}.tar.gz

WORKDIR /root

# Upgrade base system
RUN apt update \
    && apt -y -o 'Dpkg::Options::=--force-confdef' -o 'Dpkg::Options::=--force-confold' --no-install-recommends dist-upgrade \
    && rm -rf /var/lib/apt/lists/*

# Install dependencies
# Add non-free backports to get libcudart9.1 from CUDA 9.1
RUN echo 'deb http://deb.debian.org/debian stretch-backports non-free' >> /etc/apt/sources.list \
    && apt update \
    && apt -y -o 'Dpkg::Options::=--force-confdef' -o 'Dpkg::Options::=--force-confold' --no-install-recommends install \
    bsdtar libcurl3 libjansson4 libcudart9.1 wget ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install binary
RUN wget ${URL} -O- | bsdtar -xvf- --include='t-rex' -O > /root/t-rex \
    && chmod 0755 /root/ && chmod 0755 /root/t-rex

# This version is dynamically linked to libcrypto.so.1.0.0 so we'll get those files from Debian Jessie
RUN mkdir /root/src \
    && wget http://deb.debian.org/debian/pool/main/o/openssl/libssl1.0.0_1.0.1t-1+deb8u8_amd64.deb -O /root/src/libssl.deb \
    && dpkg --fsys-tarfile /root/src/libssl.deb \
       | tar xv --directory=/root --strip-components=4 ./usr/lib/x86_64-linux-gnu/libcrypto.so.1.0.0 ./usr/lib/x86_64-linux-gnu/libssl.so.1.0.0 \
    && rm -rf /root/src/

# nvidia-container-runtime @ https://gitlab.com/nvidia/cuda/blob/ubuntu16.04/8.0/runtime/Dockerfile
ENV PATH /usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64
# For libcrypto.so.1.0.0
ENV LD_LIBRARY_PATH /root:${LD_LIBRARY_PATH}
LABEL com.nvidia.volumes.needed="nvidia_driver"
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility
