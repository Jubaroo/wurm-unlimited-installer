# Wurm Unlimited Server Installer

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A modern, user-friendly installer script for the Wurm Unlimited dedicated server on Debian and Ubuntu systems. This script provides a graphical (TUI) setup wizard to configure and install a secure, production-ready server.

## Features

- **User-Friendly Wizard:** A guided setup process using `whiptail` for easy configuration.
- **Secure by Default:** Creates a dedicated, unprivileged `steam` user to run the game server.
- **ModLauncher Support:** Automatically downloads and patches the server with the latest Ago ModLauncher.
- **Headless Operation:** Configures the server to run on machines without a desktop environment using `Xvfb`.
- **Systemd Service:** Installs the server as a proper `systemd` service for reliable startup and management.
- **Easy Management:** Includes a simple `wurm` command (`wurm start`, `wurm stop`, `wurm logs`) for effortless server administration.

## Prerequisites

- A server running a fresh installation of **Debian 11/12** or **Ubuntu 20.04/22.04**.
- `sudo` or `root` access.

## Installation

Run one of the following commands on your server to start the installation wizard.

**Using `curl`:**
```bash
curl -sSL https://raw.githubusercontent.com/jubaroo/wurm-unlimited-installer/master/src/modern_installer_ui.sh | sudo bash
```
Using `wget`:

```bash
wget -qO- https://raw.githubusercontent.com/jubaroo/wurm-unlimited-installer/master/src/modern_installer_ui.sh | sudo bash
```

## Post-Installation

After the script finishes, you can manage your server with the wurm command.

| Command               | Description                             |
| --------------------- | --------------------------------------- |
| `sudo wurm start`     | Starts the Wurm Unlimited server.       |
| `sudo wurm stop`      | Stops the Wurm Unlimited server.        |
| `sudo wurm restart`   | Restarts the server.                    |
| `sudo wurm status`    | Checks the current status of the server.|
| `sudo wurm logs`      | Shows the live server logs (press Ctrl+C to exit).|
| `sudo wurm config`    | Opens the server configuration file for editing. |

**IMPORTANT:** You must open the required ports in your server's firewall and/or your home router for players to be able to connect.

* Game Port: 3724 TCP (or your custom port)
* Steam Query Port: 27017 UDP (or your custom port)
* Steam API Ports: 8766 TCP/UDP

## Uninstallation
To completely remove the server and all its files:

```bash
# Stop and disable the service
sudo systemctl stop wurm
sudo systemctl disable wurm

# Remove the service file and management script
sudo rm /etc/systemd/system/wurm.service
sudo rm /usr/local/bin/wurm
sudo systemctl daemon-reload

# (Optional) Delete the steam user and all server files
sudo userdel -r steam
```
## License

This project is licensed under the MIT License.
