# AzerothCore Graceful Stopper

Script to gracefully stop or restart AzerothCore.

## Problem

Running `sudo systemctl stop ac-worldserver` kills the process. This script allows automated jobs to give a heads up to users before server is being shutdown, allowing for pending queries to be flushed, bots to log out and everything else better than killing the process.

## Requirements

- Linux
- systemd ≥ 250 (you can check with `systemctl --version`)
- AzerothCore installed and setup per https://www.azerothcore.org/wiki/linux-core-installation with all the environment variables loaded up

## Setup

- Log in as azerothuser (or whatever your `$AC_UNIT_USER` is)

- Edit your worldserver.conf to enable SOAP (check AzerothCore docs)

- Update your firewall to allow SOAP connections from localhost. For example, for ufw it would be:

```
sudo ufw allow from 127.0.0.1 to 127.0.0.1 port 7878
```

- Check out the script wherever you want it to be

```
mkdir -p $HOME/scripts
cd $HOME/scripts
git clone https://github.com/abracadaniel222/azerothcore-graceful-stopper.git
chmod +x azerothcore-graceful-stopper/azerothcore_graceful_stopper.sh
```

- (Optional) customize the soap server, port and shutdown timer

```
cd $HOME/scripts/azerothcore-graceful-stopper
cp azerothcore_graceful_stopper.conf.dist azerothcore_graceful_stopper.conf
```

- Create SOAP user secrets

```
echo "yoursoapuser" | sudo tee /etc/systemd/secrets/ac_soap_user > /dev/null
echo "yourpassword" | sudo tee /etc/systemd/secrets/ac_soap_pass > /dev/null

sudo chmod 600 /etc/systemd/secrets/ac_soap_*
sudo chown root:root /etc/systemd/secrets/ac_soap_*
```

- Create/update the worldserver systemd service `/etc/systemd/system/ac-worldserver.service` by adding the new `ExecStop` and `LoadCredential` entries

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

# Load credentials into /run/cred/
LoadCredential=ac_soap_user:/etc/systemd/secrets/ac_soap_user
LoadCredential=ac_soap_pass:/etc/systemd/secrets/ac_soap_pass

TimeoutStopSec=70

[Install]
WantedBy=multi-user.target
EOF
```

- Reload service definition

```
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
```

## Usage

The usage is through `systemctl`, so things like `sudo systemctl ac-worldserver restart` or `sudo systemctl ac-worldserver stop` should gracefully wait for the server to warn users and shutdown.
