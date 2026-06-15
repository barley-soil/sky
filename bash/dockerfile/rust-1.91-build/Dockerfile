FROM billbear-cn-shanghai.cr.volces.com/base/ubuntu:24.04

ENV RUSTUP_DIST_SERVER=https://rsproxy.cn \
    RUSTUP_UPDATE_ROOT=https://rsproxy.cn/rustup \
    CARGO_HOME=/root/.cargo \
    RUSTUP_HOME=/root/.rustup \
    PATH="/root/.cargo/bin:$PATH"

RUN apt update && \
    apt install -y curl ca-certificates build-essential pkg-config git

RUN mkdir -p /root/.cargo && \
    tee /root/.cargo/config.toml > /dev/null <<EOF
[source.crates-io]
replace-with = 'rsproxy-sparse'

[source.rsproxy]
registry = "https://rsproxy.cn/crates.io-index"

[source.rsproxy-sparse]
registry = "sparse+https://rsproxy.cn/index/"

[registries.rsproxy]
index = "https://rsproxy.cn/crates.io-index"

[net]
git-fetch-with-cli = true
EOF

RUN curl --proto '=https' --tlsv1.2 -sSf https://rsproxy.cn/rustup-init.sh | sh -s -- -y --profile minimal && \
    rustup install stable && \
    rustup default stable

RUN rustc --version && cargo --version
