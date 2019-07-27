FROM debian:buster
LABEL MAINTAINER="docker@ix.ai"
ENV DEBIAN_FRONTEND=noninteractive TERM=linux
ARG PORT=25
ARG BIND_IP="0.0.0.0"
ARG BIND_IP6="::0"

RUN apt-get update && \
    apt-get install -y exim4-daemon-light && \
    apt-get -y --purge autoremove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    find /var/log -type f | while read f; do echo -ne '' > $f; done;

COPY entrypoint.sh /bin/
COPY set-exim4-update-conf /bin/

RUN chmod a+x /bin/entrypoint.sh && \
    chmod a+x /bin/set-exim4-update-conf

ENV PORT=${PORT} BIND_IP=${BIND_IP} BIND_IP6=${BIND_IP6}

EXPOSE ${PORT}

ENTRYPOINT ["/bin/entrypoint.sh"]
CMD ["exim", "-bd", "-q15m", "-v"]
