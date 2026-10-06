#!/usr/bin/env bash
# install.sh - Install the kubectl pod-topology plugin
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN="$SCRIPT_DIR/kubectl-pod_topology"

echo ""
echo "=== kubectl pod-topology installer ==="
echo ""

# Make the plugin executable
chmod +x "$PLUGIN"

# Install to a directory on PATH
INSTALL_DIR="/usr/local/bin"
if [[ ! -w "$INSTALL_DIR" ]]; then
    echo "INFO: /usr/local/bin is not writable, trying ~/bin ..."
    INSTALL_DIR="$HOME/bin"
    mkdir -p "$INSTALL_DIR"
fi

cp "$PLUGIN" "$INSTALL_DIR/kubectl-pod-topology"
# Backward-compatible alias for direct execution
cp "$PLUGIN" "$INSTALL_DIR/kubectl-pod_topology"
echo "Plugin installed to: $INSTALL_DIR/kubectl-pod-topology"

# Check PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo ""
    echo "WARNING: $INSTALL_DIR is not in your PATH."
    echo "Add the following line to your ~/.zshrc or ~/.bashrc:"
    echo "  export PATH=\"\$PATH:$INSTALL_DIR\""
fi

# Install Python dependencies
echo ""
echo "Installing Python dependencies ..."
if command -v pip3 &>/dev/null; then
    pip3 install -r "$SCRIPT_DIR/requirements.txt"
elif command -v pip &>/dev/null; then
    pip install -r "$SCRIPT_DIR/requirements.txt"
else
    echo "ERROR: pip not found. Please install Python 3 and pip first."
    exit 1
fi

# Remind about local env files
echo ""
if [[ ! -f "$SCRIPT_DIR/.env" && ! -f "$SCRIPT_DIR/.env.local" ]]; then
    cp "$SCRIPT_DIR/.env.example" "$SCRIPT_DIR/.env.local"
    echo "Created .env.local from .env.example"
    echo "IMPORTANT: Edit $SCRIPT_DIR/.env.local and fill in your API keys before using the plugin."
else
    echo "Local env file already exists - skipping creation."
fi

echo ""
echo "=== Installation complete ==="
echo ""
echo "Usage:"
echo "  kubectl pod-topology <pod-name> -n <namespace>"
echo "  kubectl pod-topology nginx-topology -n default"
echo "  kubectl pod-topology nginx-topology -n default -o /tmp/out.png"
echo ""
