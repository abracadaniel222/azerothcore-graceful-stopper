#!/bin/bash
# Gracefully shutdown AzerothCore using SOAP
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
  echo "Already stopped"
  exit 0
fi

read -r -d '' SOAP_XML <<EOF
<?xml version="1.0"?>
<SOAP-ENV:Envelope
    xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" 
    xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/" 
    xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance" 
    xmlns:xsd="http://www.w3.org/1999/XMLSchema" 
    xmlns:ns1="urn:AC">
  <SOAP-ENV:Body>
    <ns1:executeCommand>
      <command>server shutdown $SHUTDOWN_TIMEOUT_SECONDS</command>
    </ns1:executeCommand>
  </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
EOF

response=$(curl -s -w "\n%{http_code}" -X POST "http://$SOAP_HOST:$SOAP_PORT/" -H "Content-Type: text/xml" --user "$SOAP_USER:$SOAP_PASSWORD" -d "$SOAP_XML"  2>&1)

curl_exit=$?

body=$(echo "$response" | sed '$d')
code=$(echo "$response" | tail -n1)

if [ "$curl_exit" -ne 0 ] || [ "$code" != "200" ]; then
  echo "SOAP shutdown failed:"
  echo "HTTP code: ${code:-<none>}"
  echo "Response:"
  echo "$body"
  exit 1
fi