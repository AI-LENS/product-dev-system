#!/bin/bash
# DevFlow Common Utilities
# Source this file in other scripts: source devflow/scripts/common/common.sh

# Load DevFlow config
DEVFLOW_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${DEVFLOW_ROOT}/devflow.config" 2>/dev/null || true

# ─── DateTime ─────────────────────────────────────────────────────────────────

get_datetime() {
    date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || \
    python3 -c "from datetime import datetime,timezone; print(datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'))" 2>/dev/null || \
    python -c "from datetime import datetime,timezone; print(datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'))" 2>/dev/null
}

# ─── Path Utilities ───────────────────────────────────────────────────────────

normalize_paths() {
    local content="$1"
    content=$(echo "$content" | sed "s|/Users/[^/]*/[^/]*/|../|g")
    content=$(echo "$content" | sed "s|/home/[^/]*/[^/]*/|../|g")
    content=$(echo "$content" | sed "s|C:\\\\Users\\\\[^\\\\]*\\\\[^\\\\]*\\\\|..\\\\|g")
    echo "$content"
}

# ─── Output Formatting ───────────────────────────────────────────────────────

print_success() {
    echo "✅ $1"
}

print_error() {
    echo "❌ $1" >&2
}

print_warning() {
    echo "⚠️ $1"
}

# ─── Frontmatter ─────────────────────────────────────────────────────────────

strip_frontmatter() {
    local file="$1"
    sed '1,/^---$/d; 1,/^---$/d' "$file"
}

get_frontmatter_field() {
    local file="$1"
    local field="$2"
    grep "^${field}:" "$file" | sed "s/^${field}: *//"
}

# ─── GitHub ───────────────────────────────────────────────────────────────────

check_template_repo() {
    local remote_url=$(git remote get-url origin 2>/dev/null || echo "")
    if [[ "$remote_url" == *"AI-LENS/Product-dev-system"* ]] || [[ "$remote_url" == *"AI-LENS/Product-dev-system.git"* ]]; then
        print_error "You're trying to sync with the DevFlow template repository!"
        echo ""
        echo "This repository is a template for others to use."
        echo "You should NOT create issues or PRs here."
        echo ""
        echo "To fix this:"
        echo "1. Create a new repository on GitHub"
        echo "2. Update your remote origin:"
        echo "   git remote set-url origin https://github.com/YOUR_USERNAME/YOUR_REPO.git"
        echo ""
        echo "Current remote: $remote_url"
        return 1
    fi
    return 0
}

get_repo_slug() {
    local remote_url=$(git remote get-url origin 2>/dev/null || echo "")
    echo "$remote_url" | sed 's|.*github.com[:/]||' | sed 's|\.git$||'
}

# ─── File Counting ───────────────────────────────────────────────────────────

count_files() {
    local dir="$1"
    local pattern="${2:-*.md}"
    find "$dir" -name "$pattern" -type f 2>/dev/null | wc -l | tr -d ' '
}

# ─── Validation ───────────────────────────────────────────────────────────────

require_file() {
    local file="$1"
    local hint="$2"
    if [ ! -f "$file" ]; then
        print_error "Required file not found: $file"
        [ -n "$hint" ] && echo "  $hint"
        return 1
    fi
    return 0
}

require_dir() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir" 2>/dev/null
        if [ ! -d "$dir" ]; then
            print_error "Cannot create directory: $dir"
            return 1
        fi
    fi
    return 0
}
