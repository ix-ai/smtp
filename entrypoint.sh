#!/usr/bin/env bash
set -e

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo >&2 "error: both ${var} and ${fileVar} are set (but are mutually exclusive)"
		exit 1
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
}

file_env GMAIL_USER
file_env GMAIL_PASSWORD
file_env SES_USER
file_env SES_PASSWORD
file_env SMARTHOST_USER
file_env SMARTHOST_PASSWORD

# Initialize localmacros as an empty file
echo -n "" > /etc/exim4/exim4.conf.localmacros

if [ "$MAILNAME" ]; then
	echo "MAIN_HARDCODE_PRIMARY_HOSTNAME = $MAILNAME" > /etc/exim4/exim4.conf.localmacros
	echo "$MAILNAME" > /etc/mailname
fi

if [ "${SMTPPORTOUT}" ]; then
	awk -v port_var="${SMTPPORTOUT}" '/remote_smtp:/{ n=NR+2 } NR==n{ $0="  driver = smtp\n  port = "port_var }1' /etc/exim4/exim4.conf.template > /etc/exim4/exim4.conf.temp
	mv /etc/exim4/exim4.conf.temp /etc/exim4/exim4.conf.template
fi

if [ -s "$KEY_PATH" ] && [ -s "$CERTIFICATE_PATH" ]; then
	echo "MAIN_TLS_ENABLE = yes" >> /etc/exim4/exim4.conf.localmacros
	cp "$KEY_PATH" /etc/exim4/exim.key
	cp "$CERTIFICATE_PATH" /etc/exim4/exim.crt
	chgrp Debian-exim /etc/exim4/exim.key
	chgrp Debian-exim /etc/exim4/exim.crt
	chmod 640 /etc/exim4/exim.key
	chmod 640 /etc/exim4/exim.crt
else
	{
		echo "MAIN_TLS_ENABLE = no"
		echo "MAIN_TLS_ADVERTISE_HOSTS = !*"
	} >> /etc/exim4/exim4.conf.localmacros
fi

if [ -s "$DKIM_KEY_PATH" ]; then
	cp "$DKIM_KEY_PATH" /etc/exim4/dkim.key
	chown Debian-exim /etc/exim4/dkim.key
	chmod 640 /etc/exim4/dkim.key
	{
		echo "DKIM_DOMAIN = \${lc:\${domain:\$h_from:}}"
		echo "DKIM_KEY_FILE = /etc/exim4/dkim.key"
		echo "DKIM_PRIVATE_KEY = \${if exists{DKIM_KEY_FILE}{DKIM_KEY_FILE}{0}}"
		echo "DKIM_SELECTOR = ${DKIM_SELECTOR:-dkim}"
		echo "DKIM_CANON = simple"
	} >> /etc/exim4/exim4.conf.localmacros
fi

opts=(
	dc_local_interfaces "[${BIND_IP:-0.0.0.0}]:${PORT:-25} ; [${BIND_IP6:-::0}]:${PORT:-25}"
	dc_other_hostnames "${OTHER_HOSTNAMES}"
	dc_relay_nets "$(ip addr show dev "${NET_DEV:-eth0}" | awk '$1 == "inet" { print $2 }' | xargs | sed 's/ /:/g')${RELAY_NETWORKS}"
)

if [ "$DISABLE_IPV6" ]; then
	echo 'disable_ipv6=true' >> /etc/exim4/exim4.conf.localmacros
fi

if [ "$GMAIL_USER" ] && [ "$GMAIL_PASSWORD" ]; then
	opts+=(
		dc_eximconfig_configtype 'smarthost'
		dc_smarthost 'smtp.gmail.com::587'
		dc_relay_domains "${RELAY_DOMAINS}"
	)
	echo "*.gmail.com:$GMAIL_USER:$GMAIL_PASSWORD" > /etc/exim4/passwd.client
elif [ "$SES_USER" ] && [ "$SES_PASSWORD" ]; then
	opts+=(
		dc_eximconfig_configtype 'smarthost'
		dc_smarthost "email-smtp.${SES_REGION:=us-east-1}.amazonaws.com::${SES_PORT:=587}"
		dc_relay_domains "${RELAY_DOMAINS}"
	)
	echo "*.amazonaws.com:$SES_USER:$SES_PASSWORD" > /etc/exim4/passwd.client
# Allow to specify an arbitrary smarthost.
# Parameters: SMARTHOST_USER, SMARTHOST_PASSWORD: authentication parameters
# SMARTHOST_ALIASES: list of aliases to puth auth data for (semicolon separated)
# SMARTHOST_ADDRESS, SMARTHOST_PORT: connection parameters.
elif [ "$SMARTHOST_ADDRESS" ] ; then
	opts+=(
		dc_eximconfig_configtype 'smarthost'
		dc_smarthost "${SMARTHOST_ADDRESS}::${SMARTHOST_PORT-25}"
		dc_relay_domains "${RELAY_DOMAINS}"
	)
	rm -f /etc/exim4/passwd.client
	if [ "$SMARTHOST_ALIASES" ] && [ "$SMARTHOST_USER" ] && [ "$SMARTHOST_PASSWORD" ] ; then
		echo "$SMARTHOST_ALIASES;" | while read -r -d ";" alias; do
			echo "${alias}:$SMARTHOST_USER:$SMARTHOST_PASSWORD" >> /etc/exim4/passwd.client
		done
	fi
elif [ "$RELAY_DOMAINS" ]; then
	opts+=(
		dc_relay_domains "${RELAY_DOMAINS}"
		dc_eximconfig_configtype 'internet'
	)
else
	opts+=(
		dc_eximconfig_configtype 'internet'
	)
fi

# allow to add additional macros by bind-mounting a file
if [ -f /etc/exim4/_docker_additional_macros ]; then
	cat /etc/exim4/_docker_additional_macros >> /etc/exim4/exim4.conf.localmacros
fi

# allow using split-file config instead of monolithic config
if [ "${USE_SPLIT_CONFIG:-false}" == "true" ]; then
	opts+=(
		dc_use_split_config "true"
	)
fi

/bin/set-exim4-update-conf "${opts[@]}"

exec "$@"
