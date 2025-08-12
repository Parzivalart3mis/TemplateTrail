#!/bin/bash

# N8N Email Automation Configuration Script
# This script helps configure your workflow environment variables and Google Sheets setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}"
    echo "========================================"
    echo "  N8N EMAIL AUTOMATION CONFIGURATION"
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

# Function to prompt for user input with validation
prompt_input() {
    local prompt="$1"
    local var_name="$2"
    local validation_func="$3"
    local value=""

    while true; do
        read -p "$prompt: " value
        if [ -n "$value" ]; then
            if [ -n "$validation_func" ] && ! $validation_func "$value"; then
                print_error "Invalid input. Please try again."
                continue
            fi
            eval "$var_name='$value'"
            break
        else
            print_error "This field is required. Please enter a value."
        fi
    done
}

# Email validation function
validate_email() {
    local email="$1"
    if [[ $email =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 0
    else
        print_error "Please enter a valid email address"
        return 1
    fi
}

# Google Sheet ID validation
validate_sheet_id() {
    local sheet_id="$1"
    if [[ $sheet_id =~ ^[a-zA-Z0-9_-]{40,}$ ]]; then
        return 0
    else
        print_error "Google Sheet ID should be 40+ characters from the URL"
        return 1
    fi
}

# Main configuration function
configure_environment() {
    print_step "1" "Configuring Environment Variables"

    echo "I'll help you configure the required settings for your email automation."
    echo "Please provide the following information:"
    echo ""

    # Gmail Configuration
    echo -e "${YELLOW}Email Settings:${NC}"
    prompt_input "Your Gmail address (e.g., john@gmail.com)" SENDER_EMAIL validate_email
    prompt_input "Your full name (e.g., John Doe)" SENDER_NAME
    prompt_input "Your company/organization name" COMPANY_NAME

    echo ""

    # Google Sheets Configuration
    echo -e "${YELLOW}Google Sheets Configuration:${NC}"
    print_info "To get your Google Sheet ID:"
    print_info "1. Open your Google Sheet"
    print_info "2. Copy the ID from URL: https://docs.google.com/spreadsheets/d/[SHEET_ID]/edit"
    print_info "3. The SHEET_ID is the long string between /d/ and /edit"
    echo ""

    prompt_input "Google Sheet ID (from the URL)" GOOGLE_SHEET_ID validate_sheet_id

    # Optional settings with defaults
    WORKSHEET_NAME="Contacts"
    read -p "Worksheet/tab name (default: Contacts): " worksheet_input
    if [ -n "$worksheet_input" ]; then
        WORKSHEET_NAME="$worksheet_input"
    fi

    BATCH_SIZE="10"
    read -p "Email batch size (default: 10): " batch_input
    if [ -n "$batch_input" ] && [[ $batch_input =~ ^[0-9]+$ ]]; then
        BATCH_SIZE="$batch_input"
    fi

    BATCH_DELAY="2"
    read -p "Delay between batches in minutes (default: 2): " delay_input
    if [ -n "$delay_input" ] && [[ $delay_input =~ ^[0-9]+$ ]]; then
        BATCH_DELAY="$delay_input"
    fi

    echo ""
    print_success "Configuration collected successfully!"
}

# Update environment file
update_env_file() {
    print_step "2" "Updating Environment File"

    local env_file=".env"

    # Create backup
    if [ -f "$env_file" ]; then
        cp "$env_file" "$env_file.backup.$(date +%Y%m%d_%H%M%S)"
        print_info "Created backup of existing .env file"
    fi

    # Update or add environment variables
    update_env_var() {
        local key="$1"
        local value="$2"
        local file="$3"

        if grep -q "^$key=" "$file" 2>/dev/null; then
            # Update existing
            sed -i "s|^$key=.*|$key=$value|" "$file"
        else
            # Add new
            echo "$key=$value" >> "$file"
        fi
    }

    # Update configuration
    update_env_var "SENDER_EMAIL" "$SENDER_EMAIL" "$env_file"
    update_env_var "SENDER_NAME" "$SENDER_NAME" "$env_file"
    update_env_var "COMPANY_NAME" "$COMPANY_NAME" "$env_file"
    update_env_var "GOOGLE_SHEET_ID" "$GOOGLE_SHEET_ID" "$env_file"
    update_env_var "WORKSHEET_NAME" "$WORKSHEET_NAME" "$env_file"
    update_env_var "BATCH_SIZE" "$BATCH_SIZE" "$env_file"
    update_env_var "BATCH_DELAY_MINUTES" "$BATCH_DELAY" "$env_file"
    update_env_var "REPLY_TO_EMAIL" "$SENDER_EMAIL" "$env_file"
    update_env_var "ADMIN_EMAIL" "$SENDER_EMAIL" "$env_file"

    print_success "Environment file updated"
}

# Create Google Sheets template
create_sheets_guide() {
    print_step "3" "Google Sheets Setup Guide"

    echo "Create a Google Sheet with the following columns (in this exact order):"
    echo ""
    echo -e "${YELLOW}Required Columns:${NC}"
    echo "1. email          - Recipient email address"
    echo "2. first_name     - Recipient's first name"
    echo "3. last_name      - Recipient's last name (optional)"
    echo "4. company        - Recipient's company (optional)"
    echo "5. status         - Email status (leave empty, will be auto-filled)"
    echo "6. sent_date      - Send date (leave empty, will be auto-filled)"
    echo "7. custom_field_1 - Any custom data (optional)"
    echo "8. custom_field_2 - Any custom data (optional)"
    echo ""

    echo -e "${YELLOW}Sample Data:${NC}"
    echo "email                    | first_name | last_name | company     | status | sent_date | custom_field_1"
    echo "john.doe@example.com     | John       | Doe       | Tech Corp   |        |           | Premium"
    echo "jane.smith@company.com   | Jane       | Smith     | Design LLC  |        |           | Basic"
    echo ""

    # Create CSV template
    cat > "contacts-template.csv" << EOF
email,first_name,last_name,company,status,sent_date,custom_field_1,custom_field_2
john.doe@example.com,John,Doe,Tech Corp,,,Premium,Technology
jane.smith@company.com,Jane,Smith,Design LLC,,,Basic,Design
test@yourcompany.com,Test,User,Your Company,,,Standard,Testing
EOF

    print_success "Created contacts-template.csv as a reference"

    print_info "Import this CSV into your Google Sheet or use it as a column reference."
}

# Restart n8n to pick up environment changes
restart_n8n() {
    print_step "4" "Restarting N8N to Apply Changes"

    if command -v docker-compose &> /dev/null; then
        print_info "Restarting N8N container..."
        if docker-compose restart n8n &>/dev/null; then
            print_success "N8N restarted successfully"
            print_info "New environment variables are now available"
        else
            print_warning "Could not restart N8N automatically. Please restart manually:"
            echo "  sudo docker-compose restart n8n"
        fi
    else
        print_warning "Docker Compose not found. Please restart N8N manually to apply changes."
    fi
}

# Next steps guide
show_next_steps() {
    print_step "5" "Next Steps"

    echo -e "${GREEN}Configuration Complete!${NC}"
    echo ""
    echo "Now complete these steps in N8N:"
    echo ""
    echo "1. ${YELLOW}Setup Google Credentials:${NC}"
    echo "   • Go to http://localhost:5678"
    echo "   • Settings → Credentials → Create New Credential"
    echo "   • Add 'Google Sheets OAuth2 API' credential"
    echo "   • Add 'Gmail OAuth2' credential"
    echo "   • Use the same Client ID and Secret for both"
    echo ""
    echo "2. ${YELLOW}Import Workflow:${NC}"
    echo "   • Go to Workflows → Import from File"
    echo "   • Select: workflows/email-automation-workflow.json"
    echo "   • Or copy the JSON content and paste it"
    echo ""
    echo "3. ${YELLOW}Configure Workflow:${NC}"
    echo "   • Open the imported workflow"
    echo "   • Click on 'Read Contacts from Sheet' node"
    echo "   • Select your Google Sheets credential"
    echo "   • Click on 'Send Personalized Email' node"
    echo "   • Select your Gmail credential"
    echo ""
    echo "4. ${YELLOW}Test Your Setup:${NC}"
    echo "   • Add 2-3 test contacts to your Google Sheet"
    echo "   • Use your own email addresses for testing"
    echo "   • Execute the workflow manually in N8N"
    echo "   • Check that emails are sent and status is updated"
    echo ""
    echo "5. ${YELLOW}Scale Up Gradually:${NC}"
    echo "   • Start with small batches (5-10 contacts)"
    echo "   • Monitor email delivery rates"
    echo "   • Adjust timing and batch sizes as needed"
    echo ""

    echo -e "${YELLOW}Important URLs:${NC}"
    echo "• N8N Dashboard: http://localhost:5678"
    echo "• Google Cloud Console: https://console.cloud.google.com/"
    echo "• Your Google Sheet: https://docs.google.com/spreadsheets/d/$GOOGLE_SHEET_ID/edit"
    echo ""

    print_warning "Remember to comply with email marketing laws (CAN-SPAM, GDPR, etc.)"
}

# Main execution
main() {
    print_header

    # Check if we're in the right directory
    if [ ! -f "docker-compose.yml" ] || [ ! -d "workflows" ]; then
        print_error "Please run this script from the n8n-email-automation directory"
        exit 1
    fi

    configure_environment
    update_env_file
    create_sheets_guide
    restart_n8n
    show_next_steps

    echo ""
    print_success "Configuration completed successfully! 🎉"
    echo ""
    print_info "Next: Open http://localhost:5678 to continue setup in N8N"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
