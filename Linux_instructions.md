# Trakt2EmbySync - Linux Installation Guide

This guide provides instructions for installing and running Trakt2EmbySync on Linux systems, with specific considerations for Raspberry Pi 4 (ARM64).

## System Requirements

- Linux-based operating system (tested on Raspberry Pi OS, Ubuntu, Debian)
- Python 3.7 or higher
- Internet connection
- Trakt account
- Emby server (local or remote)

## Installation

### 1. Download the Repository

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/Trakt2EmbySync.git
cd Trakt2EmbySync
```

### 2. Run the Setup Script

The included setup script will automatically create a Python virtual environment, install dependencies, and optionally configure autostart services.

```bash
# Make the setup script executable
chmod +x setup.sh

# Run the setup script
./setup.sh
```

During setup, you'll be asked if you want to configure autostart options. You can choose from:

- **Console runner only**: Runs only the background sync service
- **Web UI only**: Runs only the web interface
- **Both services separately**: Runs both as independent services
- **Complete service**: Runs both web interface and scheduler together
- **None**: No autostart configuration

## Configuration

The first time you run the application, you'll need to configure:

1. **Trakt API Access**: Connect to your Trakt account
2. **Emby Server Details**: Server URL and API key
3. **Emby Libraries**: Select which libraries to sync with
4. **Trakt Lists**: Configure which Trakt lists to sync with which Emby libraries
5. **Sync Schedule**: Configure when and how often to sync

Configuration is done through the web interface, which is accessible at:
```
http://[raspberry-pi-ip]:8501
```

## Usage

The `run.sh` script provides several ways to run the application:

### Run Modes

```bash
# Run both web interface and scheduler (complete mode)
./run.sh all

# Run only the web interface
./run.sh web

# Run only the background scheduler
./run.sh scheduler

# Run a one-time sync
./run.sh sync_once

# Check configuration
./run.sh check_config
```

### Running as a Service

If you configured autostart during setup, the services will start automatically on boot. You can also manually control them:

```bash
# Start the complete service (web + scheduler)
sudo systemctl start trakt2embysync-all

# Check service status
sudo systemctl status trakt2embysync-all

# Stop the service
sudo systemctl stop trakt2embysync-all

# Enable/disable autostart
sudo systemctl enable trakt2embysync-all
sudo systemctl disable trakt2embysync-all
```

You can replace `trakt2embysync-all` with:
- `trakt2embysync` for the scheduler-only service
- `trakt2embysync-web` for the web interface-only service

## Troubleshooting

### 1. Web Interface Not Accessible

If you cannot access the web interface from other devices:

- Ensure you're using the correct IP address and port (8501)
- Check your firewall settings to make sure port 8501 is open
- Verify the service is running: `sudo systemctl status trakt2embysync-web` or `sudo systemctl status trakt2embysync-all`

### 2. Syncing Issues

If content isn't syncing properly between Trakt and Emby:

- Check the configuration in the web interface
- Look for any error messages in the sync logs
- Verify that the application is using multiple ID types for matching content between Trakt and Emby (IMDB, TMDB, Trakt ID, and TVDB)

### 3. Viewing Logs

To view service logs:

```bash
# View logs for the complete service
sudo journalctl -u trakt2embysync-all -f

# View logs for the web interface only
sudo journalctl -u trakt2embysync-web -f

# View logs for the scheduler only
sudo journalctl -u trakt2embysync -f
```

## Updating

To update Trakt2EmbySync:

```bash
# Pull the latest changes from GitHub
git pull

# Run the setup script again to update dependencies
./setup.sh

# Restart the service if running as a systemd service
sudo systemctl restart trakt2embysync-all
```

## Uninstallation

To completely remove Trakt2EmbySync:

```bash
# Stop and disable the services
sudo systemctl stop trakt2embysync-all trakt2embysync-web trakt2embysync
sudo systemctl disable trakt2embysync-all trakt2embysync-web trakt2embysync

# Remove the systemd service files
sudo rm /etc/systemd/system/trakt2embysync*.service
sudo systemctl daemon-reload

# Delete the application directory
rm -rf /path/to/Trakt2EmbySync
```

## Advanced Configuration

### Custom Sync Intervals

You can customize the sync interval by editing the `.env` file or through the web interface. Supported formats include:
- `1h` - Every hour
- `6h` - Every 6 hours
- `1d` - Every day
- `1w` - Every week

### Memory Usage Optimization

On a Raspberry Pi with limited RAM, you may want to adjust the scheduler to run at off-peak times. Configure this through the web interface by setting specific sync times and days.
