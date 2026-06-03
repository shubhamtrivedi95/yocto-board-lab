FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Kolkata

RUN apt-get update && apt-get install -y \
    build-essential chrpath cpio debianutils \
    diffstat file gawk gcc git iputils-ping \
    libacl1 libcrypt-dev locales python3 \
    python3-git python3-jinja2 python3-pexpect \
    python3-pip python3-subunit socat texinfo \
    unzip wget xz-utils zstd python3-venv \
    && rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

RUN useradd -ms /bin/bash builder
RUN echo "builder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER builder
WORKDIR /home/builder
