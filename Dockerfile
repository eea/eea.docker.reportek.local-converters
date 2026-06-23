FROM python:3.11-slim-bookworm AS builder

ENV LC_HOME=/opt/local_converters \
    VIRTUAL_ENV=/opt/local_converters/venv \
    PATH=/opt/local_converters/venv/bin:$PATH \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY src/requirements.txt /requirements.txt

RUN python -m venv "$VIRTUAL_ENV" && \
    "$VIRTUAL_ENV/bin/python" -m pip install --upgrade pip setuptools wheel && \
    "$VIRTUAL_ENV/bin/python" -m pip install -r /requirements.txt


FROM python:3.11-slim-bookworm AS runtime

ENV LC_HOME=/opt/local_converters \
    VIRTUAL_ENV=/opt/local_converters/venv \
    PATH=/opt/local_converters/venv/bin:$PATH \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PORT=5000 \
    WORKERS=2 \
    TIMEOUT=300

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      antiword \
      ca-certificates \
      default-jre-headless \
      file \
      gawk \
      gdal-bin \
      graphviz \
      libxml2-utils \
      mdbtools \
      netcat-openbsd \
      p7zip-full \
      poppler-utils \
      unzip \
      wv \
      xsltproc \
      zip \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder "$VIRTUAL_ENV" "$VIRTUAL_ENV"
COPY src/docker-setup.sh /docker-setup.sh

RUN groupadd -g 500 zope-www && \
    useradd -g 500 -u 500 -m -s /bin/bash zope-www && \
    mkdir -p "$LC_HOME/var" && \
    chmod +x /docker-setup.sh && \
    chown -R 500:500 "$LC_HOME"

WORKDIR /opt/local_converters/venv/lib/python3.11/site-packages/Products/reportek.converters

USER zope-www

HEALTHCHECK --interval=3m --timeout=5s --start-period=30s \
    CMD nc -z -w5 127.0.0.1 ${PORT} || exit 1

EXPOSE 5000
VOLUME $LC_HOME/var/

ENTRYPOINT ["/docker-setup.sh"]
CMD []
