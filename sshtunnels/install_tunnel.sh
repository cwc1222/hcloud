#!/usr/bin/env bash

# Exit the script with error if any of the commands fail
set -o errexit

ENV_FILE=".env"
DIST_PATH=$HOME/.local/bin

readEnv() {
    set -o allexport && . $ENV_FILE
    source $ENV_FILE
    set +o allexport
}

cleanEnv() {
    # Clean the env variables
    unset $(grep -v '^#' $ENV_FILE | sed -E 's/(.*)=.*/\1/' | xargs)
}

checkFrep() {
    ## Ensure frep is installed

    if [ ! -d "$DIST_PATH" ]; then
        echo "$DIST_PATH does not exist... creating"
        mkdir -p $DIST_PATH
        echo "$DIST_PATH created"
    fi

    if ! command -v $DIST_PATH/frep 2>&1 /dev/null
    then
        echo "frep could not be found, try download it now..."
        if [[ $(arch) == "arm64" || $(arch) == "aarch64" ]]; then
            ARCH="arm64"
        else
            ARCH="amd64"
        fi
        BINARY_NAME="frep-1.3.13-$(uname -s | tr '[:upper:]' '[:lower:]')-$ARCH"

        curl -fSL "https://github.com/subchen/frep/releases/download/v1.3.13/$BINARY_NAME" -o "$DIST_PATH/frep"
        chmod +x "$DIST_PATH/frep"
        echo "Installed frep to $DIST_PATH/frep, if you wanna use it directly, add it to your PATH variable"
    fi
}

## Main Entry
cleanEnv
readEnv
checkFrep
$DIST_PATH/frep --overwrite -e LOCAL_USER=$(whoami) ./k3s-ssh-tunnel.service.tmpl
$DIST_PATH/frep --overwrite -e LOCAL_USER=$(whoami) ./postgres-tunnel.service.tmpl
echo "Rendered templates successfully"

# Install the service
echo "Installing k3s ssh tunnel service..."
mkdir -p ~/.config/systemd/user
cp ./k3s-ssh-tunnel.service ~/.config/systemd/user/k3s-ssh-tunnel.service
systemctl --user daemon-reload
systemctl --user enable k3s-ssh-tunnel.service
systemctl --user restart k3s-ssh-tunnel.service
echo "k3s ssh tunnel service installed successfully"

echo "Installing postgres ssh tunnel service..."
mkdir -p ~/.config/systemd/user
cp ./postgres-tunnel.service ~/.config/systemd/user/postgres-tunnel.service
systemctl --user daemon-reload
systemctl --user enable postgres-tunnel.service
systemctl --user restart postgres-tunnel.service
echo "postgres ssh tunnel service installed successfully"

# Clean up
echo "Cleaning up..."
cleanEnv

