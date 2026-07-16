FROM debian:bookworm-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates git build-essential cmake automake libtool autoconf \
      libhwloc-dev libuv1-dev libssl-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN git clone --depth 1 --branch v6.24.0 https://github.com/xmrig/xmrig.git

WORKDIR /src/xmrig/build
RUN cmake .. -DWITH_HWLOC=OFF -DWITH_TLS=OFF -DXMRIG_DEPS=OFF \
      -DWITH_RANDOMX=OFF -DWITH_CN_GPU=OFF -DWITH_KAWPOW=OFF \
      -DWITH_ARGON2=OFF -DWITH_RANDOMX_ARMV8=OFF \
    && make -j"$(nproc)"

FROM debian:bookworm-slim AS runtime

RUN apt-get update && apt-get install -y --no-install-recommends \
      python3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /src/xmrig/build/xmrig /app/artifacts/xmrig
COPY --from=builder /src/xmrig/src/config.json /app/artifacts/config.json

COPY server.py /app/server.py

EXPOSE 8080
CMD ["python3", "/app/server.py"]
