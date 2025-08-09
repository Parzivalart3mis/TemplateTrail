# 🚀 N8N Email Automation - Quick Start Guide

Get your personalized email automation system up and running in under 30 minutes!

## 📋 What This Does

- **Reads contacts** from Google Sheets
- **Sends personalized emails** via Gmail
- **Tracks delivery status** automatically
- **Handles rate limiting** and batch processing
- **Provides detailed reporting** and error handling

## ⚡ Quick Setup (5 Minutes)

### 1. Prerequisites Checklist

- [ ] Google account with Gmail and Sheets access
- [ ] Docker and Docker Compose installed
- [ ] Domain name (optional, for production)

### 2. One-Line Setup

```bash
git clone <repository-url> && cd n8n-email-automation && ./scripts/setup.sh
```

**OR Manual Setup:**

```bash
# Clone and configure
git clone <repository-url>
cd n8n-email-automation
cp .env.docker .env

# Edit configuration (required)
nano .env

# Start services
docker-compose up -d
```

### 3. Access N8N

1. Open browser to `http://localhost:5678`
2. Create admin account
3. Import workflow: `workflows/email-automation-workflow.json`

## ⚙️ Essential Configuration

### Google Cloud Setup (10 Minutes)

1. **Enable APIs**: Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Enable Google Sheets API
   - Enable Gmail API

2. **Create OAuth2 Credentials**:
   - Go to APIs & Services > Credentials
   - Create OAuth 2.0 Client ID
   - Add redirect URI: `http://localhost:5678/rest/oauth2-credential/callback`

3. **Configure N8N Credentials**:
   - Google Sheets OAuth2 API
   - Gmail OAuth2
   - Use Client ID and Secret from step 2

### Google Sheets Setup (5 Minutes)

1. **Create Sheet** with these columns:
   ```
   email | first_name | last_name | company | status | sent_date | custom_field_1
   ```

2. **Add Sample Data**:
   ```
   john@example.com | John | Doe | Tech Corp | pending | | Premium
   ```

3. **Get Sheet ID** from URL:
   ```
   https://docs.google.com/spreadsheets/d/1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms/edit
                                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
                                        This is your GOOGLE_SHEET_ID
   ```

4. **Update .env file**:
   ```bash
   GOOGLE_SHEET_ID=1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms
   SENDER_EMAIL=your-email@gmail.com
   SENDER_NAME=Your Full Name
   COMPANY_NAME=Your Company
   ```

## 🎯 First Email Campaign (5 Minutes)

### 1. Test with Small Batch

- Add 2-3 test contacts to your Google Sheet
- Set `status` column to `pending`
- Use your own email addresses for testing

### 2. Run Workflow

1. In N8N, open the imported workflow
2. Click "Execute Workflow"
3. Monitor execution in real-time
4. Check your inbox for test emails
5. Verify status updates in Google Sheets

### 3. Scale Up

- Add more contacts to your sheet
- Adjust batch size in workflow settings
- Monitor delivery rates and adjust timing

## 📊 Key Features

| Feature | Description | Configuration |
|---------|-------------|---------------|
| **Personalization** | Dynamic content based on contact data | Edit Code nodes in workflow |
| **Rate Limiting** | Respects Gmail API limits | `BATCH_SIZE=10, BATCH_DELAY_MINUTES=2` |
| **Error Handling** | Automatic retries and error logging | Built into workflow |
| **Status Tracking** | Updates Google Sheets with send status | Automatic |
| **Templates** | Professional HTML email templates | `templates/` directory |

## 🛠 Environment Variables (Required)

```bash
# Essential settings
GOOGLE_SHEET_ID=your_sheet_id
SENDER_EMAIL=your@gmail.com
SENDER_NAME=Your Name
COMPANY_NAME=Your Company

# Rate limiting
BATCH_SIZE=10
BATCH_DELAY_MINUTES=2
DAILY_LIMIT=450

# Security (change in production)
POSTGRES_PASSWORD=secure_password_here
N8N_ENCRYPTION_KEY=your-32-char-key-here
```

## 🚨 Troubleshooting

### Common Issues

**Authentication Failed**
```bash
# Check OAuth2 credentials in N8N
# Verify redirect URIs match exactly
# Ensure APIs are enabled in Google Cloud
```

**Emails Not Sending**
```bash
# Check Gmail API quotas
# Verify email format in sheets
# Review n8n execution logs
docker-compose logs -f n8n
```

**Workflow Import Error**
```bash
# Update n8n to latest version
# Check JSON file format
# Manually create nodes if needed
```

**Rate Limits Hit**
```bash
# Reduce BATCH_SIZE (try 5)
# Increase BATCH_DELAY_MINUTES (try 5)
# Check Gmail sending limits
```

## 📁 Project Structure

```
n8n-email-automation/
├── workflows/               # N8N workflow files
├── templates/              # Email templates
├── config/                 # Configuration files
├── scripts/               # Setup and utility scripts
├── docs/                  # Detailed documentation
├── docker-compose.yml     # Docker deployment
└── README.md             # Complete documentation
```

## 🔗 Next Steps

### Production Deployment
- Read: `docs/deployment-guide.md`
- Set up SSL certificate
- Configure domain name
- Enable monitoring

### Advanced Features
- Custom email templates
- CRM integration
- Advanced personalization
- A/B testing

### Compliance
- Review CAN-SPAM requirements
- Set up unsubscribe handling
- Configure privacy policy
- Implement GDPR compliance

## 📚 Documentation

| Topic | File | Description |
|-------|------|-------------|
| **Complete Setup** | `README.md` | Comprehensive installation guide |
| **Google Cloud** | `docs/google-cloud-setup.md` | Detailed API configuration |
| **Production Deploy** | `docs/deployment-guide.md` | Cloud deployment guide |
| **Contact Validation** | `scripts/validate-contacts.py` | Clean your email lists |

## 🆘 Support

### Getting Help
1. Check troubleshooting section above
2. Review execution logs: `docker-compose logs -f n8n`
3. Validate your Google Sheets format
4. Test with minimal contact list first

### Community Resources
- [N8N Community Forum](https://community.n8n.io/)
- [Google Sheets API Docs](https://developers.google.com/sheets/api)
- [Gmail API Docs](https://developers.google.com/gmail/api)

## ⚠️ Important Notes

- **Start with small batches** (5-10 contacts)
- **Test thoroughly** before large campaigns
- **Follow email laws** (CAN-SPAM, GDPR)
- **Monitor deliverability** and adjust as needed
- **Keep backups** of your configuration and data

---

**🎉 You're Ready!** Your email automation system should now be running. Start with test emails and gradually scale up your campaigns.

**⏱️ Total Setup Time**: ~30 minutes  
**First Email**: ~5 minutes after setup  
**Production Ready**: ~2 hours with SSL and monitoring