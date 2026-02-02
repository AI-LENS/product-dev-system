#!/bin/bash

echo ""
echo "██████╗ ███████╗██╗   ██╗███████╗██╗      ██████╗ ██╗    ██╗"
echo "██╔══██╗██╔════╝██║   ██║██╔════╝██║     ██╔═══██╗██║    ██║"
echo "██║  ██║█████╗  ██║   ██║█████╗  ██║     ██║   ██║██║ █╗ ██║"
echo "██║  ██║██╔══╝  ╚██╗ ██╔╝██╔══╝  ██║     ██║   ██║██║███╗██║"
echo "██████╔╝███████╗ ╚████╔╝ ██║     ███████╗╚██████╔╝╚███╔███╔╝"
echo "╚═════╝ ╚══════╝  ╚═══╝  ╚═╝     ╚══════╝ ╚═════╝  ╚══╝╚══╝"
echo ""
echo "┌──────────────────────────────────┐"
echo "│  DevFlow by AI LENS              │"
echo "│  End-to-End Product Development  │"
echo "└──────────────────────────────────┘"
echo ""

set -e

# Detect OS
OS="$(uname -s)"
case "$OS" in
    Linux*)  PLATFORM=linux ;;
    Darwin*) PLATFORM=macos ;;
    *)       echo "❌ Unsupported OS: $OS"; exit 1 ;;
esac

echo "Platform: $PLATFORM"
echo ""

# Check prerequisites
echo "🔍 Checking prerequisites..."

# Git
if command -v git &> /dev/null; then
    echo "  ✅ Git $(git --version | cut -d' ' -f3)"
else
    echo "  ❌ Git not found. Install: https://git-scm.com/"
    exit 1
fi

# GitHub CLI
if command -v gh &> /dev/null; then
    echo "  ✅ GitHub CLI $(gh --version | head -1 | cut -d' ' -f3)"
else
    echo "  ⚠️  GitHub CLI not found. Installing..."
    if [ "$PLATFORM" = "macos" ] && command -v brew &> /dev/null; then
        brew install gh
    elif [ "$PLATFORM" = "linux" ] && command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y gh
    else
        echo "  ❌ Please install GitHub CLI manually: https://cli.github.com/"
        exit 1
    fi
fi

# Python
if command -v python3 &> /dev/null; then
    echo "  ✅ Python $(python3 --version | cut -d' ' -f2)"
elif command -v python &> /dev/null; then
    echo "  ✅ Python $(python --version | cut -d' ' -f2)"
else
    echo "  ❌ Python not found. Install: https://www.python.org/"
    exit 1
fi

# Claude Code
if command -v claude &> /dev/null; then
    echo "  ✅ Claude Code installed"
else
    echo "  ⚠️  Claude Code not detected (optional but recommended)"
fi

echo ""
echo "🔐 Checking GitHub authentication..."
if gh auth status &> /dev/null; then
    echo "  ✅ GitHub authenticated"
else
    echo "  ⚠️  GitHub not authenticated"
    echo "  Running: gh auth login"
    gh auth login
fi

# Check for gh-sub-issue extension
echo ""
echo "📦 Checking gh extensions..."
if gh extension list 2>/dev/null | grep -q "yahsan2/gh-sub-issue"; then
    echo "  ✅ gh-sub-issue extension installed"
else
    echo "  📥 Installing gh-sub-issue extension..."
    gh extension install yahsan2/gh-sub-issue 2>/dev/null || echo "  ⚠️  Could not install gh-sub-issue (optional)"
fi

echo ""
echo "📁 Setting up DevFlow directories..."

# Create .claude structure that maps to devflow
mkdir -p .claude/commands/pm
mkdir -p .claude/commands/context
mkdir -p .claude/commands/design
mkdir -p .claude/commands/init
mkdir -p .claude/commands/arch
mkdir -p .claude/commands/db
mkdir -p .claude/commands/api
mkdir -p .claude/commands/ai
mkdir -p .claude/commands/testing
mkdir -p .claude/commands/quality
mkdir -p .claude/commands/deploy
mkdir -p .claude/commands/review
mkdir -p .claude/rules
mkdir -p .claude/agents
mkdir -p .claude/scripts/pm
mkdir -p .claude/scripts/common
mkdir -p .claude/hooks
mkdir -p .claude/context
mkdir -p .claude/prds
mkdir -p .claude/epics
mkdir -p .claude/specs
mkdir -p .claude/adrs

echo "  ✅ Directories created"

# Copy DevFlow files to .claude
echo ""
echo "📝 Installing DevFlow components..."

if [ -d "devflow" ]; then
    # Copy commands
    cp -r devflow/commands/* .claude/commands/ 2>/dev/null && echo "  ✅ Commands installed"
    # Copy rules
    cp -r devflow/rules/* .claude/rules/ 2>/dev/null && echo "  ✅ Rules installed"
    # Copy agents
    cp -r devflow/agents/* .claude/agents/ 2>/dev/null && echo "  ✅ Agents installed"
    # Copy scripts
    cp -r devflow/scripts/* .claude/scripts/ 2>/dev/null && echo "  ✅ Scripts installed"
    chmod +x .claude/scripts/pm/*.sh 2>/dev/null
    chmod +x .claude/scripts/common/*.sh 2>/dev/null
    # Copy hooks
    cp -r devflow/hooks/* .claude/hooks/ 2>/dev/null && echo "  ✅ Hooks installed"
    chmod +x .claude/hooks/*.sh 2>/dev/null
else
    echo "  ⚠️  devflow/ directory not found. Skipping file copy."
fi

echo ""
echo "✅ DevFlow Installation Complete!"
echo "================================="
echo ""
echo "🎯 Next Steps:"
echo "  1. Initialize: /devflow:init"
echo "  2. Set principles: /devflow:principles"
echo "  3. Create context: /context:create"
echo "  4. Start building: /pm:prd-new <feature-name>"
echo ""
echo "📚 Documentation: README.md"
echo ""

exit 0
