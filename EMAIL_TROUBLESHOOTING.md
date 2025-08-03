# Email Troubleshooting Guide - Password Reset Spam Issues

This guide helps resolve issues with password reset emails going to spam folders.

## Immediate Solutions (Quick Fixes)

### 1. Check Spam/Junk Folder
- Always check your spam/junk folder first
- Mark the email as "Not Spam" to train your email provider
- Add `noreply@muktarnutrition.firebaseapp.com` to your contacts

### 2. Verify Email Address
- Double-check the email address you entered
- Ensure there are no typos or extra spaces
- Try with a different email address if available

### 3. Wait and Retry
- Email delivery can take 5-10 minutes
- Wait a few minutes before requesting another reset
- Don't spam the reset button

## Firebase Console Configuration

### 1. Customize Email Templates
1. Go to Firebase Console > Authentication > Templates
2. Click on "Password reset" template
3. Customize:
   - **Sender name**: "Champions Gym" (instead of generic Firebase)
   - **Subject**: "Reset your Champions Gym password"
   - **Message**: Add your branding and make it more professional

### 2. Configure Authorized Domains
1. Go to Firebase Console > Authentication > Settings
2. Add your app's domain to "Authorized domains"
3. This helps with email deliverability

### 3. Set Up Custom Domain (Production)
1. Purchase a domain (e.g., `championsgym.com`)
2. Configure DNS records:
   ```
   SPF: v=spf1 include:_spf.google.com ~all
   DMARC: v=DMARC1; p=quarantine; rua=mailto:dmarc@yourdomain.com
   ```
3. Add domain to Firebase authorized domains

## Email Provider Specific Solutions

### Gmail
- Check "Promotions" tab
- Add sender to contacts
- Move email from spam to inbox
- Check Gmail filters

### Outlook/Hotmail
- Check "Junk Email" folder
- Add sender to safe senders list
- Check Outlook rules and filters

### Yahoo Mail
- Check "Spam" folder
- Add sender to contacts
- Check Yahoo Mail filters

### Apple Mail
- Check "Junk" folder
- Add sender to contacts
- Check Mail rules

## Development vs Production

### Development Environment
- Emails may go to spam more frequently
- Use test email addresses
- Check spam folders regularly

### Production Environment
- Set up proper domain authentication
- Use custom email templates
- Monitor email deliverability
- Consider using a dedicated email service

## Alternative Solutions

### 1. Use a Different Email Service
Consider integrating with:
- SendGrid
- Mailgun
- Amazon SES
- Twilio SendGrid

### 2. Implement In-App Password Reset
- Send reset codes via SMS
- Use in-app verification
- Implement time-based one-time passwords (TOTP)

### 3. Use Social Authentication
- Encourage users to use Google/Apple Sign-In
- Reduces dependency on email-based password reset

## Testing Email Delivery

### 1. Test with Multiple Email Providers
- Gmail
- Outlook
- Yahoo
- Apple Mail
- Custom domains

### 2. Use Email Testing Tools
- Mail Tester
- GlockApps
- 250ok
- SendGrid Email Testing

### 3. Monitor Email Analytics
- Track delivery rates
- Monitor bounce rates
- Check spam complaints

## Best Practices

### 1. Email Content
- Use clear, professional language
- Include your brand name
- Avoid spam trigger words
- Keep it concise

### 2. Technical Setup
- Use proper email authentication
- Configure reverse DNS
- Set up feedback loops
- Monitor reputation

### 3. User Communication
- Inform users to check spam folders
- Provide clear instructions
- Offer alternative contact methods
- Set proper expectations

## Emergency Contact

If users can't access their account:
1. Provide support email: `support@championsgym.com`
2. Offer manual account recovery
3. Consider implementing backup authentication methods

## Monitoring and Maintenance

### Regular Tasks
- Monitor email deliverability
- Check spam folder placement
- Update email templates
- Review user feedback

### Monthly Reviews
- Analyze email delivery metrics
- Update DNS records if needed
- Review and update templates
- Check for new spam filter changes

## Resources

- [Firebase Email Templates Documentation](https://firebase.google.com/docs/auth/custom-email-handler)
- [Email Deliverability Best Practices](https://support.google.com/mail/answer/81126)
- [SPF Record Generator](https://www.spf-record-generator.com/)
- [DMARC Record Generator](https://dmarc.postmarkapp.com/)

## Support

For additional help:
1. Check Firebase Console logs
2. Review email delivery reports
3. Contact Firebase support
4. Consult with email deliverability experts 