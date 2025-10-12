# Wurm Unlimited Server Installer for Debian/Ubuntu

A modern, user-friendly installer script for the Wurm Unlimited dedicated server with full mod support.

## Features

- 🚀 **Easy Installation** - Interactive whiptail UI guides you through setup
- 🎮 **ModLauncher Support** - Optional server mod system installation
- 🖥️ **Headless Operation** - Xvfb integration for servers without displays
- ⚙️ **Systemd Service** - Automatic startup and easy management
- 🛠️ **Management Helper** - Simple `wurm` command for server control
- 🔒 **Input Validation** - Prevents configuration errors
- 🔥 **UFW Integration** - Optional automatic firewall configuration
- ✅ **Safety Checks** - Disk space verification and re-installation warnings

## Quick Start

```bash
# Download and run the installer
wget https://raw.githubusercontent.com/Jubaroo/wurm-unlimited-installer/master/modern_installer_ui.sh
chmod +x modern_installer_ui.sh
sudo ./modern_installer_ui.sh
```

The installer will guide you through:
1. Package installation (SteamCMD, dependencies)
2. Server download from Steam
3. Optional ModLauncher installation
4. Server configuration (IP, ports, settings)
5. Systemd service setup

## Requirements

- **Operating System**: Debian 11/12 or Ubuntu 20.04/22.04/24.04
- **Privileges**: Root access (sudo)
- **Disk Space**: 5GB minimum free space
- **Network**: Internet connection for downloads
- **Architecture**: x86_64 (64-bit)

## Server Management

After installation, manage your server with these simple commands:

```bash
sudo wurm start    # Start the server
sudo wurm stop     # Stop the server
sudo wurm restart  # Restart the server
sudo wurm status   # Check server status
sudo wurm logs     # View real-time logs (Ctrl+C to exit)
sudo wurm config   # Edit configuration file
```

### Advanced Management (systemctl)

```bash
sudo systemctl start wurm      # Start server
sudo systemctl stop wurm       # Stop server
sudo systemctl restart wurm    # Restart server
sudo systemctl status wurm     # Detailed status
sudo journalctl -u wurm -f     # Follow logs
```

## Network Configuration

### Required Firewall Ports

Make sure these ports are open in your firewall:

| Port | Protocol | Purpose |
|------|----------|---------|
| 8766 | TCP/UDP | Steam communication |
| 27016-27030 | UDP | Steam queries (server browser) |
| 3724 | TCP | Game port (default, configurable) |

### UFW Example

```bash
sudo ufw allow 8766/tcp
sudo ufw allow 8766/udp
sudo ufw allow 27016:27030/udp
sudo ufw allow 3724/tcp
```

### Port Forwarding (Home Networks)

If hosting from home, configure port forwarding on your router:
- Forward ports 3724 (TCP), 8766 (TCP/UDP), and 27016-27030 (UDP)
- Point to your server's local IP address

## Configuration

### Main Configuration File

Location: `/home/steam/wurm/server.cfg`

Edit with: `sudo wurm config` or `sudo nano /home/steam/wurm/server.cfg`

### Key Settings

```bash
SERVERNAME="My Server"        # Server name in browser
SERVERPASSWORD=""            # Optional server password
ADMINPWD="your_admin_pass"   # Admin password for in-game commands
MAXPLAYERS=100              # Max concurrent players (1-200)
EXTERNALPORT=3724           # Game connection port
IP="192.168.1.100"          # Server IP address
```

### Game Types

- **Creative**: Fast skill gain, less hostile environment, ideal for building
- **Adventure**: Slower progression, PvP focused, like official Wurm servers

### Mods

If you installed ModLauncher, mods are located in:
- `/home/steam/wurm/mods/`

Each mod has a `.config` file for customization.

## Troubleshooting

### Server Won't Start

```bash
# Check logs for errors
sudo wurm logs

# Check service status
sudo systemctl status wurm

# View installation log
cat /tmp/wurm_install.log
```

### Common Issues

**ModLauncher not working**
- Verify `/home/steam/wurm/WurmServerLauncher-patched` exists
- Check `MODLAUNCHER_INSTALLED="true"` in `server.cfg`
- Server auto-detects launcher; manual config rarely needed

**Server not visible in browser**
- Verify Steam query port (27016-27030 UDP) is open
- Check firewall and router port forwarding
- Confirm server is running: `sudo wurm status`

**Permission errors**
- All files should be owned by `steam:steam`
- Fix with: `sudo chown -R steam:steam /home/steam/wurm/`

**Out of disk space during installation**
- Installer checks for 5GB free space
- Clear space and re-run installer

### Getting Help

1. Check installation log: `/tmp/wurm_install.log`
2. Check server logs: `sudo wurm logs`
3. Review systemd status: `sudo systemctl status wurm`
4. Check GitHub Issues for similar problems

## File Locations

| Path | Description |
|------|-------------|
| `/home/steam/wurm/` | Server installation directory |
| `/home/steam/wurm/server.cfg` | Configuration file |
| `/home/steam/wurm/Creative/` | Creative world files |
| `/home/steam/wurm/Adventure/` | Adventure world files |
| `/home/steam/wurm/mods/` | ModLauncher mods directory |
| `/etc/systemd/system/wurm.service` | Systemd service file |
| `/usr/local/bin/wurm` | Management helper script |
| `/tmp/wurm_install.log` | Installation log |

## Updating the Server

To update Wurm Unlimited server:

```bash
sudo systemctl stop wurm
su - steam
cd ~/steamcmd
./steamcmd.sh +force_install_dir /home/steam/wurm +login anonymous +app_update 402370 validate +quit
exit
sudo systemctl start wurm
```

## Uninstallation

To completely remove the server:

```bash
# Stop and disable service
sudo systemctl stop wurm
sudo systemctl disable wurm
sudo rm /etc/systemd/system/wurm.service
sudo systemctl daemon-reload

# Remove helper command
sudo rm /usr/local/bin/wurm

# Remove server files (WARNING: This deletes everything!)
sudo rm -rf /home/steam/wurm
sudo rm -rf /home/steam/steamcmd

# Optionally remove steam user
sudo userdel -r steam
```

## Development

### Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Test your changes thoroughly
4. Submit a pull request

### Testing

Test the installer in a fresh VM or container:

```bash
# Debian 12
docker run -it debian:12 bash

# Ubuntu 24.04
docker run -it ubuntu:24.04 bash
```

## Credits

- Original installer concept from legacy Wurm community scripts (circa 2017)
- Modernized for 2025 with enhanced UX and reliability
- [WurmServerModLauncher](https://github.com/ago1024/WurmServerModLauncher) by ago1024
- Developed by [Jubaroo](https://github.com/Jubaroo)

## Resources

- [Wurm Unlimited on Steam](https://store.steampowered.com/app/366220/Wurm_Unlimited/)
- [Official Wurmpedia](https://www.wurmpedia.com/)
- [ModLauncher Documentation](https://github.com/ago1024/WurmServerModLauncher)
- [Wurm Unlimited Modding](https://www.reddit.com/r/WurmUnlimited/)

## License

MIT License

Copyright (c) 2025 Jubaroo

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---

**⭐ If this installer helped you, please star the repository!**
