ARG RUST_VERSION=1.84.0
ARG DEBIAN_VERSION=bookworm

FROM rust:${RUST_VERSION} AS builder
ARG RUST_VERSION
ARG DEBIAN_VERSION
RUN --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt update && \
    apt -y install \
        scdoc \
        build-essential \
        ninja-build \
        gettext \
        cmake \
        curl  \
        g++ \
        pkg-config \
        libfreetype6-dev \
        libfontconfig1-dev \
        libxcb-xfixes0-dev \
        libxkbcommon-dev \
        python3 && \
    curl -sSLf https://go.dev/dl/go1.23.5.linux-amd64.tar.gz -o /tmp/go1.23.5.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf /tmp/go1.23.5.linux-amd64.tar.gz && \
    rm /tmp/go1.23.5.linux-amd64.tar.gz
# RUN --mount=type=cache,target=/usr/local/cargo/registry,id=cargo-${RUST_VERSION}-registry \
#     --mount=type=cache,target=/usr/local/cargo/git/db \
#     cargo install sccache
ENV SCCACHE_DIR=/opt/sccache/${RUST_VERSION} \
    SCCACHE_CACHE_SIZE="2G" \
    GOCACHE="/var/cache/go/build" \
    GOMODCACHE="/var/cache/go/pkg/mod" \
    PATH="/usr/local/go/bin:$PATH"
#ENV RUSTC_WRAPPER="/usr/local/cargo/bin/sccache"
RUN --mount=type=ssh \
    mkdir ~/.ssh/ && \
    ssh-keyscan github.com >> ~/.ssh/known_hosts && \
    git config --global user.name 'Harry Brown'  && \
    git config --global user.email me@h3y.sh     && \
    git clone \
        --branch main \
        --depth 1 \
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
COPY README.md .
COPY scripts scripts
RUN --mount=type=ssh \
    --mount=type=cache,target=/opt/sccache/${RUST_VERSION} \
    --mount=type=cache,target=/usr/local/cargo/registry,id=cargo-${RUST_VERSION}-registry \
    --mount=type=cache,target=/usr/local/cargo/git/db      \
    --mount=type=cache,target=/var/cache/go                \
    --mount=type=cache,target=/opt/workbench/.pax/repos,id=pax-repos-${DEBIAN_VERSION} \
    /usr/local/bin/pax

FROM ubuntu:24.04 AS workbench
ARG DEBIAN_VERSION
RUN apt update -q
#COPY ./dist/workbench-v0.0.1_amd64.deb /tmp/workbench.deb
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
