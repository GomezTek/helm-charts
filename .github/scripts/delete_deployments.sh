#!/bin/bash

# Script to delete all deployments of the Mesa Helm chart

# Set script to exit on error
set -e

# Default values
CHART_NAME="mesa"
REGISTRY_OWNER=$(echo "${GITHUB_REPOSITORY_OWNER:-$(git config --get remote.origin.url | sed 's/.*[\/:]\([^/]*\)\/[^/]*$/\1/')}" | tr '[:upper:]' '[:lower:]')

# Help message
show_help() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Delete all deployments of the Mesa Helm chart from GHCR"
    echo ""
    echo "Options:"
    echo "  -h, --help         Show this help message"
    echo "  -o, --owner        Registry owner (default: derived from git config)"
    echo "  -n, --name         Chart name (default: mesa)"
    echo "  -f, --force        Skip confirmation prompt"
    echo ""
    echo "Environment variables used:"
    echo "  GITHUB_TOKEN       GitHub personal access token with delete:packages scope"
    echo "  GITHUB_REPOSITORY_OWNER  GitHub repository owner (optional)"
}

# Parse command line arguments
FORCE=0
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -o|--owner)
            REGISTRY_OWNER="$2"
            shift 2
            ;;
        -n|--name)
            CHART_NAME="$2"
            shift 2
            ;;
        -f|--force)
            FORCE=1
            shift
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Check if GITHUB_TOKEN is set
if [ -z "$GITHUB_TOKEN" ]; then
    echo "Error: GITHUB_TOKEN environment variable must be set"
    echo "Please set it with: export GITHUB_TOKEN=your_token"
    exit 1
fi

# Function to delete a specific package version
delete_package_version() {
    local version_id="$1"
    echo "Deleting package version $version_id..."
    curl -L -X DELETE \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer $GITHUB_TOKEN" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "https://api.github.com/user/packages/container/charts%2F${CHART_NAME}/versions/${version_id}"
}

# Get all package versions
echo "Fetching package versions for ${CHART_NAME} from ghcr.io/${REGISTRY_OWNER}/charts..."
VERSIONS=$(curl -s -L -f \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/orgs/${REGISTRY_OWNER}/packages/container/charts%2F${CHART_NAME}/versions" 2>/dev/null || \
    curl -s -L -f \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/user/packages/container/charts%2F${CHART_NAME}/versions")

# Check if there are any versions
if [ "$(echo "$VERSIONS" | jq '. | length')" -eq 0 ]; then
    echo "No package versions found."
    exit 0
fi

# Check if we got an error response
if echo "$VERSIONS" | jq -e 'has("message")' > /dev/null; then
    ERROR_MSG=$(echo "$VERSIONS" | jq -r '.message')
    echo "Error from GitHub API: $ERROR_MSG"
    exit 1
fi

# Show versions that will be deleted
echo "The following versions will be deleted:"
echo "$VERSIONS" | jq -r '.[] | select(.metadata != null) | .metadata.container.tags[] // .name // "unknown"'

# Get count of versions
VERSION_COUNT=$(echo "$VERSIONS" | jq '. | length')
echo "Found $VERSION_COUNT version(s)"

# Confirm deletion unless force flag is set
if [ $FORCE -eq 0 ]; then
    read -p "Are you sure you want to delete all versions? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Operation cancelled."
        exit 1
    fi
fi

# Delete each version
echo "$VERSIONS" | jq -r '.[] | .id' | while read -r version_id; do
    if [ ! -z "$version_id" ]; then
        delete_package_version "$version_id"
    fi
done

echo "All versions have been deleted successfully."
