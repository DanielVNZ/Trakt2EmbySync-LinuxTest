#!/bin/bash

# Trakt2EmbySync Runner Script

# Base directory is where the script is located
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Activate virtual environment
source "${BASE_DIR}/venv/bin/activate"

# Run the app (with optional mode parameter)
MODE=${1:-"all"}  # Default to running both web and scheduler
echo "🎬 Starting Trakt2EmbySync in ${MODE} mode..."

case "$MODE" in
    "web")
        # Run only Streamlit web interface
        cd "${BASE_DIR}"
        echo "📊 Starting web interface only..."
        # Use --server.address 0.0.0.0 to make it accessible from any device on the network
        streamlit run app.py --server.address 0.0.0.0 --server.headless true
        ;;
    "scheduler")
        # Run only console mode scheduler
        cd "${BASE_DIR}"
        echo "⏱️ Starting background scheduler only..."
        python console_runner.py --mode "scheduler"
        ;;
    "sync_once")
        # Run one-time sync
        cd "${BASE_DIR}"
        echo "🔄 Running one-time sync..."
        python console_runner.py --mode "sync_once"
        ;;
    "check_config")
        # Check configuration
        cd "${BASE_DIR}"
        echo "🔍 Checking configuration..."
        python console_runner.py --mode "check_config"
        ;;
    "all")
        # Run both web interface and scheduler in background
        cd "${BASE_DIR}"
        echo "🌐 Starting both web interface and background scheduler..."
        
        # Start the console_runner in the background
        echo "⏱️ Starting background scheduler..."
        python console_runner.py --mode "scheduler" &
        SCHEDULER_PID=$!
        echo "✅ Scheduler started with PID: $SCHEDULER_PID"
        
        # Make sure the scheduler process gets terminated when this script exits
        trap "echo '🛑 Stopping background scheduler...'; kill $SCHEDULER_PID 2>/dev/null" EXIT
        
        # Start the web interface in the foreground
        echo "📊 Starting web interface..."
        echo "Note: Web interface available at http://$(hostname -I | awk '{print $1}'):8501"
        streamlit run app.py --server.address 0.0.0.0 --server.headless true
        ;;
    *)
        echo "❌ Unknown mode: $MODE"
        echo "Usage: ./run.sh [mode]"
        echo "Available modes:"
        echo "  all          - Run both web interface and background scheduler (default)"
        echo "  web          - Run only web interface"
        echo "  scheduler    - Run only background scheduler"
        echo "  sync_once    - Run a one-time sync"
        echo "  check_config - Check configuration"
        exit 1
        ;;
esac
