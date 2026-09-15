#!/bin/bash
# admin/create-resource-groups.sh - Create resource groups for all teams

set -e

# Configuration
SUBSCRIPTION="${SUBSCRIPTION:-}"
LOCATION="${LOCATION:-swedencentral}"
RESOURCE_GROUP_PREFIX="rg-hackathon-rbs2026"

# Teams to create (adjust as needed)
TEAMS=("uc1" "uc2" "uc3" "uc4" "uc5" "uc6" "uc7" "uc8" "uc9" "uc10" "uc11")

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Verify Azure CLI
if ! command -v az &> /dev/null; then
    print_error "Azure CLI not found. Install: https://aka.ms/azure-cli"
    exit 1
fi

print_header "Azure Admin: Create Resource Groups"

# Verify authentication
if ! az account show &> /dev/null; then
    print_info "Signing in to Azure..."
    az login --use-device-code
fi

ACCOUNT=$(az account show --query user.name -o tsv)
CURRENT_SUB=$(az account show --query name -o tsv)
print_success "Authenticated as: $ACCOUNT"
echo "Current subscription: $CURRENT_SUB"

# Set subscription if specified
if [ -n "$SUBSCRIPTION" ]; then
    echo ""
    echo "Switching to subscription: $SUBSCRIPTION"
    az account set --subscription "$SUBSCRIPTION"
    CURRENT_SUB=$(az account show --query name -o tsv)
    echo "Active subscription: $CURRENT_SUB"
fi

# Confirm before creating
echo ""
echo "This will create ${#TEAMS[@]} resource groups:"
echo ""
for team in "${TEAMS[@]}"; do
    echo "  • ${RESOURCE_GROUP_PREFIX}-${team}"
done
echo ""
echo "Location: $LOCATION"
echo ""
read -p "Proceed? (y/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_error "Cancelled"
    exit 0
fi

# Create resource groups
print_header "Creating Resource Groups"

CREATED=0
FAILED=0

for team in "${TEAMS[@]}"; do
    RG_NAME="${RESOURCE_GROUP_PREFIX}-${team}"

    echo -n "Creating $RG_NAME... "

    # Check if already exists
    if az group show --name "$RG_NAME" &> /dev/null; then
        print_info "already exists"
    else
        if az group create --name "$RG_NAME" --location "$LOCATION" &> /dev/null; then
            print_success "created"
            ((CREATED++))
        else
            print_error "failed"
            ((FAILED++))
        fi
    fi
done

# Summary
print_header "Summary"

echo "Created: $CREATED"
echo "Already existed: $((${#TEAMS[@]} - CREATED - FAILED))"
echo "Failed: $FAILED"

if [ $FAILED -eq 0 ]; then
    print_success "All resource groups ready!"
    echo ""
    echo "📋 List your resource groups:"
    echo "   az group list --query \"[?contains(name, 'hackathon')].name\" -o table"
    echo ""
    echo "📤 Share these group names with your teams:"
    for team in "${TEAMS[@]}"; do
        echo "   ${RESOURCE_GROUP_PREFIX}-${team}"
    done
else
    print_error "Some resource groups failed to create"
    exit 1
fi
