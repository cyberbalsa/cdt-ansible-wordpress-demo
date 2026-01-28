#!/bin/bash
# SSH Key Setup Script for Ansible Demo
# This script sets up SSH keys for connecting to your lab servers

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "  Ansible Demo - SSH Key Setup"
echo "=========================================="
echo ""

# Configuration
JUMP_HOST="sshjump@ssh.cyberrange.rit.edu"
REMOTE_USER="cyberrange"
REMOTE_PASS="Cyberrange123!"
KEY_FILE="$HOME/.ssh/id_ed25519"

# Check if sshpass is installed
if ! command -v sshpass &> /dev/null; then
    echo -e "${YELLOW}Installing sshpass...${NC}"
    sudo apt-get update && sudo apt-get install -y sshpass
fi

# Step 1: Check for existing SSH key
echo "Step 1: Checking for SSH key..."
if [ -f "$KEY_FILE" ]; then
    echo -e "${GREEN}✓ SSH key already exists at $KEY_FILE${NC}"
else
    echo -e "${YELLOW}No SSH key found. Generating new key...${NC}"
    ssh-keygen -t ed25519 -f "$KEY_FILE" -N "" -C "ansible-demo-key"
    echo -e "${GREEN}✓ SSH key generated${NC}"
fi
echo ""

# Step 2: Read server IPs from inventory
echo "Step 2: Reading server IPs from inventory..."
if [ ! -f "inventory.ini" ]; then
    echo -e "${RED}Error: inventory.ini not found!${NC}"
    echo "Make sure you're running this script from the project directory."
    exit 1
fi

# Extract IPs from inventory
SERVERS=$(grep "ansible_host=" inventory.ini | sed 's/.*ansible_host=//' | tr -d ' ')
echo "Found servers:"
echo "$SERVERS"
echo ""

# Step 3: Set up SSH config for jump host
echo "Step 3: Configuring SSH for jump host..."
SSH_CONFIG="$HOME/.ssh/config"

# Backup existing config if it exists
if [ -f "$SSH_CONFIG" ]; then
    cp "$SSH_CONFIG" "$SSH_CONFIG.backup.$(date +%s)"
fi

# Add jump host configuration if not already present
if ! grep -q "Host ssh.cyberrange.rit.edu" "$SSH_CONFIG" 2>/dev/null; then
    cat >> "$SSH_CONFIG" << 'EOF'

# Ansible Demo - CyberRange Jump Host
Host ssh.cyberrange.rit.edu
    User sshjump
    StrictHostKeyChecking no

Host 100.65.*
    User cyberrange
    ProxyJump sshjump@ssh.cyberrange.rit.edu
    StrictHostKeyChecking no
EOF
    chmod 600 "$SSH_CONFIG"
    echo -e "${GREEN}✓ SSH config updated${NC}"
else
    echo -e "${GREEN}✓ SSH config already configured${NC}"
fi
echo ""

# Step 4: Copy SSH key to each server
echo "Step 4: Copying SSH key to servers..."
echo "(You may see some warnings - that's normal)"
echo ""

for SERVER in $SERVERS; do
    echo -n "  Copying key to $SERVER... "

    # Use sshpass to copy the key through the jump host
    if sshpass -p "$REMOTE_PASS" ssh-copy-id \
        -o StrictHostKeyChecking=no \
        -o ProxyJump="$JUMP_HOST" \
        -i "$KEY_FILE.pub" \
        "$REMOTE_USER@$SERVER" 2>/dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${YELLOW}(may already be configured)${NC}"
    fi
done
echo ""

# Step 5: Test connections
echo "Step 5: Testing connections..."
echo ""

ALL_OK=true
for SERVER in $SERVERS; do
    echo -n "  Testing $SERVER... "
    if ssh -o ConnectTimeout=10 -o ProxyJump="$JUMP_HOST" "$REMOTE_USER@$SERVER" "echo ok" 2>/dev/null | grep -q "ok"; then
        echo -e "${GREEN}✓ Connected!${NC}"
    else
        echo -e "${RED}✗ Failed${NC}"
        ALL_OK=false
    fi
done
echo ""

if $ALL_OK; then
    echo "=========================================="
    echo -e "${GREEN}  All servers connected successfully!${NC}"
    echo "=========================================="
    echo ""
    echo "You can now run Ansible commands:"
    echo "  ansible all -m ping"
    echo ""
else
    echo "=========================================="
    echo -e "${RED}  Some connections failed${NC}"
    echo "=========================================="
    echo "Check that your servers are running and try again."
fi
