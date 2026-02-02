#!/bin/bash

echo "Initializing..."
echo ""
echo ""

echo "██████╗ ███████╗██╗   ██╗███████╗██╗      ██████╗ ██╗    ██╗"
echo "██╔══██╗██╔════╝██║   ██║██╔════╝██║     ██╔═══██╗██║    ██║"
echo "██║  ██║█████╗  ██║   ██║█████╗  ██║     ██║   ██║██║ █╗ ██║"
echo "██║  ██║██╔══╝  ╚██╗ ██╔╝██╔══╝  ██║     ██║   ██║██║███╗██║"
echo "██████╔╝███████╗ ╚████╔╝ ██║     ███████╗╚██████╔╝╚███╔███╔╝"
echo "╚═════╝ ╚══════╝  ╚═══╝  ╚═╝     ╚══════╝ ╚═════╝  ╚══╝╚══╝"

echo "┌──────────────────────────────────┐"
echo "│  DevFlow Project Management      │"
echo "│  AI-Powered Development System   │"
echo "└──────────────────────────────────┘"
echo ""
echo ""

echo "Initializing DevFlow PM System"
echo "======================================"
echo ""

# Check for required tools
echo "Checking dependencies..."

# Check gh CLI
if command -v gh &> /dev/null; then
  echo "  GitHub CLI (gh) installed: $(gh --version | head -1)"
else
  echo "  GitHub CLI (gh) not found"
  echo ""
  echo "  Installing gh..."
  if command -v brew &> /dev/null; then
    brew install gh
  elif command -v apt-get &> /dev/null; then
    sudo apt-get update && sudo apt-get install gh
  else
    echo "  Please install GitHub CLI manually: https://cli.github.com/"
    exit 1
  fi
fi

# Check Python
if command -v python3 &> /dev/null; then
  echo "  Python 3 installed: $(python3 --version)"
else
  echo "  Python 3 not found"
  echo "  Please install Python 3.11+: https://www.python.org/downloads/"
fi

# Check pip/uv
if command -v uv &> /dev/null; then
  echo "  uv (Python package manager) installed"
elif command -v pip3 &> /dev/null; then
  echo "  pip3 installed"
else
  echo "  No Python package manager found. Install uv: curl -LsSf https://astral.sh/uv/install.sh | sh"
fi

# Check gh auth status
echo ""
echo "Checking GitHub authentication..."
if gh auth status &> /dev/null; then
  echo "  GitHub authenticated"
else
  echo "  GitHub not authenticated"
  echo "  Running: gh auth login"
  gh auth login
fi

# Check for gh-sub-issue extension
echo ""
echo "Checking gh extensions..."
if gh extension list | grep -q "yahsan2/gh-sub-issue"; then
  echo "  gh-sub-issue extension installed"
else
  echo "  Installing gh-sub-issue extension..."
  gh extension install yahsan2/gh-sub-issue
fi

# Create directory structure
echo ""
echo "Creating directory structure..."
mkdir -p .claude/prds
mkdir -p .claude/epics
mkdir -p .claude/specs
mkdir -p .claude/context
echo "  .claude/prds/ - Product requirement documents"
echo "  .claude/epics/ - Epic and task files"
echo "  .claude/specs/ - Specifications and plans"
echo "  .claude/context/ - Project context documentation"
echo "  Directories created"

# Check for git
echo ""
echo "Checking Git configuration..."
if git rev-parse --git-dir > /dev/null 2>&1; then
  echo "  Git repository detected"

  # Check remote
  if git remote -v | grep -q origin; then
    remote_url=$(git remote get-url origin)
    echo "  Remote configured: $remote_url"

    # Check if remote is a template repository
    if [[ "$remote_url" == *"AI-LENS/Product-dev-system"* ]] || [[ "$remote_url" == *"AI-LENS/Product-dev-system.git"* ]] || [[ "$remote_url" == *"devflow-template"* ]]; then
      echo ""
      echo "  WARNING: Your remote origin points to a template repository!"
      echo "  This means any issues you create will go to the template repo, not your project."
      echo ""
      echo "  To fix this:"
      echo "  1. Create your own repository on GitHub"
      echo "  2. Update your remote:"
      echo "     git remote set-url origin https://github.com/YOUR_USERNAME/YOUR_REPO.git"
      echo ""
    else
      # Create GitHub labels if this is a GitHub repository
      if gh repo view &> /dev/null; then
        echo ""
        echo "Creating GitHub labels..."

        epic_created=false
        task_created=false
        spec_created=false

        if gh label create "epic" --color "0E8A16" --description "Epic issue containing multiple related tasks" --force 2>/dev/null; then
          epic_created=true
        elif gh label list 2>/dev/null | grep -q "^epic"; then
          epic_created=true
        fi

        if gh label create "task" --color "1D76DB" --description "Individual task within an epic" --force 2>/dev/null; then
          task_created=true
        elif gh label list 2>/dev/null | grep -q "^task"; then
          task_created=true
        fi

        if gh label create "spec" --color "D93F0B" --description "Specification document" --force 2>/dev/null; then
          spec_created=true
        elif gh label list 2>/dev/null | grep -q "^spec"; then
          spec_created=true
        fi

        # Create priority labels
        gh label create "P1" --color "B60205" --description "Must have - launch blocker" --force 2>/dev/null
        gh label create "P2" --color "FBCA04" --description "Should have - target for release" --force 2>/dev/null
        gh label create "P3" --color "0E8A16" --description "Nice to have - can defer" --force 2>/dev/null

        # Create status labels
        gh label create "in-progress" --color "5319E7" --description "Work in progress" --force 2>/dev/null
        gh label create "blocked" --color "D93F0B" --description "Blocked by dependency" --force 2>/dev/null

        if $epic_created && $task_created; then
          echo "  GitHub labels created (epic, task, spec, P1-P3, status)"
        else
          echo "  Some GitHub labels may not have been created (check repository permissions)"
        fi
      else
        echo "  Not a GitHub repository - skipping label creation"
      fi
    fi
  else
    echo "  No remote configured"
    echo "  Add with: git remote add origin <url>"
  fi
else
  echo "  Not a git repository"
  echo "  Initialize with: git init"
fi

# Create CLAUDE.md if it doesn't exist
if [ ! -f "CLAUDE.md" ]; then
  echo ""
  echo "Creating CLAUDE.md..."
  cat > CLAUDE.md << 'EOF'
# CLAUDE.md

> Think carefully and implement the most concise solution that changes as little code as possible.

## Project-Specific Instructions

Add your project-specific instructions here.

## Tech Stack

- Backend: Python 3.11+ with FastAPI
- Database: PostgreSQL with SQLAlchemy 2.0
- Frontend: [Angular/React - specify your choice]

## Testing

Always run tests before committing:
- `pytest` for backend tests
- `npm test` for frontend tests

## Code Style

Follow existing patterns in the codebase.
EOF
  echo "  CLAUDE.md created"
fi

# Summary
echo ""
echo "Initialization Complete!"
echo "=========================="
echo ""
echo "System Status:"
gh --version 2>/dev/null | head -1 || echo "  gh CLI: not installed"
python3 --version 2>/dev/null || echo "  Python: not installed"
echo "  Extensions: $(gh extension list 2>/dev/null | wc -l | tr -d ' ') installed"
echo "  Auth: $(gh auth status 2>&1 | grep -o 'Logged in to [^ ]*' || echo 'Not authenticated')"
echo ""
echo "Next Steps:"
echo "  1. Define principles: /devflow:principles"
echo "  2. Create your first PRD: /pm:prd-new <feature-name>"
echo "  3. View help: /pm:help"
echo "  4. Check status: /pm:status"
echo ""

exit 0
