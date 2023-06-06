# SMTP

[![Pipeline Status](https://gitlab.com/ix.ai/smtp/badges/master/pipeline.svg)](https://gitlab.com/ix.ai/smtp/)
[![Docker Stars](https://img.shields.io/docker/stars/ixdotai/smtp.svg)](https://hub.docker.com/r/ixdotai/smtp/)
[![Docker Pulls](https://img.shields.io/docker/pulls/ixdotai/smtp.svg)](https://hub.docker.com/r/ixdotai/smtp/)
[![Gitlab Project](https://img.shields.io/badge/GitLab-Project-554488.svg)](https://gitlab.com/ix.ai/smtp/)

This is a SMTP docker container for sending emails. You can also relay emails to gmail and amazon SES.

## Environment variables

The container accepts `RELAY_NETWORKS` environment variable which *MUST* start with `:` e.g `:192.168.0.0/24` or `:192.168.0.0/24:10.0.0.0/16`.

The container accepts `KEY_PATH` and `CERTIFICATE_PATH` environment variable that if provided will enable TLS support. The paths must be to the key and certificate file on a exposed volume. The keys will be copied into the container location.

The container accepts `MAILNAME` environment variable which will set the outgoing mail hostname.

The container also accepts the `PORT` environment variable, to set the port the mail daemon will listen on inside the container. The default port is `25`.

The container accepts `BIND_IP` and `BIND_IP6` environment variables. The defaults are `0.0.0.0` and `::0`.

To disable IPV6 you can set the `DISABLE_IPV6` environment variable to any value.

The container accepts `OTHER_HOSTNAMES` environment variable which will set the list of domains for which this machine should consider itself the final destination.

The container accepts `NET_DEV` environment variable to override the default `eth0` interface for retrieving the IP address for relay networks.

The container accepts `SMTPPORTOUT`environment variable to override the default port of 25 for connecting to the primary mailserver when used as secondary(eg. setting RELAY_DOMAINS)

## Below are scenarios for using this container

### As SMTP Server

You don't need to specify any environment variable to get this up.

### As a Secondary SMTP Server

Specify 'RELAY_DOMAINS' to setup what domains should be accepted to forward to lower distance MX server.

Format is `<domain1> : <domain2> : <domain3> etc`

### As Gmail Relay

You need to set the `GMAIL_USER` and `GMAIL_PASSWORD` to be able to use it.

### As Amazon SES Relay

You need to set the `SES_USER` and `SES_PASSWORD` to be able to use it.

You can override the SES region by setting `SES_REGION` as well.
If you use Google Compute Engine you also should set `SES_PORT` to 2587.

### As generic SMTP Relay

You can also use any generic SMTP server with authentication as smarthost.</br>
You need to set `SMARTHOST_ADDRESS`, `SMARTHOST_PORT` (connection parameters), `SMARTHOST_USER`, `SMARTHOST_PASSWORD` (authentication parameters), and `SMARTHOST_ALIASES`: this is a list of aliases to puth auth data for authentication, semicolon separated.</br>

Example 1:

```txt
SMARTHOST_ADDRESS=mail.mysmtp.com
SMARTHOST_PORT=587
SMARTHOST_USER=myuser
SMARTHOST_PASSWORD=secret
SMARTHOST_ALIASES=*.mysmtp.com
```

Example 2 using docker-compose.yml:

```yml
version: '3'

services:
  smtp:
    image: ixdotai/smtp:latest
    ports:
      # this port mapping allows you to send email from the host.
      # if you only send from other docker containers you don't need this.
      - 127.0.0.1:25:25
    environment:
      - SMARTHOST_ADDRESS=smtp.sendgrid.net
      - SMARTHOST_PORT=587
      - SMARTHOST_USER=apikey
      - SMARTHOST_PASSWORD=SG.blahblahblahblahWoSpQodvLakqXQfxo
      - SMARTHOST_ALIASES=*.sendgrid.net
```

## Tags and Arch

Starting with version v0.0.1, the images are multi-arch, with builds for amd64, arm64 and armv7. Starting with v0.1.3 support for i386 was added.

* `vN.N.N` - for example v0.0.1
* `latest` - always pointing to the latest version
* `dev-master` - the last build on the master branch

## Resources

* Gitlab Registry: `registry.gitlab.com/ix.ai/smtp` - [gitlab.com/ix.ai/smtp](https://gitlab.com/ix.ai/smtp)
* GitHub Registry: `ghcr.io/ix-ai/smtp` [github.com/ix-ai/smtp](https://github.com/ix-ai/smtp)
* Docker Hub: `ixdotai/smtp` - [hub.docker.com/r/ixdotai/smtp](https://hub.docker.com/r/ixdotai/smtp)

## Troubleshooting

Check the container logs to see exim output.

### Certificate Verification Error in Exim 4.93 and 4.94

Additional checking added in Exim 4.93 can cause certificate verification to fail with this error message:

```txt
    TLS session: (certificate verification failed): certificate invalid: delivering unencrypted to H=smtp.sendgrid.net [167.89.115.117] (not in hosts_require_tls)
```

Exim then tries to deliver unencrypted but this may fail because authentication may only be possible on TLS connections:

```txt
    smtp        |   293   SMTP<< 550 Unauthenticated senders not allowed
    smtp        |   293   SMTP<< 503 Must have sender before recipient
    smtp        |   293   SMTP<< 503 Must have valid receiver and originator
    smtp        |   293   SMTP>> QUIT
    smtp        |   293   SMTP(close)>>
    smtp        |   292 LOG: MAIN
    smtp        |   292   ** autosender@commonword.ca R=smarthost T=remote_smtp_smarthost H=smtp.sendgrid.net [167.89.123.82]: SMTP error from remote mail server after pipelined MAIL FROM:<> SIZE=3128: 550 Unauthenticated senders not allowed
    smtp        |   292 LOG: MAIN
    smtp        |   292   Frozen (delivery error message)
```

This issue will hopefully be resolved in Exim 4.95 (see [bugs.exim.org/show_bug.cgi?id=2594](https://bugs.exim.org/show_bug.cgi?id=2594)), but at the time of writing (Sept 2021) the debian stable bas image we use has Exim 4.94.  One possible workaround in the meantime is to disable TLS verification when sending to your smarthost.

Put this into a config file `exim4_additional_macros`:

```sh
# disable TLS verification as a workaround
REMOTE_SMTP_SMARTHOST_TLS_VERIFY_HOSTS = :
```

and bind-mount this file to `/etc/exim4/_docker_additional_macros`.

## Credits

Special thanks to [namshi/docker-smtp](https://github.com/namshi/docker-smtp).

### Differences from namshi/docker-smtp

In terms of configuration, this image works the same as namshi/docker-smtp.

The main differences are:

* this image is based on `debian:stable` (vs. `debian:buster` used by namshi) so it has a newer version of Exim with the latest security updates.  The newer version may result in some differences vs. namshi.
* this image in addition to AMD64, is built for ARM64, ARMv7, ARMv6 and i386.
* cosmetic changes in `entrypoint.sh` to make [shellcheck](https://github.com/koalaman/shellcheck/) happy
