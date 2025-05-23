FROM debian:stable

ARG target=ath79-generic
ENV target=$target

ARG profile=linksys_ea8100-v1
ENV profile=$profile

SHELL ["/bin/bash", "-c"]

RUN apt-get update && apt-get -y install build-essential file libncurses-dev zlib1g-dev gawk git \
    gettext libssl-dev xsltproc rsync wget unzip python3 python3-distutils zstd


RUN mkdir /openwrt
WORKDIR /openwrt

RUN wget https://downloads.openwrt.org/snapshots/targets/${target//-//}/openwrt-imagebuilder-${target}.Linux-x86_64.tar.zst

RUN tar --zstd -x -f openwrt-imagebuilder-${target}.Linux-x86_64.tar.zst

WORKDIR /openwrt/openwrt-imagebuilder-${target}.Linux-x86_64



RUN make image PROFILE=${profile}

