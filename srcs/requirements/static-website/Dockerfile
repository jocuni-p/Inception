FROM debian:bullseye

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    nginx \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
