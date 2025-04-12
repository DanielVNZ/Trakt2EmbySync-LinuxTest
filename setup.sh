#!/bin/bash

# Trakt2EmbySync Setup Script for Raspberry Pi 4 (ARM64)
# This script installs dependencies and configures the application

set -e  # Exit on any error

echo "=========================================="
echo "🎬 Trakt2EmbySync - Raspberry Pi Setup Script"
echo "=========================================="

# Check if running as root
if [ "$(id -u)" -eq 0 ]; then
    echo "⚠️ This script should not be run as root. Please run as regular user."
    exit 1
fi

# Base directory is where the script is located
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "📂 Base directory: ${BASE_DIR}"

# Create virtual environment if it doesn't exist
if [ ! -d "${BASE_DIR}/venv" ]; then
    echo "🔧 Creating Python virtual environment..."
    python3 -m venv "${BASE_DIR}/venv"
fi

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source "${BASE_DIR}/venv/bin/activate"

# Install dependencies
echo "📦 Installing dependencies..."
pip install --upgrade pip
pip install -r "${BASE_DIR}/requirements.txt"

# Create run script
echo "📝 Creating run script..."
cat > "${BASE_DIR}/run.sh" << 'EOL'
#!/bin/bash

# Trakt2EmbySync Runner Script

# Base directory is where the script is located
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Activate virtual environment
source "${BASE_DIR}/venv/bin/activate"

# Run the app (with optional mode parameter)
MODE=${1:-"scheduler"}  # Default to scheduler mode if not specified
echo "🎬 Starting Trakt2EmbySync in ${MODE} mode..."

if [ "$MODE" == "web" ]; then
    # Run Streamlit web interface
    cd "${BASE_DIR}"
    streamlit run app.py
elif [ "$MODE" == "all" ]; then
    # Run both web interface and scheduler
    cd "${BASE_DIR}"
    streamlit run app.py &
    python console_runner.py --mode "scheduler"
else
    # Run console mode (scheduler, sync_once, or check_config)
    cd "${BASE_DIR}"
    python console_runner.py --mode "${MODE}"
fi
EOL

# Make run script executable
chmod +x "${BASE_DIR}/run.sh"

# Ask if user wants to setup auto-start
echo ""
echo "Would you like to set up auto-start on boot? (y/n)"
read -r setup_autostart

if [[ "$setup_autostart" =~ ^[Yy]$ ]]; then
    echo "🔧 Setting up auto-start on boot..."
    
    # Create systemd service files
    echo "📝 Creating systemd service files..."
    
    # Console runner service (for background syncing)
    sudo tee /etc/systemd/system/trakt2embysync.service > /dev/null << EOL
[Unit]
Description=Trakt2EmbySync Console Runner
After=network.target

[Service]
Type=simple
User=$(whoami)
WorkingDirectory=${BASE_DIR}
ExecStart=${BASE_DIR}/run.sh scheduler
Restart=on-failure
RestartSec=10
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOL

    # Web UI service
    sudo tee /etc/systemd/system/trakt2embysync-web.service > /dev/null << EOL
[Unit]
Description=Trakt2EmbySync Web Interface
After=network.target

[Service]
Type=simple
User=$(whoami)
WorkingDirectory=${BASE_DIR}
ExecStart=${BASE_DIR}/run.sh web
Restart=on-failure
RestartSec=10
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOL

    # Combined service (both web and scheduler)
    sudo tee /etc/systemd/system/trakt2embysync-all.service > /dev/null << EOL
[Unit]
Description=Trakt2EmbySync Complete (Web + Scheduler)
After=network.target

[Service]
Type=simple
User=$(whoami)
WorkingDirectory=${BASE_DIR}
ExecStart=${BASE_DIR}/run.sh all
Restart=on-failure
RestartSec=10
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOL

    # Reload systemd
    sudo systemctl daemon-reload

    # Ask which services to enable
    echo ""
    echo "Which services would you like to enable at startup?"
    echo "1) Console runner only (background sync)"
    echo "2) Web UI only"
    echo "3) Both console runner and web UI"
    echo "4) Complete (Web + Scheduler)"
    echo "5) None (I'll enable them manually later)"
    read -r service_choice

    case $service_choice in
        1)
            sudo systemctl enable trakt2embysync.service
            echo "✅ Console runner service enabled. It will start automatically on boot."
            echo "   You can manually start it with: sudo systemctl start trakt2embysync"
            ;;
        2)
            sudo systemctl enable trakt2embysync-web.service
            echo "✅ Web UI service enabled. It will start automatically on boot."
            echo "   You can manually start it with: sudo systemctl start trakt2embysync-web"
            echo "   The web interface will be available at http://localhost:8501"
            ;;
        3)
            sudo systemctl enable trakt2embysync.service
            sudo systemctl enable trakt2embysync-web.service
            echo "✅ Both services enabled. They will start automatically on boot."
            echo "   You can manually start them with:"
            echo "   - sudo systemctl start trakt2embysync"
            echo "   - sudo systemctl start trakt2embysync-web"
            echo "   The web interface will be available at http://localhost:8501"
            ;;
        4)
            sudo systemctl enable trakt2embysync-all.service
            echo "✅ Complete service enabled. It will start automatically on boot."
            echo "   You can manually start it with: sudo systemctl start trakt2embysync-all"
            echo "   The web interface will be available at http://localhost:8501"
            ;;
        *)
            echo "No services enabled. You can enable them later with:"
            echo "- sudo systemctl enable trakt2embysync.service"
            echo "- sudo systemctl enable trakt2embysync-web.service"
            echo "- sudo systemctl enable trakt2embysync-all.service"
            ;;
    esac

    # Ask if user wants to start the services now
    echo ""
    echo "Would you like to start the services now? (y/n)"
    read -r start_now

    if [[ "$start_now" =~ ^[Yy]$ ]]; then
        case $service_choice in
            1)
                sudo systemctl start trakt2embysync.service
                echo "✅ Console runner service started."
                ;;
            2)
                sudo systemctl start trakt2embysync-web.service
                echo "✅ Web UI service started. Access it at http://localhost:8501"
                ;;
            3)
                sudo systemctl start trakt2embysync.service
                sudo systemctl start trakt2embysync-web.service
                echo "✅ Both services started. Web UI available at http://localhost:8501"
                ;;
            4)
                sudo systemctl start trakt2embysync-all.service
                echo "✅ Complete service started. Web UI available at http://localhost:8501"
                ;;
            *)
                echo "No services started."
                ;;
        esac
    fi
fi

echo ""
echo "=========================================="
echo "✅ Setup complete!"
echo ""
echo "You can run the application using:"
echo "- Console mode: ./run.sh"
echo "- Web interface: ./run.sh web"
echo "- One-time sync: ./run.sh sync_once"
echo "- Check config: ./run.sh check_config"
echo "- Complete (Web + Scheduler): ./run.sh all"
echo "=========================================="
