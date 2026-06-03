ARG RUST_VERSION=1.84.0
ARG DEBIAN_VERSION=bookworm

FROM debian:${DEBIAN_VERSION} AS debian_base
ARG GO_VERSION
ARG RUST_VERSION
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH
RUN --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt update && \
    apt -y install wget curl build-essential
RUN set -eux; \
    dpkgArch="$(dpkg --print-architecture)"; \
    case "${dpkgArch##*-}" in \
        amd64) rustArch='x86_64-unknown-linux-gnu' ;; \
        arm64) rustArch='aarch64-unknown-linux-gnu' ;; \
        *) echo >&2 "unsupported architecture: ${dpkgArch}"; exit 1 ;; \
    esac; \
    url="https://static.rust-lang.org/rustup/dist/${rustArch}/rustup-init"; \
    wget "$url"; \
    chmod +x /rustup-init; \
    /rustup-init -y --no-modify-path --default-toolchain ${RUST_VERSION}; \
    chmod -R a+w $RUSTUP_HOME $CARGO_HOME; \
    curl -sSLf https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz -o /tmp/go${GO_VERSION}.linux-amd64.tar.gz; \
    tar -C /usr/local -xzf /tmp/go${GO_VERSION}.linux-amd64.tar.gz; \
    rm /tmp/go${GO_VERSION}.linux-amd64.tar.gz; \
    rm /rustup-init;

FROM debian_base AS sshtest
RUN apt update && \
		apt install -y git openssh-client
RUN \
		mkdir -p -m 0700 ~/.ssh && \
		ssh-keyscan github.com >> ~/.ssh/known_hosts && \
    git config --global user.name 'Harry Brown' &&  \
    git config --global user.email me@h3y.sh
RUN --mount=type=ssh \
    git clone \
        --branch main \
        --depth 1     \
        git@github.com:harrybrwn/pax.git /opt/pax

FROM debian_base AS builder
ARG RUST_VERSION
ARG DEBIAN_VERSION
ARG GO_VERSION=1.23.5
ARG USER=pax-builder
RUN --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt update && \
    apt -y install \
    scdoc           \
    git             \
    openssh-client  \
    unzip           \
    file            \
    build-essential \
    ninja-build     \
    gettext         \
    cmake           \
    curl            \
    g++             \
    pkg-config         \
    libfreetype6-dev   \
    libfontconfig1-dev \
    libxcb-xfixes0-dev \
    libxkbcommon-dev   \
    libclang-dev       \
    python3

RUN \
		mkdir -p -m 0700 ~/.ssh && \
		ssh-keyscan github.com >> ~/.ssh/known_hosts && \
    git config --global user.name 'Harry Brown'  && \
    git config --global user.email me@h3y.sh

# RUN --mount=type=cache,target=/usr/local/cargo/registry,id=cargo-${RUST_VERSION}-registry \
#     --mount=type=cache,target=/usr/local/cargo/git/db \
#     cargo install sccache
#ENV RUSTC_WRAPPER="/usr/local/cargo/bin/sccache"
ENV SCCACHE_DIR=/opt/sccache/${RUST_VERSION} \
    SCCACHE_CACHE_SIZE="2G" \
    GOCACHE="/var/cache/go/build" \
    GOMODCACHE="/var/cache/go/pkg/mod" \
    PATH="/usr/local/go/bin:$PATH" \
    USER=${USER}
RUN --mount=type=ssh \
    git clone \
        --branch main \
        --depth 1     \
        git@github.com:harrybrwn/pax.git /opt/pax
WORKDIR /opt/pax/
RUN --mount=type=cache,target=/opt/sccache/${RUST_VERSION} \
    --mount=type=cache,target=/usr/local/cargo/registry,id=cargo-${RUST_VERSION}-registry \
    --mount=type=cache,target=/usr/local/cargo/git/db \
    --mount=type=cache,target=/opt/pax/target,id=pax-target-${RUST_VERSION}-${DEBIAN_VERSION} \
    cargo build --release && \
    cp target/release/pax /usr/local/bin/pax

WORKDIR /opt/workbench
COPY *.lua .
COPY ./misc misc
COPY README.md .
COPY scripts scripts
RUN --mount=type=ssh \
    --mount=type=cache,target=/opt/sccache/${RUST_VERSION} \
    --mount=type=cache,target=/usr/local/cargo/registry,id=cargo-${RUST_VERSION}-registry \
    --mount=type=cache,target=/usr/local/cargo/git/db      \
    --mount=type=cache,target=/var/cache/go                \
    --mount=type=cache,target=/opt/workbench/.pax/repos,id=pax-repos-${DEBIAN_VERSION} \
    /usr/local/bin/pax

#
# Workbench
#
FROM ubuntu:24.04 AS workbench
ARG DEBIAN_VERSION
RUN apt update -q
COPY --from=builder /opt/workbench/dist/workbench-*_amd64.deb /tmp/workbench.deb
RUN apt install -yq -f /tmp/workbench.deb && \
    rm /tmp/workbench.deb
RUN cat >> ~/.bashrc <<EOF

alias ls=eza
alias l='ls -lA --group-directories-first --git'
EOF
ENTRYPOINT [ "bash" ]

FROM scratch AS workbench-dist
ARG VERSION
ARG DEBIAN_VERSION
COPY --from=builder \
    /opt/workbench/dist/workbench-*_amd64.deb \
    ./workbench-${VERSION}_${DEBIAN_VERSION}_amd64.deb
