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
bash <(curl -sSL [https://raw.githubusercontent.com/YourUsername/wurm-unlimited-installer/main/install_wurm.sh](https://raw.githubusercontent.com/YourUsername/wurm-unlimited-installer/main/install_wurm.sh))