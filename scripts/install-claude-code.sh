#!/bin/bash
# =====================================================
# Install/Run Claude Code CLI
# Standalone script for Ubuntu/Debian
# =====================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║           CLAUDE CODE                                     ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    CLAUDE_USER="claude"

    # Create claude user if not exists
    if ! id "$CLAUDE_USER" &>/dev/null; then
        echo "Creating user '$CLAUDE_USER'..."
        useradd -m -s /bin/bash "$CLAUDE_USER"
        echo -e "${GREEN}User '$CLAUDE_USER' created${NC}"
    fi

    RUN_AS="su - $CLAUDE_USER -c"
    CLAUDE_HOME="/home/claude"
else
    CLAUDE_USER="$USER"
    RUN_AS="bash -c"
    CLAUDE_HOME="$HOME"
fi

# Function to run claude
run_claude() {
    echo ""
    echo -e "${GREEN}Starting Claude Code...${NC}"
    echo ""

    if [ "$EUID" -eq 0 ]; then
        cd "$CLAUDE_HOME"
        exec su - claude -c "cd $CLAUDE_HOME && claude --dangerously-skip-permissions"
    else
        cd "$CLAUDE_HOME"
        exec claude --dangerously-skip-permissions
    fi
}

# Check if Claude Code already installed
if $RUN_AS "which claude" &>/dev/null; then
    echo -e "${GREEN}Claude Code is installed${NC}"
    run_claude
fi

# Not installed - proceed with installation
echo ""
echo "Installing Claude Code..."
echo ""

# Check/Install Node.js
if ! command -v node &>/dev/null; then
    echo -e "${YELLOW}Node.js not found. Installing...${NC}"
    if [ "$EUID" -eq 0 ]; then
        curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
        apt-get install -y nodejs
    else
        echo -e "${RED}Node.js is required. Please install it first:${NC}"
        echo "  curl -fsSL https://deb.nodesource.com/setup_22.x | sudo bash -"
        echo "  sudo apt-get install -y nodejs"
        exit 1
    fi
fi
echo -e "${GREEN}Node.js: $(node --version)${NC}"

# Install Claude Code
if [ "$EUID" -eq 0 ]; then
    su - $CLAUDE_USER -c 'curl -fsSL https://claude.ai/install.sh | bash'
    # Add ~/.local/bin to PATH if not already there
    if ! su - $CLAUDE_USER -c 'grep -q "\.local/bin" ~/.bashrc' 2>/dev/null; then
        su - $CLAUDE_USER -c 'echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> ~/.bashrc'
        echo -e "${GREEN}Added ~/.local/bin to PATH${NC}"
    fi
else
    curl -fsSL https://claude.ai/install.sh | bash
    # Add ~/.local/bin to PATH if not already there
    if ! grep -q "\.local/bin" ~/.bashrc 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
        echo -e "${GREEN}Added ~/.local/bin to PATH${NC}"
    fi
fi

echo ""

# Verify installation and run
if $RUN_AS "which claude" &>/dev/null; then
    echo -e "${GREEN}Installation successful!${NC}"
    run_claude
else
    echo ""
    echo -e "${RED}Installation may have failed.${NC}"
    echo ""
    echo "Try manually:"
    echo "  curl -fsSL https://claude.ai/install.sh | sh"
    exit 1
fi
