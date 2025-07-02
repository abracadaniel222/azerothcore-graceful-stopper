#!/bin/bash
# Gracefully shutdown AzerothCore if it's running with screen
# @author abracadaniel222

SHUTDOWN_TIMEOUT=60

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_FILE="$SCRIPT_DIR/azerothcore_graceful_stopper.conf"
if [ -f "$CONF_FILE" ]; then
  source "$CONF_FILE"
fi

if ! pgrep -u azerothuser worldserver > /dev/null; then
  echo "Already stopped"
  exit 0
fi

response=$(screen -S worldserver -X stuff "server shutdown $SHUTDOWN_TIMEOUT\n" 2>&1)
shutdown_exit=$?

if [ "$shutdown_exit" -ne 0 ] || echo "$response" | grep -qi "no screen session"; then
  echo "Failed to send shutdown command:"
  echo "$response"
  exit 1
fi

echo "Shutdown command sent. Waiting for worldserver to stop..."
# not timing out on purpose. If the server isn't shutting down then it ain't up to us to kill it
while pidof -x worldserver > /dev/null; do
  sleep 2
done
echo "worldserver has shut down."