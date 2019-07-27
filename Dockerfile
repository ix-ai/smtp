FROM alpine:latest
LABEL MAINTAINER="docker@ix.ai"
ARG PORT=25
ARG BIND_IP="0.0.0.0"
ARG BIND_IP6="::0"

RUN apk add --no-cache exim bash

COPY entrypoint.sh /bin/
COPY set-exim-update-conf /bin/

RUN chmod a+x /bin/entrypoint.sh && \
    chmod a+x /bin/set-exim-update-conf

ENV PORT=${PORT} BIND_IP=${BIND_IP} BIND_IP6=${BIND_IP6}

EXPOSE ${PORT}

ENTRYPOINT ["/bin/entrypoint.sh"]
CMD ["exim", "-bd", "-q15m", "-v"]
