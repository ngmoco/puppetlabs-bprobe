#!/bin/bash

APIHOST="api.boundary.com"
APICREDS=
TARGET_DIR="/tmp"
EC2_INTERNAL="http://169.254.169.254/latest/meta-data"
TAGS="ami-id hostname instance-id instance-type kernel-id local-hostname local-ipv4 mac placement/availability-zone
public-hostname public-ipv4 reservation-id security-groups"

function print_help() {
  echo "./provision_meter.sh -a USERNAME:APIKEY"
  exit 0
}

function create_meter() {
  local LOCATION=`curl -is -X POST -H "Content-Type: application/json" -d "{\"name\": \"$HOSTNAME\"}" -u $1 $2 \
        | grep Location \
        | sed 's/Location: //' \
        | sed 's/\(.*\)./\1/'`

  echo $LOCATION
}

function download_certificate() {
  echo "downloading meter certificate for $2"
  curl -s -u $1 $2/cert.pem > $TARGET_DIR/cert.pem
}

function download_key() {
  echo "downloading meter key for $2"
  curl -s -u $1 $2/key.pem > $TARGET_DIR/key.pem
}

function ec2_tag() {
  echo -n "Auto generating ec2 tags for this meter...."

  for tag in $TAGS; do
local AN_TAG
    local exit_code

    AN_TAG=`curl -s --connect-timeout 5 "$EC2_INTERNAL/$tag"`
    exit_code=$?

    # if the exit code is 7, that means curl couldnt connect so we can bail
    # since we probably are not on ec2.
    if [ "$exit_code" -eq "7" ]; then
echo " doesn't look like this host is on ec2."
      return 0
    fi

    # it appears that an exit code of 28 is also a can't connect error
    if [ "$exit_code" -eq "28" ]; then
echo " doesn't look like this host is on ec2."
      return 0
    fi

    # otherwise, maybe there was as timeout or something, skip that tag.
    if [ "$exit_code" -ne "0" ]; then
continue
fi

for an_tag in $AN_TAG; do
      # create the tag
      curl -H "Content-Type: application/json" -s -u $1 -X PUT "$2/tags/$an_tag"
    done
done

curl -H "Content-Type: application/json" -s -u $1 -X PUT "$2/tags/ec2"
  echo "done."
}

while getopts "h a:d:" opts
do
case $opts in
    h) print_help;;
    a) APICREDS="$OPTARG";;
    d) TARGET_DIR="$OPTARG";;
    [?]) print_help;;
  esac
done

if [ ! -z $APICREDS ]
  then
if [ "$HOSTNAME" == "localhost" ] || [ -z $HOSTNAME ]
      then
echo "Hostname set to localhost or null, exiting."
        exit 1
    else
URL="https://$APIHOST/meters"

      METER_LOCATION=`create_meter $APICREDS $URL`

      if [ ! -z $METER_LOCATION ]
        then
echo "Meter created at $METER_LOCATION"
          download_certificate $APICREDS $METER_LOCATION
          download_key $APICREDS $METER_LOCATION
          # ec2_tag $APICREDS $METER_LOCATION
        else
echo "No location header received, error creating meter!"
          exit 1
      fi
fi
else
print_help
fi