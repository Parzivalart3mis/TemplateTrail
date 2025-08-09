#!/usr/bin/env python3

"""
Contact List Validation Script for N8N Email Automation
======================================================

This script validates email contact lists to ensure high-quality data
before running email automation campaigns.

Features:
- Email format validation
- Duplicate detection and removal
- Domain validation and verification
- Data completeness checks
- Invalid contact reporting
- Clean contact list export
- Validation statistics

Usage:
    python validate-contacts.py input.csv [--output cleaned.csv] [--report]

Requirements:
    pip install pandas validators dnspython requests
"""

import os
import sys
import csv
import re
import argparse
import json
from datetime import datetime
from typing import Dict, List, Tuple, Set
from urllib.parse import urlparse
import logging

try:
    import pandas as pd
    import validators
    import dns.resolver
    import requests
except ImportError as e:
    print(f"Missing required package: {e}")
    print("Install with: pip install pandas validators dnspython requests")
    sys.exit(1)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('validation.log'),
        logging.StreamHandler()
    ]
)

class ContactValidator:
    """Validates email contact lists for quality and deliverability."""

    def __init__(self):
        self.stats = {
            'total_contacts': 0,
            'valid_contacts': 0,
            'invalid_contacts': 0,
            'duplicates_removed': 0,
            'validation_errors': {},
            'domain_stats': {},
            'validation_time': None
        }

        self.valid_contacts = []
        self.invalid_contacts = []
        self.validation_errors = []

        # Common disposable email domains
        self.disposable_domains = {
            '10minutemail.com', 'tempmail.org', 'guerrillamail.com',
            'mailinator.com', 'yopmail.com', 'temp-mail.org',
            'throwaway.email', 'fakeinbox.com', 'maildrop.cc',
            'sharklasers.com', 'guerrillamail.info', 'grr.la'
        }

        # Common typos in popular domains
        self.domain_typos = {
            'gmai.com': 'gmail.com',
            'gmial.com': 'gmail.com',
            'gmail.co': 'gmail.com',
            'hotmial.com': 'hotmail.com',
            'hotmai.com': 'hotmail.com',
            'yahooo.com': 'yahoo.com',
            'yaho.com': 'yahoo.com',
            'outlok.com': 'outlook.com',
            'outloo.com': 'outlook.com'
        }

    def validate_email_format(self, email: str) -> Tuple[bool, str]:
        """Validate email format using regex and validators library."""
        if not email or not isinstance(email, str):
            return False, "Empty or invalid email"

        email = email.strip().lower()

        # Basic format check
        email_regex = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        if not re.match(email_regex, email):
            return False, "Invalid email format"

        # Use validators library for additional checks
        if not validators.email(email):
            return False, "Invalid email format (failed validators check)"

        # Check for common issues
        if email.count('@') != 1:
            return False, "Multiple @ symbols"

        local, domain = email.split('@')

        # Local part checks
        if len(local) > 64:
            return False, "Local part too long"

        if local.startswith('.') or local.endswith('.'):
            return False, "Local part cannot start/end with dot"

        if '..' in local:
            return False, "Consecutive dots in local part"

        # Domain checks
        if len(domain) > 253:
            return False, "Domain too long"

        if domain.startswith('-') or domain.endswith('-'):
            return False, "Domain cannot start/end with hyphen"

        return True, "Valid format"

    def check_domain_typos(self, email: str) -> str:
        """Check for common domain typos and suggest corrections."""
        if '@' not in email:
            return email

        local, domain = email.split('@')
        if domain in self.domain_typos:
            corrected_email = f"{local}@{self.domain_typos[domain]}"
            logging.warning(f"Possible typo detected: {email} -> {corrected_email}")
            return corrected_email

        return email

    def check_disposable_email(self, email: str) -> bool:
        """Check if email is from a disposable email service."""
        if '@' not in email:
            return False

        domain = email.split('@')[1].lower()
        return domain in self.disposable_domains

    def validate_mx_record(self, domain: str) -> Tuple[bool, str]:
        """Validate domain has valid MX records."""
        try:
            mx_records = dns.resolver.resolve(domain, 'MX')
            if mx_records:
                return True, f"Valid MX records: {len(mx_records)} found"
            else:
                return False, "No MX records found"
        except dns.resolver.NXDOMAIN:
            return False, "Domain does not exist"
        except dns.resolver.NoAnswer:
            return False, "No MX records for domain"
        except Exception as e:
            return False, f"DNS lookup error: {str(e)}"

    def validate_required_fields(self, contact: Dict) -> Tuple[bool, List[str]]:
        """Validate required fields are present and not empty."""
        required_fields = ['email', 'first_name']
        missing_fields = []

        for field in required_fields:
            if field not in contact or not contact[field] or str(contact[field]).strip() == '':
                missing_fields.append(field)

        return len(missing_fields) == 0, missing_fields

    def check_data_quality(self, contact: Dict) -> List[str]:
        """Check data quality issues."""
        issues = []

        # Check for placeholder/test data
        test_patterns = [
            r'test@.*',
            r'.*@test\..*',
            r'.*@example\..*',
            r'.*placeholder.*',
            r'.*sample.*',
            r'john\.?doe@.*',
            r'jane\.?doe@.*'
        ]

        email = contact.get('email', '').lower()
        for pattern in test_patterns:
            if re.match(pattern, email):
                issues.append("Appears to be test/placeholder data")
                break

        # Check name quality
        first_name = str(contact.get('first_name', '')).strip()
        if first_name:
            if len(first_name) < 2:
                issues.append("First name too short")
            if re.match(r'^[^a-zA-Z]*$', first_name):
                issues.append("First name contains no letters")

        # Check company name
        company = str(contact.get('company', '')).strip()
        if company:
            if len(company) < 2:
                issues.append("Company name too short")

        return issues

    def remove_duplicates(self, contacts: List[Dict]) -> List[Dict]:
        """Remove duplicate contacts based on email address."""
        seen_emails = set()
        unique_contacts = []
        duplicates = 0

        for contact in contacts:
            email = str(contact.get('email', '')).strip().lower()
            if email and email not in seen_emails:
                seen_emails.add(email)
                unique_contacts.append(contact)
            else:
                duplicates += 1

        self.stats['duplicates_removed'] = duplicates
        logging.info(f"Removed {duplicates} duplicate contacts")

        return unique_contacts

    def validate_contact_list(self, file_path: str, check_mx: bool = False) -> None:
        """Main validation function."""
        start_time = datetime.now()
        logging.info(f"Starting validation of {file_path}")

        try:
            # Read CSV file
            df = pd.read_csv(file_path)
            contacts = df.to_dict('records')

            self.stats['total_contacts'] = len(contacts)
            logging.info(f"Loaded {len(contacts)} contacts")

            # Remove duplicates
            contacts = self.remove_duplicates(contacts)

            # Validate each contact
            for i, contact in enumerate(contacts):
                if i % 100 == 0:
                    logging.info(f"Processed {i}/{len(contacts)} contacts")

                contact_errors = []

                # Validate required fields
                fields_valid, missing_fields = self.validate_required_fields(contact)
                if not fields_valid:
                    contact_errors.append(f"Missing required fields: {', '.join(missing_fields)}")

                if fields_valid:
                    email = str(contact['email']).strip().lower()

                    # Check for domain typos
                    corrected_email = self.check_domain_typos(email)
                    if corrected_email != email:
                        contact['email'] = corrected_email
                        contact_errors.append(f"Domain typo corrected: {email} -> {corrected_email}")
                        email = corrected_email

                    # Validate email format
                    format_valid, format_error = self.validate_email_format(email)
                    if not format_valid:
                        contact_errors.append(f"Email format: {format_error}")

                    # Check disposable email
                    if self.check_disposable_email(email):
                        contact_errors.append("Disposable email address")

                    # Validate MX records if requested
                    if check_mx and format_valid:
                        domain = email.split('@')[1]
                        mx_valid, mx_error = self.validate_mx_record(domain)
                        if not mx_valid:
                            contact_errors.append(f"Domain validation: {mx_error}")

                        # Update domain stats
                        if domain not in self.stats['domain_stats']:
                            self.stats['domain_stats'][domain] = {'count': 0, 'valid': mx_valid}
                        self.stats['domain_stats'][domain]['count'] += 1

                    # Check data quality
                    quality_issues = self.check_data_quality(contact)
                    contact_errors.extend(quality_issues)

                # Categorize contact
                if not contact_errors or all('corrected' in error for error in contact_errors):
                    self.valid_contacts.append(contact)
                    self.stats['valid_contacts'] += 1
                else:
                    contact['validation_errors'] = contact_errors
                    self.invalid_contacts.append(contact)
                    self.stats['invalid_contacts'] += 1

                    # Track error types
                    for error in contact_errors:
                        error_type = error.split(':')[0] if ':' in error else error
                        self.stats['validation_errors'][error_type] = \
                            self.stats['validation_errors'].get(error_type, 0) + 1

            self.stats['validation_time'] = (datetime.now() - start_time).total_seconds()
            logging.info("Validation completed")

        except Exception as e:
            logging.error(f"Error during validation: {str(e)}")
            raise

    def export_results(self, output_file: str = None, export_invalid: bool = True) -> None:
        """Export validation results to CSV files."""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

        if output_file:
            valid_file = output_file
        else:
            valid_file = f"valid_contacts_{timestamp}.csv"

        # Export valid contacts
        if self.valid_contacts:
            valid_df = pd.DataFrame(self.valid_contacts)
            valid_df.to_csv(valid_file, index=False)
            logging.info(f"Valid contacts exported to {valid_file}")

        # Export invalid contacts
        if export_invalid and self.invalid_contacts:
            invalid_file = f"invalid_contacts_{timestamp}.csv"
            invalid_df = pd.DataFrame(self.invalid_contacts)
            invalid_df.to_csv(invalid_file, index=False)
            logging.info(f"Invalid contacts exported to {invalid_file}")

    def generate_report(self) -> str:
        """Generate detailed validation report."""
        report = []
        report.append("="*60)
        report.append("CONTACT LIST VALIDATION REPORT")
        report.append("="*60)
        report.append(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        report.append(f"Validation time: {self.stats['validation_time']:.2f} seconds")
        report.append("")

        # Summary statistics
        report.append("SUMMARY STATISTICS")
        report.append("-" * 30)
        report.append(f"Total contacts processed: {self.stats['total_contacts']:,}")
        report.append(f"Valid contacts: {self.stats['valid_contacts']:,}")
        report.append(f"Invalid contacts: {self.stats['invalid_contacts']:,}")
        report.append(f"Duplicates removed: {self.stats['duplicates_removed']:,}")

        if self.stats['total_contacts'] > 0:
            valid_rate = (self.stats['valid_contacts'] / self.stats['total_contacts']) * 100
            report.append(f"Validation rate: {valid_rate:.1f}%")

        report.append("")

        # Error breakdown
        if self.stats['validation_errors']:
            report.append("ERROR BREAKDOWN")
            report.append("-" * 30)
            for error_type, count in sorted(self.stats['validation_errors'].items(),
                                          key=lambda x: x[1], reverse=True):
                report.append(f"{error_type}: {count:,} contacts")
            report.append("")

        # Domain statistics
        if self.stats['domain_stats']:
            report.append("TOP DOMAINS")
            report.append("-" * 30)
            sorted_domains = sorted(self.stats['domain_stats'].items(),
                                  key=lambda x: x[1]['count'], reverse=True)
            for domain, stats in sorted_domains[:10]:
                status = "✓" if stats.get('valid', True) else "✗"
                report.append(f"{status} {domain}: {stats['count']:,} contacts")
            report.append("")

        # Recommendations
        report.append("RECOMMENDATIONS")
        report.append("-" * 30)

        if self.stats['invalid_contacts'] > 0:
            report.append("• Remove invalid contacts before sending emails")

        if self.stats['duplicates_removed'] > 0:
            report.append("• Implement deduplication in your data collection process")

        invalid_rate = (self.stats['invalid_contacts'] / self.stats['total_contacts']) * 100 if self.stats['total_contacts'] > 0 else 0
        if invalid_rate > 10:
            report.append("• High invalid contact rate - review data collection quality")

        if any('Disposable email' in error for error in self.stats['validation_errors']):
            report.append("• Consider blocking disposable email services")

        if any('Domain validation' in error for error in self.stats['validation_errors']):
            report.append("• Some domains have DNS issues - double-check before removing")

        report.append("")
        report.append("="*60)

        return "\n".join(report)

    def save_report(self, filename: str = None) -> str:
        """Save validation report to file."""
        if not filename:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"validation_report_{timestamp}.txt"

        report_content = self.generate_report()

        with open(filename, 'w', encoding='utf-8') as f:
            f.write(report_content)

        logging.info(f"Report saved to {filename}")
        return filename

def main():
    parser = argparse.ArgumentParser(
        description="Validate email contact lists for quality and deliverability",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python validate-contacts.py contacts.csv
  python validate-contacts.py contacts.csv --output clean_contacts.csv
  python validate-contacts.py contacts.csv --mx-check --report
  python validate-contacts.py contacts.csv --no-invalid-export
        """
    )

    parser.add_argument('input_file', help='Input CSV file with contacts')
    parser.add_argument('--output', '-o', help='Output file for valid contacts')
    parser.add_argument('--report', '-r', action='store_true',
                       help='Generate and display detailed report')
    parser.add_argument('--mx-check', action='store_true',
                       help='Perform MX record validation (slower)')
    parser.add_argument('--no-invalid-export', action='store_true',
                       help='Don\'t export invalid contacts to separate file')
    parser.add_argument('--quiet', '-q', action='store_true',
                       help='Reduce output verbosity')

    args = parser.parse_args()

    if args.quiet:
        logging.getLogger().setLevel(logging.WARNING)

    # Check input file exists
    if not os.path.exists(args.input_file):
        print(f"Error: Input file '{args.input_file}' not found")
        sys.exit(1)

    # Initialize validator
    validator = ContactValidator()

    try:
        # Run validation
        print(f"Validating contacts from {args.input_file}...")
        validator.validate_contact_list(args.input_file, check_mx=args.mx_check)

        # Export results
        validator.export_results(args.output, not args.no_invalid_export)

        # Generate report
        if args.report:
            report_content = validator.generate_report()
            print("\n" + report_content)
            validator.save_report()

        # Summary
        print(f"\nValidation complete!")
        print(f"Valid contacts: {validator.stats['valid_contacts']:,}")
        print(f"Invalid contacts: {validator.stats['invalid_contacts']:,}")
        print(f"Duplicates removed: {validator.stats['duplicates_removed']:,}")

        if validator.stats['total_contacts'] > 0:
            valid_rate = (validator.stats['valid_contacts'] / validator.stats['total_contacts']) * 100
            print(f"Success rate: {valid_rate:.1f}%")

    except Exception as e:
        logging.error(f"Validation failed: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()
