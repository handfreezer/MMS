ARG IMAGE_ICINGA2_TAG="2.13.7"
ARG CENTREON_PLUGINS_VERSION="20230118"

FROM icinga/icinga2:${IMAGE_ICINGA2_TAG}

USER root

RUN apt update
RUN apt install --no-install-recommends -y perl libsnmp-perl libxml-libxml-perl libjson-perl libwww-perl libxml-xpath-perl libnet-telnet-perl libnet-ntp-perl libnet-dns-perl libdbi-perl libdbd-mysql-perl libdbd-pg-perl

RUN apt install --no-install-recommends -y libjson-xs-perl vim

COPY root/ /
COPY --chown=icinga misc/docker-host.conf /data-init/etc/icinga2/docker-host.conf

RUN echo "" >> /data-init/etc/icinga2/icinga2.conf \
	&& echo 'include "/mms/mms.conf"' >> /data-init/etc/icinga2/icinga2.conf \
	&& echo 'include "docker-host.conf"' >> /data-init/etc/icinga2/icinga2.conf

ENV CENTREON_PLUGINS_VERSION ${CENTREON_PLUGINS_VERSION}
RUN cd /mms/scripts/centreon \
	&& ./deploy.sh

USER icinga

