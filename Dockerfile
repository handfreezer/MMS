ARG IMAGE_ICINGA2_TAG="2.13.7"
ARG CENTREON_PLUGINS_VERSION="20230118"

FROM icinga/icinga2:${IMAGE_ICINGA2_TAG}

USER root

RUN apt update
RUN apt install --no-install-recommends -y perl libsnmp-perl libxml-libxml-perl libjson-perl libwww-perl libxml-xpath-perl libnet-telnet-perl libnet-ntp-perl libnet-dns-perl libdbi-perl libdbd-mysql-perl libdbd-pg-perl

RUN apt install --no-install-recommends -y libjson-xs-perl

COPY root/ /

ENV CENTREON_PLUGINS_VERSION ${CENTREON_PLUGINS_VERSION}
RUN cd /mms/scripts/centreon \
	&& ./deploy.sh

USER icinga

