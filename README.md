# AzerothCore Graceful Stopper

Script to gracefully stop or restart AzerothCore.

## Problem

Running `sudo systemctl stop ac-worldserver` kills the process. This script allows automated jobs to give a heads up to users before server is being shutdown, allowing for pending queries to be flushed, bots to log out and everything else better than killing the process.

## Requirements

- Linux
- curl
- AzerothCore installed and setup per https://www.azerothcore.org/wiki/linux-core-installation , running with `screen` and with all the environment variables loaded up

## Setup

- Log in as azerothuser (or whatever your `$AC_UNIT_USER` is)

- Check out the script wherever you want it to be. By default we'll use `$HOME/scripts`

```
mkdir -p $HOME/scripts
cd $HOME/scripts
git clone https://github.com/abracadaniel222/azerothcore-graceful-stopper.git
chmod +x azerothcore-graceful-stopper/azerothcore_graceful_stopper.sh
```

- (Optional) Create a custom config file if you want a different shutdown timer. The default is 60 seconds

```
cp $HOME/scripts/azerothcore-graceful-stopper/azerothcore_graceful_stopper.conf.dist $HOME/scripts/azerothcore-graceful-stopper/azerothcore_graceful_stopper.conf
```

- Create/update the worldserver systemd service `/etc/systemd/system/ac-worldserver.service` by adding the new `ExecStop` entry

```
sudo tee /etc/systemd/system/ac-worldserver.service << EOF
[Unit]
Description=AzerothCore Worldserver
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
RestartSec=1
User=$AC_UNIT_USER
WorkingDirectory=$AC_CODE_DIR
ExecStart=/bin/screen -S worldserver -D -m $AC_CODE_DIR/env/dist/bin/worldserver
ExecStop=$( getent passwd "$AC_UNIT_USER" | cut -d: -f6 )/scripts/azerothcore-graceful-stopper/azerothcore_graceful_stopper.sh

TimeoutStopSec=70

[Install]
WantedBy=multi-user.target
EOF
```

- Reload service definition

```
sudo systemd daemon-reload
```

## Usage

The usage is through `systemctl`, so things like `sudo systemctl ac-worldserver restart` or `sudo systemctl ac-worldserver stop` should gracefully wait for the server to warn users and shutdown.
