FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive
ARG USERNAME=builder
ARG USER_UID=1000
ARG USER_GID=1000

RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -yq --no-install-recommends \
    gawk wget git-core diffstat unzip texinfo gcc-multilib \
    build-essential chrpath socat libsdl1.2-dev xterm \
    ca-certificates  locales cpio file zstd lz4 && \
    rm -rf /var/lib/apt/lists/* && \
    echo "dash dash/sh boolean false" | debconf-set-selections && \
    dpkg-reconfigure dash

RUN locale-gen en_US.UTF-8 && update-locale

RUN groupadd --gid "${USER_GID}" "${USERNAME}" && \
    useradd --uid "${USER_UID}" --gid "${USER_GID}" \
        --create-home --shell /bin/bash "${USERNAME}" && \
    usermod -aG sudo "${USERNAME}" && \
    mkdir -p /etc/sudoers.d && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/yocto-builder && \
    chmod 0440 /etc/sudoers.d/yocto-builder

ENV YOCTO_WORKSPACE=/workspace
RUN mkdir -p "${YOCTO_WORKSPACE}" && chown "${USERNAME}:${USERNAME}" "${YOCTO_WORKSPACE}"
WORKDIR /workspace

COPY scripts/build-yocto.sh /usr/local/bin/build-yocto.sh
RUN chmod +x /usr/local/bin/build-yocto.sh

USER ${USERNAME}

CMD ["/usr/local/bin/build-yocto.sh"]