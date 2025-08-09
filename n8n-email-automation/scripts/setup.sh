#!/bin/bash

# ==========================================
# N8N EMAIL AUTOMATION SETUP SCRIPT
# ==========================================
# This script helps you set up the complete email automation system
# with n8n, Google Sheets, and Gmail integration.

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$PROJECT_DIR/config"
WORKFLOWS_DIR="$PROJECT_DIR/workflows"
TEMPLATES_DIR="$PROJECT_DIR/templates"

# Functions
print_header() {
    echo -e "${BLUE}"
    echo "========================================"
    echo "  N8N EMAIL AUTOMATION SETUP"
    echo "========================================"
    echo -e "${NC}"
}

print_step() {
    echo -e "${BLUE}[STEP $1]${NC} $2"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Prompt for user input
prompt_input() {
    local prompt="$1"
    local default="$2"
    local var_name="$3"

    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " input
        input=${input:-$default}
    else
        read -p "$prompt: " input
    fi

    eval "$var_name='$input'"
}

# Validate email format
validate_email() {
    local email="$1"
    if [[ $email =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Check system requirements
check_requirements() {
    print_step "1" "Checking System Requirements"

    local requirements_met=true

    # Check for curl
    if command_exists curl; then
        print_success "curl is installed"
    else
        print_error "curl is not installed. Please install curl and try again."
        requirements_met=false
    fi

    # Check for jq
    if command_exists jq; then
        print_success "jq is installed"
    else
        print_warning "jq is not installed. Installing jq for JSON processing..."
        if command_exists apt-get; then
            sudo apt-get update && sudo apt-get install -y jq
        elif command_exists yum; then
            sudo yum install -y jq
        elif command_exists brew; then
            brew install jq
        else
            print_error "Could not install jq. Please install it manually."
            requirements_met=false
        fi
    fi

    # Check Node.js (for n8n)
    if command_exists node; then
        local node_version=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
        if [ "$node_version" -ge 16 ]; then
            print_success "Node.js $(node --version) is installed"
        else
            print_error "Node.js version 16 or higher is required. Current: $(node --version)"
            requirements_met=false
        fi
    else
        print_error "Node.js is not installed. Please install Node.js 16+ and try again."
        requirements_met=false
    fi

    # Check npm
    if command_exists npm; then
        print_success "npm $(npm --version) is installed"
    else
        print_error "npm is not installed. Please install npm and try again."
        requirements_met=false
    fi

    if [ "$requirements_met" = false ]; then
        print_error "Some requirements are not met. Please install them and run the setup again."
        exit 1
    fi

    echo
}

# Setup environment configuration
setup_environment() {
    print_step "2" "Setting Up Environment Configuration"

    local env_file="$CONFIG_DIR/.env"
    local env_example="$CONFIG_DIR/.env.example"

    if [ -f "$env_file" ]; then
        print_warning "Environment file already exists. Do you want to recreate it? (y/N)"
        read -n 1 -r response
        echo
        if [[ ! $response =~ ^[Yy]$ ]]; then
            print_info "Skipping environment setup. Using existing .env file."
            echo
            return
        fi
    fi

    print_info "Creating environment configuration..."

    # Copy example file
    cp "$env_example" "$env_file"

    # Collect user information
    echo "Please provide the following information:"
    echo

    # Google Sheets Configuration
    echo -e "${YELLOW}Google Sheets Configuration:${NC}"
    prompt_input "Google Sheet ID (from the URL)" "" GOOGLE_SHEET_ID
    prompt_input "Worksheet name" "Contacts" WORKSHEET_NAME
    echo

    # Email Configuration
    echo -e "${YELLOW}Email Configuration:${NC}"
    while true; do
        prompt_input "Your full name" "" SENDER_NAME
        if [ -n "$SENDER_NAME" ]; then
            break
        fi
        print_error "Name is required."
    done

    while true; do
        prompt_input "Your Gmail address" "" SENDER_EMAIL
        if validate_email "$SENDER_EMAIL"; then
            break
        fi
        print_error "Please enter a valid email address."
    done

    prompt_input "Your job title" "Business Development Manager" SENDER_TITLE
    prompt_input "Reply-to email" "$SENDER_EMAIL" REPLY_TO_EMAIL
    prompt_input "Admin notification email" "$SENDER_EMAIL" ADMIN_EMAIL
    echo

    # Company Information
    echo -e "${YELLOW}Company Information:${NC}"
    prompt_input "Company name" "" COMPANY_NAME
    prompt_input "Company address (for CAN-SPAM compliance)" "" COMPANY_ADDRESS
    prompt_input "Company website" "" COMPANY_WEBSITE
    echo

    # Rate Limiting
    echo -e "${YELLOW}Rate Limiting Settings:${NC}"
    prompt_input "Batch size (emails per batch)" "10" BATCH_SIZE
    prompt_input "Delay between batches (minutes)" "2" BATCH_DELAY_MINUTES
    prompt_input "Daily email limit" "450" DAILY_LIMIT
    echo

    # Compliance URLs
    echo -e "${YELLOW}Compliance URLs:${NC}"
    prompt_input "Unsubscribe URL" "$COMPANY_WEBSITE/unsubscribe" UNSUBSCRIBE_URL
    prompt_input "Privacy policy URL" "$COMPANY_WEBSITE/privacy" PRIVACY_POLICY_URL
    echo

    # Update .env file with user inputs
    sed -i.bak \
        -e "s/your_google_sheet_id_here/$GOOGLE_SHEET_ID/g" \
        -e "s/Contacts/$WORKSHEET_NAME/g" \
        -e "s/Your Full Name/$SENDER_NAME/g" \
        -e "s/your-email@gmail.com/$SENDER_EMAIL/g" \
        -e "s/Business Development Manager/$SENDER_TITLE/g" \
        -e "s/admin@yourcompany.com/$ADMIN_EMAIL/g" \
        -e "s/Your Company Name/$COMPANY_NAME/g" \
        -e "s|123 Main Street, Suite 100, City, State 12345, Country|$COMPANY_ADDRESS|g" \
        -e "s|https://www.yourcompany.com|$COMPANY_WEBSITE|g" \
        -e "s/10/$BATCH_SIZE/g" \
        -e "s/2/$BATCH_DELAY_MINUTES/g" \
        -e "s/450/$DAILY_LIMIT/g" \
        -e "s|https://yourcompany.com/unsubscribe|$UNSUBSCRIBE_URL|g" \
        -e "s|https://yourcompany.com/privacy|$PRIVACY_POLICY_URL|g" \
        "$env_file"

    # Clean up backup file
    rm -f "$env_file.bak"

    print_success "Environment configuration created at $env_file"
    echo
}

# Google Cloud setup guidance
google_cloud_setup() {
    print_step "3" "Google Cloud Setup Guidance"

    print_info "To use this system, you need to set up Google Cloud APIs:"
    echo
    echo "1. Go to Google Cloud Console (https://console.cloud.google.com/)"
    echo "2. Create a new project or select an existing one"
    echo "3. Enable the following APIs:"
    echo "   - Google Sheets API"
    echo "   - Gmail API"
    echo "4. Create OAuth 2.0 credentials:"
    echo "   - Go to APIs & Services > Credentials"
    echo "   - Click 'Create Credentials' > 'OAuth 2.0 Client IDs'"
    echo "   - Set application type to 'Web application'"
    echo "   - Add your n8n redirect URI to authorized redirect URIs"
    echo "5. Download the JSON credentials file"
    echo

    print_warning "Have you completed the Google Cloud setup? (y/N)"
    read -n 1 -r response
    echo
    if [[ ! $response =~ ^[Yy]$ ]]; then
        print_info "Please complete the Google Cloud setup and run this script again."
        echo "For detailed instructions, see: $PROJECT_DIR/docs/google-cloud-setup.md"
        exit 0
    fi

    echo
}

# N8N setup
n8n_setup() {
    print_step "4" "N8N Setup"

    # Check if n8n is installed
    if command_exists n8n; then
        print_success "n8n is already installed"
    else
        print_info "Installing n8n globally..."
        npm install -g n8n
        print_success "n8n installed successfully"
    fi

    # Check if n8n is running
    if curl -s "http://localhost:5678/healthz" > /dev/null 2>&1; then
        print_success "n8n is running at http://localhost:5678"
    else
        print_warning "n8n is not running. You can start it with: n8n start"
        print_info "The workflow will be available for import at: $WORKFLOWS_DIR/email-automation-workflow.json"
    fi

    echo
}

# Create Google Sheets template
create_sheets_template() {
    print_step "5" "Creating Google Sheets Template"

    local template_file="$TEMPLATES_DIR/contacts-template.csv"

    print_info "Creating sample contacts template..."

    cat > "$template_file" << EOF
email,first_name,last_name,company,status,sent_date,custom_field_1,custom_field_2
john.doe@example.com,John,Doe,Tech Corp,pending,,Premium,Technology
jane.smith@company.com,Jane,Smith,Design LLC,pending,,Basic,Design
mike.johnson@startup.io,Mike,Johnson,StartupIO,pending,,Enterprise,Software
sarah.wilson@enterprise.com,Sarah,Wilson,Enterprise Inc,pending,,Premium,Finance
EOF

    print_success "Sample template created at $template_file"
    print_info "Import this CSV into your Google Sheet or use it as a reference for column structure."
    echo

    print_info "Required columns for your Google Sheet:"
    echo "  - email (required): Recipient email address"
    echo "  - first_name (required): Recipient's first name"
    echo "  - last_name (optional): Recipient's last name"
    echo "  - company (optional): Recipient's company"
    echo "  - status (auto-filled): Email status (pending/sent/failed)"
    echo "  - sent_date (auto-filled): Date email was sent"
    echo "  - custom_field_1 (optional): Any custom data"
    echo "  - custom_field_2 (optional): Any custom data"
    echo
}

# Test configuration
test_configuration() {
    print_step "6" "Testing Configuration"

    local env_file="$CONFIG_DIR/.env"

    if [ ! -f "$env_file" ]; then
        print_error "Environment file not found. Please run the setup again."
        exit 1
    fi

    # Source the environment file
    set -a
    source "$env_file"
    set +a

    print_info "Testing configuration values..."

    # Check required variables
    local required_vars=("GOOGLE_SHEET_ID" "SENDER_EMAIL" "SENDER_NAME" "COMPANY_NAME")
    local config_valid=true

    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            print_error "Required variable $var is not set"
            config_valid=false
        else
            print_success "$var is configured"
        fi
    done

    # Validate email format
    if validate_email "$SENDER_EMAIL"; then
        print_success "Sender email format is valid"
    else
        print_error "Sender email format is invalid"
        config_valid=false
    fi

    # Check Google Sheet ID format
    if [[ $GOOGLE_SHEET_ID =~ ^[a-zA-Z0-9_-]{44}$ ]] || [[ $GOOGLE_SHEET_ID =~ ^[a-zA-Z0-9_-]{40,}$ ]]; then
        print_success "Google Sheet ID format appears valid"
    else
        print_warning "Google Sheet ID format may be invalid. Please verify."
    fi

    if [ "$config_valid" = false ]; then
        print_error "Configuration validation failed. Please check your .env file."
        exit 1
    fi

    print_success "Configuration validation passed"
    echo
}

# Security recommendations
security_recommendations() {
    print_step "7" "Security Recommendations"

    print_info "Important security recommendations:"
    echo
    echo "1. Never commit your .env file to version control"
    echo "2. Use strong, unique passwords for all accounts"
    echo "3. Enable 2-factor authentication on Google and n8n accounts"
    echo "4. Regularly rotate your OAuth2 credentials"
    echo "5. Monitor your email sending patterns for abuse"
    echo "6. Keep your n8n instance updated"
    echo "7. Use HTTPS for all webhook URLs"
    echo "8. Regularly backup your Google Sheets data"
    echo

    print_warning "Add .env to your .gitignore file to prevent accidental commits"
    if [ ! -f "$PROJECT_DIR/.gitignore" ]; then
        echo ".env" > "$PROJECT_DIR/.gitignore"
        print_success "Created .gitignore with .env entry"
    elif ! grep -q "^\.env$" "$PROJECT_DIR/.gitignore"; then
        echo ".env" >> "$PROJECT_DIR/.gitignore"
        print_success "Added .env to existing .gitignore"
    else
        print_success ".env is already in .gitignore"
    fi

    echo
}

# Final instructions
final_instructions() {
    print_step "8" "Final Setup Instructions"

    echo -e "${GREEN}Setup Complete!${NC}"
    echo
    print_info "Next steps:"
    echo
    echo "1. Set up your Google Sheets:"
    echo "   - Create a new Google Sheet"
    echo "   - Use the template at: $TEMPLATES_DIR/contacts-template.csv"
    echo "   - Update the GOOGLE_SHEET_ID in your .env file"
    echo
    echo "2. Configure n8n:"
    echo "   - Start n8n: n8n start"
    echo "   - Go to http://localhost:5678"
    echo "   - Set up Google Sheets and Gmail credentials"
    echo "   - Import the workflow: $WORKFLOWS_DIR/email-automation-workflow.json"
    echo
    echo "3. Test with a small batch:"
    echo "   - Add 2-3 test contacts to your sheet"
    echo "   - Run the workflow manually first"
    echo "   - Check that emails are sent and statuses are updated"
    echo
    echo "4. Scale up gradually:"
    echo "   - Start with small batches"
    echo "   - Monitor deliverability and responses"
    echo "   - Adjust batch sizes and timing as needed"
    echo
    print_info "Documentation available at: $PROJECT_DIR/README.md"
    print_info "For support, check: $PROJECT_DIR/docs/"
    echo

    print_warning "Remember to comply with email marketing laws (CAN-SPAM, GDPR, etc.)"
    echo
}

# Cleanup function
cleanup() {
    if [ $? -ne 0 ]; then
        print_error "Setup failed. Check the error messages above."
        exit 1
    fi
}

# Set trap for cleanup
trap cleanup EXIT

# Main execution
main() {
    print_header

    check_requirements
    setup_environment
    google_cloud_setup
    n8n_setup
    create_sheets_template
    test_configuration
    security_recommendations
    final_instructions

    print_success "Setup completed successfully!"
}

# Check if script is being run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
