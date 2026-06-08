FROM alpine:edge

# Install build tools + Rust (1.96.0 from edge)
RUN apk add --no-cache \
    gcc g++ musl-dev libffi-dev openssl-dev \
    libxml2-dev libxslt-dev jpeg-dev zlib-dev libpng-dev \
    linux-headers cargo rust cmake make git curl python3-dev py3-pip

# Install Python 3.11 from Alpine 3.19 (not default 3.14)
RUN apk add --no-cache -X https://dl-cdn.alpinelinux.org/alpine/v3.19/community \
    python3.11 python3.11-dev 2>/dev/null || \
    (cd /tmp && curl -sL https://www.python.org/ftp/python/3.11.9/Python-3.11.9.tgz | tar xz && \
    cd Python-3.11.9 && ./configure --prefix=/usr/local && make -j$(nproc) && make install && \
    ln -sf /usr/local/bin/python3.11 /usr/bin/python3.11 && \
    ln -sf /usr/local/bin/pip3.11 /usr/bin/pip3.11)

# Verify versions
RUN python3.11 --version && rustc --version

# Install hermes-agent (builds pydantic-core from source)
RUN pip3.11 install --break-system-packages hermes-agent
