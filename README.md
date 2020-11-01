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

## Below are scenarios for using this container

### As SMTP Server
You don't need to specify any environment variable to get this up.

### As a Secondary SMTP Server
Specify 'RELAY_DOMAINS' to setup what domains should be accepted to forward to lower distance MX server.

Format is `<domain1> : <domain2> : <domain3> etc`

### As Gmail Relay
You need to set the `GMAIL_USER` and `GMAIL_PASSWORD` to be able to use it.

### As Amazon SES Relay
You need to set the `SES_USER` and `SES_PASSWORD` to be able to use it.<br/>
You can override the SES region by setting `SES_REGION` as well.
If you use Google Compute Engine you also should set `SES_PORT` to 2587.

### As generic SMTP Relay
You can also use any generic SMTP server with authentication as smarthost.</br>
You need to set `SMARTHOST_ADDRESS`, `SMARTHOST_PORT` (connection parameters), `SMARTHOST_USER`, `SMARTHOST_PASSWORD` (authentication parameters), and `SMARTHOST_ALIASES`: this is a list of aliases to puth auth data for authentication, semicolon separated.</br>

```
Example:

 * SMARTHOST_ADDRESS=mail.mysmtp.com
 * SMARTHOST_PORT=587
 * SMARTHOST_USER=myuser
 * SMARTHOST_PASSWORD=secret
 * SMARTHOST_ALIASES=*.mysmtp.com
```

## Tags and Arch

Starting with version v0.0.1, the images are multi-arch, with builds for amd64, arm64 and armv7.
* `vN.N.N` - for example v0.0.1
* `latest` - always pointing to the latest version
* `dev-master` - the last build on the master branch

## Resources:
* GitLab: https://gitlab.com/ix.ai/smtp
* GitHub: https://github.com/ix-ai/smtp
* GitLab Registry: https://gitlab.com/ix.ai/smtp/container_registry
* Docker Hub: https://hub.docker.com/r/ixdotai/smtp

# Credits
Special thanks to [namshi/docker-smtp](https://github.com/namshi/docker-smtp).

## Differences from namshi/docker-smtp
Initially, the difference was that this image was based on `debian:buster` instead of `debian:stretch`. This was implemented in the meanwhile.

Right now, the only difference, that's not of cosmetic nature (read: the `entrypoint.sh` script has been changed to make [shellcheck](https://github.com/koalaman/shellcheck/) happy), is the fact that the image, in addition to AMD64, is built for ARM64, ARMv7, ARMv6 and i386.

Functionally, there's no difference.
