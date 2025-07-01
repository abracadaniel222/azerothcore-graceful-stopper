#!/bin/bash
# shutdown AzerothCore using soap
# @author abracadaniel222

SOAP_HOST="127.0.0.1"
SOAP_PORT="7878"
SHUTDOWN_TIMEOUT_SECONDS=60
SOAP_USER="admin"
SOAP_PASSWORD="admin"

CONF_FILE="$HOME/scripts/azerothcore-graceful-stopper/azerothcore_graceful_stopper.conf"
if [ -f "$CONF_FILE" ]; then
  source "$CONF_FILE"
else
  echo "Missing config file: $CONF_FILE" >&2
  exit 1
fi

if ! pgrep -u azerothuser worldserver > /dev/null; then
  # already stopped
  exit 0
fi

read -r -d '' SOAP_XML <<EOF
<?xml version="1.0"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"
                   SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
  <SOAP-ENV:Body>
    <ns1:executeCommand xmlns:ns1="urn:AC">
      <command>server shutdown $SHUTDOWN_TIMEOUT_SECONDS</command>
    </ns1:executeCommand>
  </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
EOF

curl -s -X POST \
  -H "Content-Type: text/xml" \
  --data "$SOAP_XML" \
  "http://$SOAP_USER:$SOAP_PASSWORD@$SOAP_HOST:$SOAP_PORT/"
