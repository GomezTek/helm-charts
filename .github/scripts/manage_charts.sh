#!/bin/bash

# Constants
REPO_OWNER="gomeztek"
REPO_NAME="helm-charts"
PACKAGE_NAME="charts%2Fmesa-os"
API_URL="https://api.github.com"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Headers for API calls
HEADERS=(
    "Authorization: Bearer $GITHUB_TOKEN"
    "Accept: application/vnd.github.v3+json"
)

# Check if GITHUB_TOKEN and GITHUB_USERNAME are set
if [ -z "$GITHUB_TOKEN" ] || [ -z "$GITHUB_USERNAME" ]; then
    echo -e "${RED}Error: GITHUB_TOKEN and GITHUB_USERNAME must be set${NC}"
    echo "Export them with:"
    echo "export GITHUB_TOKEN=your_token"
    echo "export GITHUB_USERNAME=your_username"
    exit 1
fi

# Function to list all package versions
list_package_versions() {
    echo -e "${GREEN}Fetching available chart package versions...${NC}"
    curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
        "$API_URL/orgs/${REPO_OWNER,,}/packages/container/$PACKAGE_NAME/versions" | \
        jq -r '.[] | select(.metadata.container.tags != null) | "\(.id) -> \(.metadata.container.tags[0]) (\(.created_at))"'
}

# Function to list all releases
list_releases() {
    echo -e "${BLUE}Fetching GitHub releases...${NC}"
    curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
        "$API_URL/repos/${REPO_OWNER}/${REPO_NAME}/releases" | \
        jq -r '.[] | "\(.id) -> \(.tag_name) (\(.created_at))"'
}

# Function to list all tags
list_tags() {
    echo -e "${CYAN}Fetching Git tags...${NC}"
    curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
        "$API_URL/repos/${REPO_OWNER}/${REPO_NAME}/git/refs/tags" | \
        jq -r '.[] | "\(.ref) -> \(.object.sha)"'
}

# Function to delete a tag
delete_tag() {
    local tag_ref=$1
    echo -e "${YELLOW}Deleting tag $tag_ref...${NC}"
    response=$(curl -s -w "%{http_code}" -o /dev/null -X DELETE \
        -H "Authorization: Bearer $GITHUB_TOKEN" \
        "$API_URL/repos/${REPO_OWNER}/${REPO_NAME}/git/${tag_ref}")
    
    if [ "$response" = "204" ]; then
        echo -e "${GREEN}Successfully deleted tag $tag_ref${NC}"
    else
        echo -e "${RED}Failed to delete tag $tag_ref (HTTP $response)${NC}"
        return 1
    fi
}

# Function to delete a specific package version
delete_package_version() {
    local version_id=$1
    echo -e "${YELLOW}Deleting package version $version_id...${NC}"
    response=$(curl -s -w "%{http_code}" -o /dev/null -X DELETE \
        -H "Authorization: Bearer $GITHUB_TOKEN" \
        "$API_URL/orgs/${REPO_OWNER,,}/packages/container/$PACKAGE_NAME/versions/$version_id")
    
    if [ "$response" = "204" ]; then
        echo -e "${GREEN}Successfully deleted package version $version_id${NC}"
    else
        echo -e "${RED}Failed to delete package version $version_id (HTTP $response)${NC}"
        return 1
    fi
}

# Function to delete a specific release
delete_release() {
    local release_id=$1
    echo -e "${YELLOW}Deleting release $release_id...${NC}"
    response=$(curl -s -w "%{http_code}" -o /dev/null -X DELETE \
        -H "Authorization: Bearer $GITHUB_TOKEN" \
        "$API_URL/repos/${REPO_OWNER}/${REPO_NAME}/releases/$release_id")
    
    if [ "$response" = "204" ]; then
        echo -e "${GREEN}Successfully deleted release $release_id${NC}"
    else
        echo -e "${RED}Failed to delete release $release_id (HTTP $response)${NC}"
        return 1
    fi
}

# Function to show help
show_help() {
    echo "Usage: $0 [COMMAND]"
    echo
    echo "Commands:"
    echo "  list-packages    List all chart package versions"
    echo "  list-releases    List all GitHub releases"
    echo "  list-tags       List all Git tags"
    echo "  list-all        List all packages, releases, and tags"
    echo "  delete-pkg      Delete specific package version"
    echo "  delete-release  Delete specific release"
    echo "  delete-tag      Delete specific tag (provide full ref, e.g., 'refs/tags/v1.0.0')"
    echo "  clean           Attempt to delete all versions, releases, and tags"
    echo "  help            Show this help message"
    echo
    echo "Examples:"
    echo "  $0 list-packages"
    echo "  $0 list-releases"
    echo "  $0 delete-pkg 423368606"
    echo "  $0 delete-release 12345678"
    echo "  $0 clean"
}

# Main script
case "$1" in
    "list-packages")
        list_package_versions
        ;;
    "list-releases")
        list_releases
        ;;
    "list-tags")
        list_tags
        ;;
    "list-all")
        echo -e "${BLUE}=== Package Versions ===${NC}"
        list_package_versions
        echo
        echo -e "${BLUE}=== GitHub Releases ===${NC}"
        list_releases
        echo
        echo -e "${CYAN}=== Git Tags ===${NC}"
        list_tags
        ;;
    "delete-pkg")
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Package Version ID required${NC}"
            echo "Usage: $0 delete-pkg VERSION_ID"
            exit 1
        fi
        delete_package_version "$2"
        ;;
    "delete-release")
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Release ID required${NC}"
            echo "Usage: $0 delete-release RELEASE_ID"
            exit 1
        fi
        delete_release "$2"
        ;;
    "delete-tag")
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Tag ref required${NC}"
            echo "Usage: $0 delete-tag refs/tags/TAG_NAME"
            exit 1
        fi
        delete_tag "$2"
        ;;
    "clean")
        echo -e "${YELLOW}Warning: This will attempt to delete all package versions, releases, and tags${NC}"
        read -p "Are you sure you want to continue? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Cleaning package versions...${NC}"
            versions=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
                "$API_URL/orgs/${REPO_OWNER,,}/packages/container/$PACKAGE_NAME/versions" | \
                jq -r '.[].id')
            for version in $versions; do
                delete_package_version "$version"
            done

            echo -e "\n${BLUE}Cleaning releases...${NC}"
            releases=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
                "$API_URL/repos/${REPO_OWNER}/${REPO_NAME}/releases" | \
                jq -r '.[].id')
            for release in $releases; do
                delete_release "$release"
            done

            echo -e "\n${CYAN}Cleaning tags...${NC}"
            tags=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
                "$API_URL/repos/${REPO_OWNER}/${REPO_NAME}/git/refs/tags" | \
                jq -r '.[].ref')
            for tag in $tags; do
                delete_tag "$tag"
            done
        fi
        ;;
    "help"|*)
        show_help
        ;;
esac
