#!/usr/bin/env bash

PROG="`basename $0`"
ICINGA2HOST="`hostname -f`"

Usage() {
cat << EOF

  *To be used with SmsGateway of Handfreezer available under GitHub (https://github.com/handfreezer/SmsGateway)*
  
Required parameters:
  -h HOST (\$host.name\$ or \$host.display_name\$)
  -t STATE (\$host.state\$ or \$service.state\$)
  -u SMS API Uri (https://..../smsctrl.php)
  -o SMS API Token (SuperComplicatedToken)
  -d SMS API Destination Number

Optional parameters:
  -a HEADER of the SMS (first line)
  -e SERVICE (\$service.name\$ or \$service.display_name\$)
  -v Verbose mode

EOF
}

Help() {
  Usage;
  exit 0;
}

Error() {
  if [ "$1" ]; then
    echo $1
  fi
  Usage;
  exit 1;
}

## Main
while getopts "h:t:u:o:d:a:e:v" opt
do
  case "$opt" in
    a) HEADER=$OPTARG ;;
    h) HOST=$OPTARG ;;
    e) SERVICE=$OPTARG ;;
    t) STATE=$OPTARG ;;
    u) API_URI=$OPTARG ;;
    o) API_TOKEN=$OPTARG ;;
    d) API_DST=$OPTARG ;;
    v) VERBOSE=1 && set -x ;;
   \?) echo "ERROR: Invalid option -$OPTARG" >&2
       Error ;;
    :) echo "Missing option argument for -$OPTARG" >&2
       Error ;;
    *) echo "Unimplemented option: -$OPTARG" >&2
       Error ;;
  esac
done

shift $((OPTIND - 1))

## Keep formatting in sync with mail-service-notification.sh
for P in HOST STATE API_URI API_TOKEN API_DST ; do
        eval "PAR=\$${P}"

        if [ ! "$PAR" ] ; then
                Error "Required parameter '$P' is missing."
        fi
done

## Build the message's subject

if [ -n "${HEADER}" ]
then
  MESSAGE="${HEADER}\\n"
fi
MESSAGE="${MESSAGE}host: ${HOST}"
if [ -n "${SERVICE}" ]
then
  MESSAGE="${MESSAGE}\\nservice: ${SERVICE}"
fi
MESSAGE="${MESSAGE}\\nstate: ${STATE}"
MESSAGE="${MESSAGE}\\nfrom: ${ICINGA2HOST}"

## Check whether verbose mode was enabled and log to syslog.
if [ "$VERBOSE" -eq 1 ] ; then
  logger "$PROG sends [${MESSAGE}] => ${API_DST}"
fi

/usr/bin/curl -vL -H "Content-Type: application/json" -d "{\"token\":\"${API_TOKEN}\", \"gsm\":\"${API_DST}\", \"msg\":\"${MESSAGE}\"}" "${API_URI}"

