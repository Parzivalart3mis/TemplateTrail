# Google Cloud Setup Guide

This guide walks you through setting up Google Cloud APIs and OAuth2 credentials for the n8n email automation system.

## Overview

To use Google Sheets and Gmail with n8n, you need to:
1. Create a Google Cloud project
2. Enable required APIs
3. Configure OAuth consent screen
4. Create OAuth2 credentials
5. Configure credentials in n8n

## Prerequisites

- Google account with access to Google Cloud Console
- Basic understanding of OAuth2 authentication
- Access to your n8n instance

## Step-by-Step Setup

### Step 1: Create Google Cloud Project

1. **Go to Google Cloud Console**
   - Navigate to [Google Cloud Console](https://console.cloud.google.com/)
   - Sign in with your Google account

2. **Create New Project**
   - Click the project dropdown at the top of the page
   - Click "New Project"
   - Enter project details:
     - **Project name**: `n8n-email-automation` (or your preferred name)
     - **Organization**: Select your organization (if applicable)
     - **Location**: Choose appropriate location
   - Click "Create"

3. **Select Your Project**
   - Once created, make sure your new project is selected in the project dropdown

### Step 2: Enable Required APIs

1. **Navigate to APIs & Services**
   - In the Google Cloud Console, go to **Navigation menu** > **APIs & Services** > **Library**

2. **Enable Google Sheets API**
   - Search for "Google Sheets API"
   - Click on "Google Sheets API"
   - Click "Enable"
   - Wait for the API to be enabled

3. **Enable Gmail API**
   - Search for "Gmail API"
   - Click on "Gmail API"
   - Click "Enable"
   - Wait for the API to be enabled

4. **Verify APIs are Enabled**
   - Go to **APIs & Services** > **Enabled APIs & Services**
   - Confirm both APIs are listed and enabled

### Step 3: Configure OAuth Consent Screen

1. **Navigate to OAuth Consent Screen**
   - Go to **APIs & Services** > **OAuth consent screen**

2. **Choose User Type**
   - Select **External** (unless you have a Google Workspace account and want internal-only access)
   - Click "Create"

3. **Fill OAuth Consent Screen Information**

   **App Information:**
   - **App name**: `N8N Email Automation`
   - **User support email**: Your email address
   - **App logo**: Upload your company logo (optional)

   **App Domain (Optional):**
   - **Application home page**: Your company website
   - **Application privacy policy link**: Your privacy policy URL
   - **Application terms of service link**: Your terms of service URL

   **Developer Contact Information:**
   - **Email addresses**: Your email address

   Click "Save and Continue"

4. **Scopes Configuration**
   - Click "Add or Remove Scopes"
   - Add the following scopes:
     - `https://www.googleapis.com/auth/spreadsheets` (Google Sheets)
     - `https://www.googleapis.com/auth/gmail.send` (Gmail send)
     - `https://www.googleapis.com/auth/gmail.readonly` (Gmail read - optional)
   - Click "Update"
   - Click "Save and Continue"

5. **Test Users (For External Apps)**
   - Add test users who can use the app during development:
     - Your email address
     - Any other team members who need access
   - Click "Save and Continue"

6. **Summary**
   - Review your settings
   - Click "Back to Dashboard"

### Step 4: Create OAuth2 Credentials

1. **Navigate to Credentials**
   - Go to **APIs & Services** > **Credentials**

2. **Create OAuth2 Client ID**
   - Click "Create Credentials"
   - Select "OAuth 2.0 Client IDs"

3. **Configure OAuth2 Client**
   - **Application type**: Web application
   - **Name**: `n8n-email-automation-client`

   **Authorized JavaScript origins** (if needed):
   - `http://localhost:5678` (for local n8n)
   - `https://your-n8n-domain.com` (for hosted n8n)

   **Authorized redirect URIs**:
   - For n8n.cloud: `https://app.n8n.cloud/rest/oauth2-credential/callback`
   - For self-hosted: `https://your-n8n-domain.com/rest/oauth2-credential/callback`
   - For local development: `http://localhost:5678/rest/oauth2-credential/callback`

4. **Create and Download Credentials**
   - Click "Create"
   - Download the JSON file containing your credentials
   - **Important**: Keep this file secure and never commit it to version control

### Step 5: Configure Credentials in N8N

#### Google Sheets OAuth2 API Credential

1. **Open N8N**
   - Navigate to your n8n instance
   - Go to **Settings** > **Credentials**

2. **Create Google Sheets Credential**
   - Click "Create New Credential"
   - Search for and select "Google Sheets OAuth2 API"

3. **Enter Credential Details**
   - **Credential Name**: `Google Sheets OAuth2`
   - **Client ID**: From your downloaded JSON file (`client_id`)
   - **Client Secret**: From your downloaded JSON file (`client_secret`)

4. **Authenticate**
   - Click "Connect my account"
   - Follow the OAuth flow
   - Grant necessary permissions
   - Complete authentication

#### Gmail OAuth2 Credential

1. **Create Gmail Credential**
   - Click "Create New Credential"
   - Search for and select "Gmail OAuth2"

2. **Enter Credential Details**
   - **Credential Name**: `Gmail OAuth2`
   - **Client ID**: Same as Google Sheets (from JSON file)
   - **Client Secret**: Same as Google Sheets (from JSON file)

3. **Authenticate**
   - Click "Connect my account"
   - Follow the OAuth flow
   - Grant Gmail permissions
   - Complete authentication

### Step 6: Test Credentials

1. **Test Google Sheets Access**
   - Create a test workflow with a Google Sheets node
   - Select your Google Sheets credential
   - Try to read from a test spreadsheet
   - Verify the connection works

2. **Test Gmail Access**
   - Create a test workflow with a Gmail node
   - Select your Gmail credential
   - Try to send a test email to yourself
   - Verify the email is sent successfully

## Security Best Practices

### Credential Security

1. **Protect Your Credentials**
   - Never share OAuth2 client secrets
   - Store credentials securely
   - Use environment variables for sensitive data
   - Enable 2FA on your Google account

2. **Access Control**
   - Use principle of least privilege
   - Regularly audit who has access
   - Remove unused credentials
   - Monitor API usage

3. **Regular Maintenance**
   - Rotate credentials periodically
   - Review and update scopes as needed
   - Monitor for security alerts
   - Keep n8n updated

### OAuth Consent Screen

1. **Verification Process**
   - For production apps, consider going through Google's verification process
   - This removes the "unverified app" warning
   - Required for apps with many users

2. **Privacy Policy**
   - Maintain an up-to-date privacy policy
   - Clearly state how you use Google data
   - Include contact information

## Troubleshooting

### Common Issues

#### "Access blocked: This app's request is invalid"

**Cause**: Redirect URI mismatch or missing scopes

**Solution**:
- Verify redirect URIs match exactly in Google Cloud Console and n8n
- Check that required scopes are added
- Ensure the OAuth consent screen is properly configured

#### "Error 403: access_denied"

**Cause**: Insufficient permissions or disabled APIs

**Solution**:
- Verify APIs are enabled in Google Cloud Console
- Check that the user has necessary permissions
- Ensure the OAuth consent screen allows the user

#### "Error 400: redirect_uri_mismatch"

**Cause**: Redirect URI doesn't match configured URIs

**Solution**:
- Check exact URL match in Google Cloud Console
- Verify protocol (http vs https)
- Ensure no trailing slashes or extra parameters

#### "This app isn't verified"

**Cause**: OAuth consent screen not verified by Google

**Solution**:
- Add yourself as a test user
- For production, consider Google verification process
- Users can proceed by clicking "Advanced" > "Go to [App Name] (unsafe)"

### API Limits and Quotas

#### Google Sheets API Limits

- **Requests per minute per project**: 300
- **Requests per minute per user**: 100
- **Requests per day**: 50,000,000

#### Gmail API Limits

- **Quota units per user per second**: 250
- **Daily quota**: 1,000,000,000 quota units
- **Messages sent per day**: 
  - Free Gmail: 500
  - Google Workspace: 2,000

### Getting Help

#### Google Cloud Support

- Check [Google Cloud Status](https://status.cloud.google.com/)
- Visit [Google Cloud Support](https://cloud.google.com/support)
- Review [API documentation](https://developers.google.com/sheets/api)

#### N8N Community

- [N8N Community Forum](https://community.n8n.io/)
- [N8N Documentation](https://docs.n8n.io/)
- [N8N GitHub Issues](https://github.com/n8n-io/n8n/issues)

## Additional Resources

### Official Documentation

- [Google Sheets API Documentation](https://developers.google.com/sheets/api)
- [Gmail API Documentation](https://developers.google.com/gmail/api)
- [Google OAuth2 Documentation](https://developers.google.com/identity/protocols/oauth2)

### N8N Integration Docs

- [N8N Google Sheets Node](https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.googlesheets/)
- [N8N Gmail Node](https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.gmail/)
- [N8N Credentials Guide](https://docs.n8n.io/credentials/)

### Best Practices

- [Google API Best Practices](https://developers.google.com/sheets/api/guides/concepts)
- [OAuth2 Security Best Practices](https://tools.ietf.org/html/rfc6749#section-10)
- [Email Marketing Compliance](https://www.ftc.gov/tips-advice/business-center/guidance/can-spam-act-compliance-guide-business)

---

**Note**: This setup process may vary slightly based on Google Cloud Console updates. Screenshots and exact button text may differ from the current interface.