FROM debian:stable-slim@sha256:382967fd7c35a0899ca3146b0b73d0791478fba2f71020c7aa8c27e3a4f26672
LABEL maintainer="docker@ix.ai" \
      ai.ix.repository="ix.ai/smtp"

ARG PORT=25
ARG BIND_IP="0.0.0.0"
ARG BIND_IP6="::0"
ARG CI_PIPELINE_ID=""

RUN set -xeu; \
    export DEBIAN_FRONTEND=noninteractive; \
    export TERM=linux; \
    apt-get update; \
    apt-get -y dist-upgrade; \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      exim4-daemon-light \
      iproute2 \
    ; \
    apt-get -y --purge autoremove; \
    apt-get clean; \
    rm -rf \
      /var/lib/apt/lists/* \
      /tmp/* \
      /var/tmp/* \
      /var/cache/* \
    ; \
    find /var/log -type f | while read f; do \
      echo -ne '' > $f; \
    done

ENV PORT=${PORT} BIND_IP=${BIND_IP} BIND_IP6=${BIND_IP6}

EXPOSE ${PORT}

COPY entrypoint.sh set-exim4-update-conf update-exim4.conf.debug /bin/

ENTRYPOINT ["/bin/entrypoint.sh"]
CMD ["exim", "-bd", "-q15m", "-v"]
