#!/bin/bash
# deploy.sh - Deploy your team's resource group

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="$SCRIPT_DIR/main.bicep"

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

# Check prerequisites
print_header "Prerequisites"

if ! command -v az &> /dev/null; then
    print_error "Azure CLI not found. Install: https://aka.ms/azure-cli"
    exit 1
fi
print_success "Azure CLI found"

if [ $# -ne 1 ]; then
    print_error "Usage: ./deploy.sh <parameters-file>"
    echo ""
    echo "Examples:"
    echo "  ./deploy.sh main-panthers.bicepparam"
    echo "  ./deploy.sh main-team1.bicepparam"
    exit 1
fi

PARAMS_FILE="$1"

if [ ! -f "$PARAMS_FILE" ]; then
    print_error "Parameter file not found: $PARAMS_FILE"
    echo ""
    echo "Create one by copying the template:"
    echo "  cp main.bicepparam.template main-<teamname>.bicepparam"
    echo "  # Edit and customize main-<teamname>.bicepparam"
    exit 1
fi
print_success "Parameter file found: $PARAMS_FILE"

# Verify Azure login
print_header "Azure Authentication"

if ! az account show &> /dev/null; then
    echo "Sign in to Azure:"
    az login --use-device-code
fi

ACCOUNT=$(az account show --query user.name -o tsv)
SUB=$(az account show --query name -o tsv)
print_success "Authenticated as: $ACCOUNT"
echo "Subscription: $SUB"

# Validate template
print_header "Validating Template"

az bicep build --file "$TEMPLATE_FILE" > /dev/null
print_success "Bicep template valid"

# Get team name from parameter file
TEAM_NAME=$(grep "param teamName =" "$PARAMS_FILE" | head -1 | sed "s/.*= '\([^']*\)'.*/\1/")
LOCATION=$(grep "param location =" "$PARAMS_FILE" | head -1 | sed "s/.*= '\([^']*\)'.*/\1/" || echo "swedencentral")
DEPLOYMENT_NAME="hackathon-rbs2026-${TEAM_NAME}"

echo "Team: $TEAM_NAME"
echo "Location: $LOCATION"
echo "Deployment Name: $DEPLOYMENT_NAME"

# Preview
print_header "Deployment Preview"

az deployment sub what-if \
    --name "$DEPLOYMENT_NAME" \
    --location "$LOCATION" \
    --template-file "$TEMPLATE_FILE" \
    --parameters "$PARAMS_FILE" \
    --output table

# Confirm deployment
echo ""
read -p "Proceed with deployment? (y/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_error "Deployment cancelled"
    exit 0
fi

# Deploy
print_header "Deploying Infrastructure"

echo "This may take 5-15 minutes..."
echo ""

az deployment sub create \
    --name "$DEPLOYMENT_NAME" \
    --location "$LOCATION" \
    --template-file "$TEMPLATE_FILE" \
    --parameters "$PARAMS_FILE"

# Show outputs
print_header "Deployment Complete"

echo "Getting resource details..."
echo ""

OUTPUTS=$(az deployment sub show \
    --name "$DEPLOYMENT_NAME" \
    --query properties.outputs \
    --output json)

echo "$OUTPUTS" | jq -r 'to_entries[] | "\(.key): \(.value.value)"'

# Save to file
OUTPUT_FILE="outputs-${TEAM_NAME}.json"
echo "$OUTPUTS" > "$OUTPUT_FILE"
print_success "Outputs saved to: $OUTPUT_FILE"

echo ""
echo "📋 Next steps:"
echo "  1. Update your .env file with the endpoints above"
echo "  2. Get API keys:"
echo "     az cognitiveservices account keys list --name \"foundry-rbs2026-${TEAM_NAME}\" --resource-group \"rg-hackathon-rbs2026-${TEAM_NAME}\""
echo "  3. Check the starter code in ../starter/"
echo ""
