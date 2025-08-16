/// EmailJS configuration constants
/// 
/// To use EmailJS:
/// 1. Sign up at https://www.emailjs.com/
/// 2. Create an email service (Gmail, Outlook, etc.)
/// 3. Create an email template
/// 4. Replace the placeholder values below with your actual credentials
class EmailJSConfig {
  /// EmailJS service ID - replace with your actual service ID
  static const String serviceId = 'service_72xm5bg';
  
  /// EmailJS template ID - replace with your actual template ID
  static const String templateId = 'template_64tda0m';
  
  /// EmailJS public key (user_id) - replace with your actual public key
  static const String publicKey = 'GvAX8Q-Ve33EbezK9';
  
  /// EmailJS private key (accessToken) - replace with your actual private key
  static const String privateKey = 'ZzeHSPchMhD8BqZedFLo3';
  
  /// EmailJS API endpoint
  static const String apiUrl = 'https://api.emailjs.com/api/v1.0/email/send';
  
  /// Whether EmailJS is enabled
  /// Set to false to disable email notifications during development
  static const bool enabled = true;
  
  /// Rate limiting - EmailJS allows 1 request per second
  static const Duration rateLimit = Duration(seconds: 1);
} 