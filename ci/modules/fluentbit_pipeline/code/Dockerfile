FROM fluent/fluent-bit:3.0.6 as builder
FROM debian:bullseye-slim as debug
ENV DEBIAN_FRONTEND noninteractive

# hadolint ignore=DL3008
RUN echo "deb http://deb.debian.org/debian bullseye-backports main" >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    libssl1.1 \
    libsasl2-2 \
    pkg-config \
    libpq5 \
    libsystemd0/bullseye-backports \
    zlib1g \
    ca-certificates \
    libatomic1 \
    libgcrypt20 \
    libyaml-0-2 \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /fluent-bit /fluent-bit
EXPOSE 2020

ADD fluent-bit.conf /fluent-bit.conf

ENV LOG_LEVEL=debug

# No entry point so we can just shell in
CMD ["/fluent-bit/bin/fluent-bit", "-c", "/fluent-bit/etc/fluent-bit.conf"]