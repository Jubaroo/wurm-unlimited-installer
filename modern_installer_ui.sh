#!/bin/bash
# Modern Wurm Unlimited Server Installer for Debian
# With whiptail UI - Updated for 2025

set -e

if [ "$(whoami)" != 'root' ]; then
  echo "Please run this as root with: sudo $0"
  exit 1
fi

TITLE="Wurm Unlimited Server Installer 2025"
LOGFILE="/tmp/wurm_install.log"

# Clear log
> $LOGFILE

# Check for whiptail
if ! command -v whiptail &> /dev/null; then
    echo "Installing whiptail..." >> $LOGFILE
    apt-get update >> $LOGFILE 2>&1
    apt-get install -y whiptail >> $LOGFILE 2>&1
fi

whiptail --title "$TITLE" --msgbox "Welcome to the Wurm Unlimited Server Installer!\n\nThis will install:\n- SteamCMD\n- Wurm Unlimited Dedicated Server\n- Server ModLauncher\n- Xvfb for headless operation\n- Systemd service\n\nPress OK to continue" 15 70

# Check for existing installation
if [ -d "/home/steam/wurm" ]; then
    if ! whiptail --title "$TITLE" --yesno "WARNING: Wurm server files already exist!\n\nThis will OVERWRITE your existing installation.\n\nContinue?" 12 60; then
        echo "Installation cancelled."
        exit 0
    fi
fi

# Install required packages
(
echo "10" ; echo "XXX" ; echo "Updating package lists..." ; echo "XXX"
apt-get update >> $LOGFILE 2>&1

echo "30" ; echo "XXX" ; echo "Installing required packages..." ; echo "XXX"
apt-get install -y xvfb lib32gcc-s1 curl wget tar unzip whiptail >> $LOGFILE 2>&1

echo "50" ; echo "XXX" ; echo "Setting up steam user..." ; echo "XXX"
if ! id "steam" &>/dev/null; then
    useradd -d /home/steam -m -s /bin/bash steam >> $LOGFILE 2>&1
fi

echo "70" ; echo "XXX" ; echo "Installing SteamCMD..." ; echo "XXX"
su - steam -c 'mkdir -p /home/steam/steamcmd' >> $LOGFILE 2>&1
su - steam -c 'cd /home/steam/steamcmd && curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -' >> $LOGFILE 2>&1

echo "100" ; echo "XXX" ; echo "Initial setup complete!" ; echo "XXX"
sleep 1
) | whiptail --title "$TITLE" --gauge "Preparing installation..." 8 70 0

# Check disk space
AVAILABLE_SPACE=$(df /home/steam --output=avail | tail -1)
REQUIRED_SPACE=5242880  # 5GB in KB

if [ "$AVAILABLE_SPACE" -lt "$REQUIRED_SPACE" ]; then
    whiptail --title "$TITLE" --msgbox "ERROR: Insufficient disk space!\n\nRequired: 5GB\nAvailable: $((AVAILABLE_SPACE/1024/1024))GB" 10 60
    exit 1
fi

# Download Wurm Unlimited Server
(
echo "0" ; echo "XXX" ; echo "Downloading Wurm Unlimited Server from Steam...\n\nThis may take several minutes.\nPlease be patient..." ; echo "XXX"
su - steam -c '/home/steam/steamcmd/steamcmd.sh +force_install_dir /home/steam/wurm +login anonymous +app_update 402370 validate +quit' >> $LOGFILE 2>&1
echo "100" ; echo "XXX" ; echo "Download complete!" ; echo "XXX"
sleep 1
) | whiptail --title "$TITLE" --gauge "Downloading server files..." 10 70 0

# Ask about modlauncher
MODLAUNCHER_INSTALLED="false"
if whiptail --title "$TITLE" --yesno "Do you want to install the Wurm Server ModLauncher?\n\nThis allows you to use mods on your server." 10 70; then
    (
    echo "25" ; echo "XXX" ; echo "Downloading ModLauncher..." ; echo "XXX"
    MODLAUNCHER_VERSION="0.47"
    cd /tmp
    wget -q https://github.com/ago1024/WurmServerModLauncher/releases/download/v${MODLAUNCHER_VERSION}/server-modlauncher-${MODLAUNCHER_VERSION}.zip >> $LOGFILE 2>&1

    echo "50" ; echo "XXX" ; echo "Extracting files..." ; echo "XXX"
    unzip -o -q server-modlauncher-${MODLAUNCHER_VERSION}.zip -d /home/steam/wurm/ >> $LOGFILE 2>&1
    chown -R steam:steam /home/steam/wurm/ >> $LOGFILE 2>&1

    echo "75" ; echo "XXX" ; echo "Patching server..." ; echo "XXX"
    su - steam -c 'cd /home/steam/wurm && chmod +x patcher.sh && ./patcher.sh' >> $LOGFILE 2>&1

    echo "100" ; echo "XXX" ; echo "ModLauncher installation finished!" ; echo "XXX"
    sleep 1
    ) | whiptail --title "$TITLE" --gauge "Installing ModLauncher..." 8 70 0

    # Check if ModLauncher installed successfully (outside subshell)
    if [ -f /home/steam/wurm/WurmServerLauncher-patched ]; then
        chmod +x /home/steam/wurm/WurmServerLauncher-patched >> $LOGFILE 2>&1
        MODLAUNCHER_INSTALLED="true"
        whiptail --title "$TITLE" --msgbox "ModLauncher was installed successfully!" 8 70
    else
        whiptail --title "$TITLE" --msgbox "ModLauncher installation failed. Check log for details.\n\n$LOGFILE" 10 70
    fi
fi

# Setup X11 libraries
(
echo "50" ; echo "XXX" ; echo "Copying X11 libraries..." ; echo "XXX"
JAVA_LIB_PATH="/home/steam/wurm/runtime/jre1.8.0_172/lib/amd64"
cp /lib/x86_64-linux-gnu/libX11.so.6 $JAVA_LIB_PATH/ >> $LOGFILE 2>&1
cp /lib/x86_64-linux-gnu/libXext.so.6 $JAVA_LIB_PATH/ >> $LOGFILE 2>&1
cp /lib/x86_64-linux-gnu/libXi.so.6 $JAVA_LIB_PATH/ >> $LOGFILE 2>&1
cp /lib/x86_64-linux-gnu/libXrender.so.1 $JAVA_LIB_PATH/ >> $LOGFILE 2>&1
cp /usr/lib/x86_64-linux-gnu/libXtst.so.6 $JAVA_LIB_PATH/ >> $LOGFILE 2>&1
cp /usr/lib/x86_64-linux-gnu/libXtst.so.6.1.0 $JAVA_LIB_PATH/ >> $LOGFILE 2>&1
chown steam:steam $JAVA_LIB_PATH/libX* >> $LOGFILE 2>&1
echo "100" ; echo "XXX" ; echo "Headless support configured!" ; echo "XXX"
sleep 1
) | whiptail --title "$TITLE" --gauge "Setting up headless operation..." 8 70 0

# ============ SERVER CONFIGURATION ============

# Get IP address with better explanation
ip_list=()
ip_count=0
default_ip=""

for ip in $(ip addr | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1 | grep -v "127.0.0.1"); do
    # Try to determine which is the main external IP
    if [[ $ip == 192.168.* ]] || [[ $ip == 10.* ]] || [[ $ip == 172.* ]]; then
        ip_desc="(Local network IP)"
        if [ -z "$default_ip" ]; then
            default_ip=$ip
        fi
    else
        ip_desc="(Public IP)"
        default_ip=$ip  # Prefer public IP
    fi
    ip_list+=("$ip" "$ip_desc")
    ip_count=$((ip_count + 1))
done

if [ $ip_count -gt 0 ]; then
    whiptail --title "$TITLE" --msgbox "IP Address Selection Guide:\n\n\
* If you're hosting on a home network, choose your LOCAL IP (192.168.x.x or 10.x.x.x)\n\
* If you're on a cloud/VPS server, choose the PUBLIC IP\n\
* If unsure, choose the first local IP shown\n\n\
You'll still need to:\n\
- Port forward on your router (home networks)\n\
- Configure firewall rules (cloud/VPS)" 16 75

    SERVER_IP=$(whiptail --title "$TITLE" --menu "Select the IP address for your server:" 20 70 $ip_count "${ip_list[@]}" 3>&1 1>&2 2>&3)
else
    SERVER_IP=$(whiptail --title "$TITLE" --inputbox "Enter the IP address for the server:" 8 70 "" 3>&1 1>&2 2>&3)
fi

# Server Name
SERVER_NAME=$(whiptail --title "$TITLE" --inputbox "What would you like to name your server?\n(No single quotes)" 10 70 "My Wurm Server" 3>&1 1>&2 2>&3)
# Sanitize server name - remove problematic characters
SERVER_NAME=$(echo "$SERVER_NAME" | sed "s/'//g" | sed 's/"//g')

# Admin Password
ADMIN_PWD=$(whiptail --title "$TITLE" --passwordbox "Set an Admin Password\n\nThis unlocks in-game admin commands to change:\n- Skill gain rates\n- Field growth times\n- Other gameplay settings" 12 70 3>&1 1>&2 2>&3)

# Server Password (optional)
if whiptail --title "$TITLE" --yesno "Do you want to password-protect your server?\n\nPlayers will need this password to connect." 10 70; then
    SERVER_PASSWORD=$(whiptail --title "$TITLE" --passwordbox "Enter server password:" 8 70 3>&1 1>&2 2>&3)
else
    SERVER_PASSWORD=""
fi

# Max Players
MAX_PLAYERS=$(whiptail --title "$TITLE" --inputbox "Maximum number of players (1-200):" 8 70 "100" 3>&1 1>&2 2>&3)
if ! [[ "$MAX_PLAYERS" =~ ^[0-9]+$ ]] || [ "$MAX_PLAYERS" -lt 1 ] || [ "$MAX_PLAYERS" -gt 200 ]; then
    MAX_PLAYERS=100
    whiptail --title "$TITLE" --msgbox "Invalid player count. Using default: 100" 8 50
fi

# Home Kingdom
HOME_KINGDOM=$(whiptail --title "$TITLE" --menu "Select the Home Kingdom:\n\nKingdom determines PvP rules and server type." 20 70 5 \
    "4" "Freedom (Creative - Recommended for beginners)" \
    "0" "No Kingdom (Adventure/Creative)" \
    "1" "Jen-Kellon (Adventure/PvP)" \
    "2" "Mol-Rehan (Adventure/PvP)" \
    "3" "Horde of the Summoned (Adventure/PvP)" \
    3>&1 1>&2 2>&3)

# Determine server type based on kingdom
if [ "$HOME_KINGDOM" = "4" ] || [ "$HOME_KINGDOM" = "0" ]; then
    SERVER_TYPE="Creative"
else
    SERVER_TYPE="Adventure"
fi

whiptail --title "$TITLE" --msgbox "Based on your Home Kingdom selection:\n\nServer Type: $SERVER_TYPE\n\nCreative = Faster timers, less hostile\nAdventure = Slower progression, PvP focused" 12 70

# Home Server
if whiptail --title "$TITLE" --yesno "Is this a home server?\n\n(Belongs to a single kingdom - usually YES)" 10 70; then
    HOME_SERVER="true"
else
    HOME_SERVER="false"
fi

# Epic Settings
if whiptail --title "$TITLE" --yesno "Enable Epic mode?\n\n- Faster skillgain\n- Missions affect Valrei\n- Uses Epic skill curve from Wurm Online" 12 70; then
    EPIC_SETTINGS="true"
else
    EPIC_SETTINGS="false"
fi

# PvP
if whiptail --title "$TITLE" --yesno "Enable PvP?\n\n(Player vs Player combat)" 8 70; then
    PVP_ENABLED="true"
else
    PVP_ENABLED="false"
fi

# External Port
EXTERNAL_PORT=$(whiptail --title "$TITLE" --inputbox "Game Port (clients connect here):\n\nDefault: 3724" 10 70 "3724" 3>&1 1>&2 2>&3)
if ! [[ "$EXTERNAL_PORT" =~ ^[0-9]+$ ]] || [ "$EXTERNAL_PORT" -lt 1024 ] || [ "$EXTERNAL_PORT" -gt 65535 ]; then
    EXTERNAL_PORT=3724
    whiptail --title "$TITLE" --msgbox "Invalid port. Using default: 3724" 8 50
fi

# Query Port
QUERY_PORT=$(whiptail --title "$TITLE" --inputbox "Steam Query Port:\n\nAllows server browsers to see your server\nRange: 27016-27030" 11 70 "27017" 3>&1 1>&2 2>&3)
if ! [[ "$QUERY_PORT" =~ ^[0-9]+$ ]] || [ "$QUERY_PORT" -lt 27016 ] || [ "$QUERY_PORT" -gt 27030 ]; then
    QUERY_PORT=27017
    whiptail --title "$TITLE" --msgbox "Invalid query port. Using default: 27017" 8 50
fi

# RMI Ports (with warning)
whiptail --title "$TITLE" --msgbox "The next settings are for multi-server setups.\n\nIf you're running a single server, just use the defaults.\n\nWARNING: Never expose RMI ports to the internet!" 12 70

RMI_PORT=$(whiptail --title "$TITLE" --inputbox "RMI Port (multi-server only):" 8 70 "7220" 3>&1 1>&2 2>&3)
if ! [[ "$RMI_PORT" =~ ^[0-9]+$ ]] || [ "$RMI_PORT" -lt 1024 ] || [ "$RMI_PORT" -gt 65535 ]; then
    RMI_PORT=7220
fi

RMI_REG_PORT=$(whiptail --title "$TITLE" --inputbox "RMI Registry Port (multi-server only):" 8 70 "7221" 3>&1 1>&2 2>&3)
if ! [[ "$RMI_REG_PORT" =~ ^[0-9]+$ ]] || [ "$RMI_REG_PORT" -lt 1024 ] || [ "$RMI_REG_PORT" -gt 65535 ]; then
    RMI_REG_PORT=7221
fi

# Login Server
LOGIN_SERVER="true"

# ============ CREATE CONFIGURATION FILE ============

(
echo "33" ; echo "XXX" ; echo "Creating configuration file..." ; echo "XXX"

cat > /home/steam/wurm/server.cfg << SERVERCONFIG
# Wurm Unlimited Server Configuration
# Generated by installer on $(date)

# ============ MODLOADER STATUS ============
MODLAUNCHER_INSTALLED="$MODLAUNCHER_INSTALLED"

# ============ NETWORK SETTINGS ============
# The IP address the server will bind to
# Leave empty for auto-detect
IP="$SERVER_IP"

# Game port - clients connect through this (Default: 3724 TCP)
EXTERNALPORT="$EXTERNAL_PORT"

# Steam query port - allows server browsers to see your server (27016-27030 UDP)
QUERYPORT="$QUERY_PORT"

# RMI Port - for multi-server communication (Default: 7220 TCP)
# WARNING: Do NOT expose this port to the internet!
RMIPORT="$RMI_PORT"

# RMI Registry Port - for multi-server communication (Default: 7221 TCP)
# WARNING: Do NOT expose this port to the internet!
RMIREGPORT="$RMI_REG_PORT"

# ============ SERVER IDENTITY ============
# Server name visible in server browsers
SERVERNAME="$SERVER_NAME"

# Server password - leave empty for no password
SERVERPASSWORD="$SERVER_PASSWORD"

# ============ ADMIN SETTINGS ============
# Admin password - unlocks in-game admin commands
# Used to change gameplay settings like skill gain rate and field growth time
ADMINPWD="$ADMIN_PWD"

# ============ GAMEPLAY SETTINGS ============
# Maximum number of players (1-200)
MAXPLAYERS=$MAX_PLAYERS

# Enable PvP (true/false)
PVP="$PVP_ENABLED"

# Epic mode - uses Epic server rules from Wurm Online
# Includes Epic skill curve, faster skillgain, missions affect Valrei
EPICSETTINGS="$EPIC_SETTINGS"

# ============ KINGDOM SETTINGS ============
# Home server - belongs to a single kingdom (true/false)
HOMESERVER="$HOME_SERVER"

# Home Kingdom:
#   0 - No kingdom
#   1 - Jen-Kellon
#   2 - Mol-Rehan
#   3 - Horde of the Summoned
#   4 - Freedom
HOMEKINGDOM=$HOME_KINGDOM

# Login server - set to false only if connecting to another server acting as login server
LOGINSERVER="$LOGIN_SERVER"

# ============ SERVER TYPE ============
# Start type - which world folder to load (Creative or Adventure)
START="$SERVER_TYPE"

# ============ FIREWALL PORTS ============
# Make sure these ports are open in your firewall:
#
# Required ports:
#   8766 TCP/UDP    - Steam communication
#   27016-27030 UDP - Steam queries (allows server browsers to see your server)
#   3724 TCP        - Game port (or whatever you set EXTERNALPORT to)
#
# Multi-server only (LOCAL ACCESS ONLY - DO NOT EXPOSE TO INTERNET):
#   7220 TCP        - RMI port
#   7221 TCP        - RMI registry port
SERVERCONFIG

chown steam:steam /home/steam/wurm/server.cfg >> $LOGFILE 2>&1

echo "66" ; echo "XXX" ; echo "Creating startup script..." ; echo "XXX"

cat > /home/steam/wurm/start-wurm.sh << 'STARTSCRIPT'
#!/bin/bash
cd /home/steam/wurm

# Source config
if [ -f ./server.cfg ]; then
  source ./server.cfg
else
  echo "ERROR: Unable to find server.cfg file."
  exit 1
fi

# Start Xvfb on display :99 if not already running
if ! pgrep -x "Xvfb" > /dev/null; then
    Xvfb :99 -screen 0 1024x768x24 > /dev/null 2>&1 &
    XVFB_PID=$!
    sleep 2
else
    XVFB_PID=""
fi

# Export the DISPLAY variable
export DISPLAY=:99

# Ensure LD_LIBRARY_PATH includes all library directories
export LD_LIBRARY_PATH="./linux64:./nativelibs:./lib:${LD_LIBRARY_PATH}"

# Automatically detect and use the best available launcher
if [ -f WurmServerLauncher-patched ]; then
  LAUNCHER='./WurmServerLauncher-patched'
  echo "Starting with ModLauncher (mods enabled)"
elif [ -f WurmServerLauncher ]; then
  LAUNCHER='./WurmServerLauncher'
  echo "Starting with standard launcher"
else
  echo "ERROR: No launcher executable found!"
  exit 1
fi

# Make sure launcher is executable
chmod +x "$LAUNCHER"

# Build command line arguments
ARGS="START=\"$START\""
[ -n "$SERVERNAME" ] && ARGS="$ARGS SERVERNAME=\"$SERVERNAME\""
[ -n "$SERVERPASSWORD" ] && ARGS="$ARGS SERVERPASSWORD=\"$SERVERPASSWORD\""
[ -n "$IP" ] && ARGS="$ARGS IP=\"$IP\""
[ -n "$ADMINPWD" ] && ARGS="$ARGS ADMINPWD=\"$ADMINPWD\""
[ -n "$EXTERNALPORT" ] && ARGS="$ARGS EXTERNALPORT=$EXTERNALPORT"
[ -n "$QUERYPORT" ] && ARGS="$ARGS QUERYPORT=$QUERYPORT"
[ -n "$RMIPORT" ] && ARGS="$ARGS RMIPORT=$RMIPORT"
[ -n "$RMIREGPORT" ] && ARGS="$ARGS RMIREGPORT=$RMIREGPORT"
[ -n "$MAXPLAYERS" ] && ARGS="$ARGS MAXPLAYERS=$MAXPLAYERS"
[ -n "$PVP" ] && ARGS="$ARGS PVP=$PVP"
[ -n "$HOMESERVER" ] && ARGS="$ARGS HOMESERVER=$HOMESERVER"
[ -n "$HOMEKINGDOM" ] && ARGS="$ARGS HOMEKINGDOM=$HOMEKINGDOM"
[ -n "$EPICSETTINGS" ] && ARGS="$ARGS EPICSETTINGS=$EPICSETTINGS"
[ -n "$LOGINSERVER" ] && ARGS="$ARGS LOGINSERVER=$LOGINSERVER"

echo "Starting Wurm Unlimited Server..."
echo "Launcher: $LAUNCHER"

# Start the server
eval "$LAUNCHER" $ARGS

# Cleanup
if [ -n "$XVFB_PID" ]; then
    kill $XVFB_PID 2>/dev/null
fi
STARTSCRIPT

chmod +x /home/steam/wurm/start-wurm.sh >> $LOGFILE 2>&1
chown steam:steam /home/steam/wurm/start-wurm.sh >> $LOGFILE 2>&1

echo "80" ; echo "XXX" ; echo "Setting up world files..." ; echo "XXX"

if [ ! -d "/home/steam/wurm/$SERVER_TYPE" ]; then
    su - steam -c "cp -R /home/steam/wurm/dist/$SERVER_TYPE /home/steam/wurm/" >> $LOGFILE 2>&1
fi

echo "90" ; echo "XXX" ; echo "Creating systemd service..." ; echo "XXX"

cat > /etc/systemd/system/wurm.service << 'SERVICEUNIT'
[Unit]
Description=Wurm Unlimited Server
After=network.target

[Service]
Type=simple
User=steam
Group=steam
WorkingDirectory=/home/steam/wurm
ExecStart=/home/steam/wurm/start-wurm.sh
Restart=on-failure
RestartSec=10
TimeoutStartSec=600
StandardOutput=journal
StandardError=journal
SyslogIdentifier=wurm

[Install]
WantedBy=multi-user.target
SERVICEUNIT

systemctl daemon-reload >> $LOGFILE 2>&1
systemctl enable wurm.service >> $LOGFILE 2>&1

# Optional: Configure UFW firewall
if command -v ufw &> /dev/null; then
    if whiptail --title "$TITLE" --yesno "UFW firewall detected!\n\nAutomatically open required ports?\n\n- 8766 TCP/UDP (Steam)\n- 27016-27030 UDP (Query)\n- $EXTERNAL_PORT TCP (Game)" 14 60; then
        ufw allow 8766/tcp >> $LOGFILE 2>&1
        ufw allow 8766/udp >> $LOGFILE 2>&1
        ufw allow 27016:27030/udp >> $LOGFILE 2>&1
        ufw allow $EXTERNAL_PORT/tcp >> $LOGFILE 2>&1
        whiptail --title "$TITLE" --msgbox "✓ Firewall ports opened successfully!" 8 50
    fi
fi

echo "95" ; echo "XXX" ; echo "Creating management helper..." ; echo "XXX"

# Create wurm management helper script
cat > /usr/local/bin/wurm << 'HELPERSCRIPT'
#!/bin/bash
# Wurm Server Management Script

case "$1" in
    start)
        echo "Starting Wurm Unlimited Server..."
        systemctl start wurm
        sleep 3
        if systemctl is-active --quiet wurm; then
            echo "✓ Server started successfully!"
            echo ""
            echo "The server is now running and connecting to Steam."
            echo "View real-time logs with: wurm logs"
        else
            echo "✗ Server failed to start. Check logs with: wurm logs"
            exit 1
        fi
        ;;
    stop)
        echo "Stopping Wurm Unlimited Server..."
        systemctl stop wurm
        sleep 2
        if ! systemctl is-active --quiet wurm; then
            echo "✓ Server stopped successfully"
        else
            echo "⚠ Server may still be stopping..."
        fi
        ;;
    restart)
        echo "Restarting Wurm Unlimited Server..."
        systemctl restart wurm
        sleep 3
        if systemctl is-active --quiet wurm; then
            echo "✓ Server restarted successfully!"
            echo ""
            echo "View logs with: wurm logs"
        else
            echo "✗ Server failed to restart. Check logs with: wurm logs"
            exit 1
        fi
        ;;
    status)
        systemctl status wurm --no-pager
        echo ""
        if systemctl is-active --quiet wurm; then
            echo "✓ Server is running"
        else
            echo "✗ Server is not running"
        fi
        ;;
    logs)
        echo "Showing Wurm server logs (Press Ctrl+C to exit)"
        echo "=============================================="
        sleep 1
        journalctl -u wurm -f
        ;;
    config)
        if [ -f /home/steam/wurm/server.cfg ]; then
            ${EDITOR:-nano} /home/steam/wurm/server.cfg
        else
            echo "Configuration file not found at /home/steam/wurm/server.cfg"
            exit 1
        fi
        ;;
    *)
        echo "╔════════════════════════════════════════════════╗"
        echo "║      Wurm Unlimited Server Manager             ║"
        echo "╚════════════════════════════════════════════════╝"
        echo ""
        echo "Usage: wurm {start|stop|restart|status|logs|config}"
        echo ""
        echo "Commands:"
        echo "  start   - Start the server"
        echo "  stop    - Stop the server"
        echo "  restart - Restart the server"
        echo "  status  - Show server status"
        echo "  logs    - Show real-time server logs"
        echo "  config  - Edit server configuration"
        echo ""
        echo "Examples:"
        echo "  sudo wurm start"
        echo "  sudo wurm logs"
        echo "  sudo wurm config"
        exit 1
        ;;
esac
HELPERSCRIPT

chmod +x /usr/local/bin/wurm >> $LOGFILE 2>&1

echo "100" ; echo "XXX" ; echo "Installation complete!" ; echo "XXX"
sleep 1

) | whiptail --title "$TITLE" --gauge "Finalizing installation..." 8 70 0

# Show completion message with port information
whiptail --title "$TITLE" --msgbox "╔════════════════════════════════════════════════════╗\n\
║        Installation Complete Successfully!         ║\n\
╚════════════════════════════════════════════════════╝\n\n\
Configuration: /home/steam/wurm/server.cfg\n\
Server Location: /home/steam/wurm/\n\
ModLauncher: $MODLAUNCHER_INSTALLED\n\n\
IMPORTANT - Open these ports in your firewall:\n\
  8766 TCP/UDP    - Steam communication\n\
  27016-27030 UDP - Steam queries\n\
  $EXTERNAL_PORT TCP        - Game port\n\n\
Easy Server Management (with feedback):\n\
  Start:    sudo wurm start\n\
  Stop:     sudo wurm stop\n\
  Status:   sudo wurm status\n\
  Logs:     sudo wurm logs\n\
  Config:   sudo wurm config" 26 70

clear
cat << FINAL

╔════════════════════════════════════════════════════════════╗
║                                                            ║
║        Wurm Unlimited Server Installation Complete!        ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝

Server Configuration: /home/steam/wurm/server.cfg
Server Location: /home/steam/wurm/
ModLauncher Installed: $MODLAUNCHER_INSTALLED

╔═══════════════════════════════════════════════════════════╗
║               EASY SERVER COMMANDS (Recommended)          ║
╚═══════════════════════════════════════════════════════════╝

  Start Server:     sudo wurm start
  Stop Server:      sudo wurm stop
  Restart Server:   sudo wurm restart
  Check Status:     sudo wurm status
  View Logs:        sudo wurm logs
  Edit Config:      sudo wurm config

╔═══════════════════════════════════════════════════════════╗
║               SYSTEMCTL COMMANDS (Advanced Users)         ║
╚═══════════════════════════════════════════════════════════╝

  Start:    sudo systemctl start wurm
  Stop:     sudo systemctl stop wurm
  Restart:  sudo systemctl restart wurm
  Status:   sudo systemctl status wurm
  Logs:     sudo journalctl -u wurm -f

╔═══════════════════════════════════════════════════════════╗
║             FIREWALL PORTS (MUST OPEN THESE)              ║
╚═══════════════════════════════════════════════════════════╝

  8766 TCP/UDP    - Steam communication
  27016-27030 UDP - Steam queries
  $EXTERNAL_PORT TCP        - Game port

╔═══════════════════════════════════════════════════════════╗
║                         NEXT STEPS                        ║
╚═══════════════════════════════════════════════════════════╝

1. Open the firewall ports listed above
2. If on home network: Configure port forwarding on your router
3. Start the server: sudo wurm start
4. Watch it start: sudo wurm logs

Your server will be visible in the Wurm Unlimited server browser!

Installation log saved to: $LOGFILE

FINAL