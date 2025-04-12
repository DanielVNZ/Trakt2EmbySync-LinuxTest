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
    # Use --server.address 0.0.0.0 to make it accessible from any device on the network
    streamlit run app.py --server.address 0.0.0.0 --server.headless true
    # Note: Now accessible at http://raspberry-pi-ip:8501
else
    # Run console mode (scheduler, sync_once, or check_config)
    cd "${BASE_DIR}"
    python console_runner.py --mode "${MODE}"
fi
