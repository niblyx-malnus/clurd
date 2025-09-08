#!/bin/bash
# Run clurd with automatic setup

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "Setting up clurd environment..."
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
else
    # Activate virtual environment
    source venv/bin/activate
fi

# Check if config exists
if [ ! -f "config.json" ]; then
    echo "Config not found. Creating from example..."
    if [ -f "config.example.json" ]; then
        cp config.example.json config.json
        echo "✓ Created config.json - please edit with your ship details"
        echo "  Get your access code with: ./run.sh dojo '+code'"
    else
        echo "⚠️ config.example.json not found - please create config.json manually"
    fi
fi

# Run the requested command
if [ $# -eq 0 ]; then
    echo "Usage: ./run.sh <command> [args...]"
    echo "Examples:"
    echo "  ./run.sh dojo '(add 5 4)'"
    echo "  ./run.sh get 10"
    echo "  ./run.sh dojo '+code'          # Get your access code"
    echo "  ./run.sh dojo '\\t' --no-enter   # Tab completion"
else
    ./"$@"
fi