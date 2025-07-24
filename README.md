# MOCTAR Nutrition

AI-Powered Fitness & Meal Prep App

## Getting Started

This project is a Flutter application that provides personalized meal planning and fitness tracking.

## Environment Setup

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Configure Environment Variables

1. Copy the example environment file:
```bash
cp .env.example .env
```

2. Edit `.env` and add your configuration:
```env
# OpenAI Configuration
OPENAI_API_KEY=your_openai_api_key_here
OPENAI_BASE_URL=https://api.openai.com/v1/chat/completions
OPENAI_MODEL=gpt-4o
OPENAI_TEMPERATURE=0.7
OPENAI_MAX_TOKENS=4000

# Environment Configuration
ENVIRONMENT=development
APP_VERSION=1.0.0
BUILD_NUMBER=1
```

### 3. Get OpenAI API Key

1. Visit [OpenAI Platform](https://platform.openai.com/)
2. Create an account or sign in
3. Navigate to API Keys section
4. Create a new API key
5. Copy the key and paste it in your `.env` file

### 4. Run the App
```bash
flutter run
```

## Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `OPENAI_API_KEY` | Your OpenAI API key | - | ✅ |
| `OPENAI_BASE_URL` | OpenAI API endpoint | `https://api.openai.com/v1/chat/completions` | ❌ |
| `OPENAI_MODEL` | AI model to use | `gpt-4o` | ❌ |
| `OPENAI_TEMPERATURE` | AI creativity level (0.0-1.0) | `0.7` | ❌ |
| `OPENAI_MAX_TOKENS` | Maximum tokens per response | `4000` | ❌ |
| `ENVIRONMENT` | App environment | `development` | ❌ |
| `APP_VERSION` | App version | `1.0.0` | ❌ |
| `BUILD_NUMBER` | Build number | `1` | ❌ |

## Security Notes

- **Never commit your `.env` file** - it's already in `.gitignore`
- **Keep your API key secure** - don't share it publicly
- **Use different keys for different environments** (dev/staging/prod)
- **Rotate your API keys regularly** for security

## Development Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [OpenAI API Documentation](https://platform.openai.com/docs)
- [Flutter Environment Variables](https://pub.dev/packages/flutter_dotenv)
