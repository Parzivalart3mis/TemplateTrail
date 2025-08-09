# N8N Email Automation with Google Sheets & Gmail

A comprehensive email automation system that reads contact data from Google Sheets and sends personalized emails through Gmail using n8n workflows.

## 🚀 Features

- **Personalized Email Campaigns**: Dynamic content based on contact data
- **Google Sheets Integration**: Easy contact management and data updates
- **Gmail API Integration**: Reliable email delivery through your Gmail account
- **Rate Limiting**: Built-in protections against API limits
- **Error Handling**: Comprehensive error tracking and retry mechanisms
- **Template System**: Reusable email templates with variables
- **Batch Processing**: Efficient handling of large contact lists
- **Compliance Ready**: Built-in unsubscribe and CAN-SPAM compliance features

## 📋 Prerequisites

Before starting, ensure you have:

- **n8n instance** (self-hosted or n8n.cloud)
- **Google Account** with access to:
  - Google Sheets
  - Gmail
  - Google Cloud Console (for API credentials)
- **Basic knowledge** of n8n workflows
- **Email compliance** understanding (CAN-SPAM, GDPR if applicable)

## 🛠 Installation & Setup

### 1. Clone This Repository

```bash
git clone https://github.com/Parzivalart3mis/TemplateTrail.git
cd n8n-email-automation
```

### 2. Google Cloud Setup

#### Enable Required APIs
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable the following APIs:
   - Google Sheets API
   - Gmail API
   - Google Drive API (optional, for file attachments)

#### Create OAuth2 Credentials
1. Navigate to **APIs & Services > Credentials**
2. Click **Create Credentials > OAuth 2.0 Client IDs**
3. Set application type to **Web application**
4. Add your n8n instance URL to authorized redirect URIs:
   - For n8n.cloud: `https://app.n8n.cloud/rest/oauth2-credential/callback`
   - For self-hosted: `https://your-n8n-domain.com/rest/oauth2-credential/callback`
5. Download the JSON credentials file

### 3. N8N Configuration

#### Install Required Nodes
Ensure your n8n instance has these nodes available:
- Google Sheets
- Gmail
- HTTP Request
- Code
- Split In Batches
- Set

#### Import Workflow
1. Copy the workflow JSON from `workflows/email-automation-workflow.json`
2. In n8n, go to **Workflows > Import from File/URL**
3. Paste the workflow JSON
4. Save the workflow

### 4. Google Sheets Setup

#### Create Your Contact Sheet
1. Create a new Google Sheet using the template in `templates/contacts-template.xlsx`
2. Or manually create with these columns:
   - `email` (required)
   - `first_name` (required)
   - `last_name` (optional)
   - `company` (optional)
   - `status` (for tracking: pending/sent/failed)
   - `sent_date` (auto-filled)
   - `custom_field_1` (optional)
   - `custom_field_2` (optional)

#### Sample Data Format
```
email                    | first_name | last_name | company        | status  | sent_date | custom_field_1
john.doe@example.com     | John       | Doe       | Tech Corp      | pending |           | Premium
jane.smith@company.com   | Jane       | Smith     | Design LLC     | pending |           | Basic
```

### 5. Credential Setup in N8N

#### Google Sheets Credentials
1. In n8n, go to **Settings > Credentials**
2. Create new **Google Sheets OAuth2 API** credential
3. Use the OAuth2 credentials from Google Cloud Console
4. Test the connection

#### Gmail Credentials
1. Create new **Gmail OAuth2** credential
2. Use the same OAuth2 credentials from Google Cloud Console
3. Grant necessary permissions (send, read)
4. Test the connection

## 🔧 Configuration

### Environment Variables

Create a `.env` file with your configuration:

```
# Google Sheets Configuration
GOOGLE_SHEET_ID=your_google_sheet_id_here
WORKSHEET_NAME=Contacts

# Email Settings
SENDER_NAME=Your Name
SENDER_EMAIL=your-email@gmail.com
REPLY_TO_EMAIL=your-reply-to@gmail.com

# Rate Limiting
BATCH_SIZE=10
BATCH_DELAY_MINUTES=1
DAILY_LIMIT=450

# Compliance
COMPANY_NAME=Your Company Name
COMPANY_ADDRESS=Your Physical Address
UNSUBSCRIBE_URL=https://your-domain.com/unsubscribe
```

### Workflow Configuration

1. Open the imported workflow in n8n
2. Update the Google Sheets node with your sheet ID
3. Configure Gmail node with your sender information
4. Adjust batch sizes based on your Gmail limits
5. Customize email templates in the template nodes

## 📧 Email Templates

### Basic Template Structure

The system uses dynamic templates with these variables:

- `{{ $json.first_name }}` - Recipient's first name
- `{{ $json.last_name }}` - Recipient's last name
- `{{ $json.company }}` - Recipient's company
- `{{ $json.custom_field_1 }}` - Custom field data
- `{{ $env.SENDER_NAME }}` - Your name
- `{{ $env.COMPANY_NAME }}` - Your company
- `{{ $env.UNSUBSCRIBE_URL }}` - Unsubscribe link

### Sample Email Template

```html
<p>Hi {{ $json.first_name }},</p>

<p>I hope this email finds you well at {{ $json.company }}.</p>

<p>I wanted to reach out personally because...</p>

<p>Best regards,<br>
{{ $env.SENDER_NAME }}</p>

<hr>
<small>
This email was sent by {{ $env.COMPANY_NAME }}<br>
{{ $env.COMPANY_ADDRESS }}<br>
<a href="{{ $env.UNSUBSCRIBE_URL }}?email={{ $json.email }}">Unsubscribe</a>
</small>
```

## 🚦 Usage

### Running the Workflow

#### Manual Execution
1. Open your workflow in n8n
2. Click **Execute Workflow**
3. Monitor progress in the execution log

#### Scheduled Execution
1. Add a **Cron** node to trigger the workflow
2. Set desired schedule (daily, weekly, etc.)
3. Activate the workflow

#### API Triggered
1. Add a **Webhook** node as trigger
2. Configure the webhook URL
3. Call the webhook to start the campaign

### Monitoring & Tracking

The workflow automatically:
- Updates the `status` column in Google Sheets
- Records `sent_date` for successful sends
- Logs errors for failed attempts
- Respects daily sending limits

### Best Practices

1. **Start Small**: Test with 5-10 contacts first
2. **Monitor Deliverability**: Check spam folder rates
3. **Respect Limits**: Don't exceed Gmail API limits
4. **Maintain Lists**: Keep contact data clean and updated
5. **Follow Laws**: Ensure CAN-SPAM and GDPR compliance

## 🔍 Troubleshooting

### Common Issues

#### "Authentication Failed"
- Verify OAuth2 credentials are correct
- Check if APIs are enabled in Google Cloud Console
- Ensure redirect URLs match exactly

#### "Rate Limit Exceeded"
- Reduce batch size in workflow
- Increase delay between batches
- Check daily sending limits

#### "Invalid Email Format"
- Validate email addresses in Google Sheets
- Remove empty rows
- Check for special characters

#### "Workflow Execution Failed"
- Check n8n execution logs
- Verify Google Sheets permissions
- Ensure all required columns exist

### Debug Mode

Enable detailed logging by:
1. Setting workflow to "Manual" trigger
2. Running with "Debug" mode enabled
3. Checking each node's output data

## 📊 Analytics & Reporting

The system tracks:
- Total emails sent
- Success/failure rates
- Bounce notifications
- Unsubscribe requests

Access reports through:
- Google Sheets status columns
- N8N execution history
- Gmail sent folder
- Custom dashboard (optional)

## 🔒 Security & Compliance

### Data Protection
- OAuth2 secure authentication
- No hardcoded credentials
- Encrypted data transmission
- GDPR-compliant data handling

### Email Compliance
- CAN-SPAM Act compliance
- Unsubscribe mechanisms
- Physical address inclusion
- Opt-in confirmation tracking

## 🤝 Support

For issues and questions:
1. Check the troubleshooting section
2. Review n8n documentation
3. Check Google API documentation
4. Create an issue in this repository

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- n8n community for workflow inspiration
- Google for robust APIs
- Contributors and testers

---

**⚠️ Important**: Always test thoroughly with small batches before running large campaigns. Ensure compliance with email marketing laws in your jurisdiction.
