ARG HAPROXY_IMAGE=haproxy:3.3.10
FROM ${HAPROXY_IMAGE}

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        cron \
        logrotate \
        rsyslog \
        tzdata \
    && sed -i 's/^module(load="imklog")/# module(load="imklog")/' /etc/rsyslog.conf \
    && rm -rf /var/lib/apt/lists/*

COPY docker/haproxy/haproxy.cfg.template /etc/haproxy/haproxy.cfg.template
COPY docker/rsyslog/haproxy.conf /etc/rsyslog.d/49-haproxy.conf
COPY docker/logrotate/haproxy /etc/logrotate.d/haproxy
COPY docker/cron/haproxy-logrotate /etc/cron.d/haproxy-logrotate
COPY docker/entrypoint.sh /usr/local/bin/haproxy-logrotate-entrypoint.sh

RUN chmod 0644 /etc/haproxy/haproxy.cfg.template \
        /etc/rsyslog.d/49-haproxy.conf \
        /etc/logrotate.d/haproxy \
        /etc/cron.d/haproxy-logrotate \
    && chmod 0755 /usr/local/bin/haproxy-logrotate-entrypoint.sh \
    && mkdir -p /var/log/haproxy /run/haproxy /var/lib/logrotate \
    && touch /var/log/haproxy/haproxy.log

EXPOSE 5432 5433 8404

ENTRYPOINT ["haproxy-logrotate-entrypoint.sh"]
CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg"]
