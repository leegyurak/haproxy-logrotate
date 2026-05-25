#!/bin/sh
set -eu

setup_timezone() {
    if [ -n "${TZ:-}" ] && [ -f "/usr/share/zoneinfo/${TZ}" ]; then
        ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime
        echo "${TZ}" > /etc/timezone
    fi
}

setup_log_directory() {
    mkdir -p /var/log/haproxy /run/haproxy /var/lib/logrotate
    touch /var/log/haproxy/haproxy.log
    chmod 0750 /var/log/haproxy /var/lib/logrotate
    chmod 0640 /var/log/haproxy/haproxy.log
}

setup_haproxy_config() {
    : "${HAPROXY_MAXCONN:=4096}"
    : "${HAPROXY_WRITE_PORT:=5432}"
    : "${HAPROXY_READ_PORT:=5433}"
    : "${HAPROXY_STATS_PORT:=8404}"
    : "${POSTGRES_MASTER_HOST:=postgres-master}"
    : "${POSTGRES_MASTER_PORT:=5432}"
    : "${POSTGRES_REPLICA_HOST:=postgres-replica}"
    : "${POSTGRES_REPLICA_PORT:=5432}"

    sed \
        -e "s|__HAPROXY_MAXCONN__|${HAPROXY_MAXCONN}|g" \
        -e "s|__HAPROXY_WRITE_PORT__|${HAPROXY_WRITE_PORT}|g" \
        -e "s|__HAPROXY_READ_PORT__|${HAPROXY_READ_PORT}|g" \
        -e "s|__HAPROXY_STATS_PORT__|${HAPROXY_STATS_PORT}|g" \
        -e "s|__POSTGRES_MASTER_HOST__|${POSTGRES_MASTER_HOST}|g" \
        -e "s|__POSTGRES_MASTER_PORT__|${POSTGRES_MASTER_PORT}|g" \
        -e "s|__POSTGRES_REPLICA_HOST__|${POSTGRES_REPLICA_HOST}|g" \
        -e "s|__POSTGRES_REPLICA_PORT__|${POSTGRES_REPLICA_PORT}|g" \
        /etc/haproxy/haproxy.cfg.template > /usr/local/etc/haproxy/haproxy.cfg
}

start_rsyslog() {
    if command -v rsyslogd >/dev/null 2>&1; then
        mkdir -p /run/rsyslogd
        rsyslogd
    fi
}

start_cron() {
    if command -v cron >/dev/null 2>&1; then
        cron
    fi
}

if [ "$(id -u)" = "0" ]; then
    setup_timezone
    setup_log_directory
    setup_haproxy_config
    start_rsyslog
    start_cron
fi

exec /docker-entrypoint.sh "$@"
