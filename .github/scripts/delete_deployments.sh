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

# Function to delete a specific deployment
# $1 = deployment_id
# $2 = repo_owner
# $3 = repo_name
# Requires: GITHUB_TOKEN

delete_deployment() {
    local deployment_id="$1"
    local repo_owner="$2"
    local repo_name="$3"
    echo "Deleting deployment $deployment_id..."
    curl -s -L -X DELETE \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer $GITHUB_TOKEN" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "https://api.github.com/repos/${repo_owner}/${repo_name}/deployments/${deployment_id}"
}

# Get repo owner and name
REPO_OWNER="$REGISTRY_OWNER"
REPO_NAME=$(basename -s .git "$(git config --get remote.origin.url)")

# Fetch all deployments
DEPLOYMENTS=$(curl -s -L -f \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/deployments")

DEPLOYMENT_COUNT=$(echo "$DEPLOYMENTS" | jq 'length')
if [ "$DEPLOYMENT_COUNT" -eq 0 ]; then
    echo "No deployments found."
    exit 0
fi

# Show deployments that will be deleted
echo "The following deployments will be deleted:"
echo "$DEPLOYMENTS" | jq -r '.[] | "ID: \(.id), Ref: \(.ref), Environment: \(.environment)"'

echo "Found $DEPLOYMENT_COUNT deployment(s)"

# Confirm deletion unless force flag is set
if [ $FORCE -eq 0 ]; then
    read -p "Are you sure you want to delete all deployments? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Operation cancelled."
        exit 1
    fi
fi

# Delete each deployment

echo "$DEPLOYMENTS" | jq -r '.[].id' | while read -r deployment_id; do
    if [ ! -z "$deployment_id" ]; then
        delete_deployment "$deployment_id" "$REPO_OWNER" "$REPO_NAME"
    fi
done

echo "All deployments have been deleted successfully."
