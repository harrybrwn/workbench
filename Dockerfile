FROM rust:1.84.0 as pax
WORKDIR /pax
RUN git clone git@github.com:harrybrwn/pax.git --depth 1 /pax && \
    cargo build --release

FROM ubuntu:24.04 as builder
COPY --from=pax /pax/target/release/pax /usr/local/bin/pax
WORKDIR /workbench
COPY *.lua .
RUN pax

FROM ubuntu:24.04
RUN apt update -q
#COPY ./dist/workbench-v0.0.1_amd64.deb /tmp/workbench.deb
COPY --from=builder /workbench/dist/workbench-*_amd64.deb /tmp/workbench.deb
RUN apt install -yq -f /tmp/workbench.deb && \
    rm /tmp/workbench.deb
RUN cat >> ~/.bashrc <<EOF

alias ls=eza
alias l='ls -lA --group-directories-first --git'
EOF
ENTRYPOINT [ "bash" ]
