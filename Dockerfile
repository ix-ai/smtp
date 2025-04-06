FROM public.ecr.aws/docker/library/debian:stable-slim@sha256:70b337e820bf51d399fa5bfa96a0066fbf22f3aa2c3307e2401b91e2207ac3c3
LABEL org.opencontainers.image.authors="smtp@docker.egos.tech" \
      org.opencontianers.image.description="A docker image to allow the launch of container in docker swarm, with options normally unavailable to swarm mode" \
      org.opencontainers.image.source="https://gitlab.com/ix.ai/smtp" \
      org.opencontainers.image.url="https://egos.tech/smtp"

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
