# OneAI Chatbot Hub

A mobile AI chatbot application that integrates multiple AI providers into a single, user-friendly interface.

## Features

- Multiple AI Chatbots (OpenAI, Gemini, Mistral, DeepInfra, OpenRouter, Hugging Face)
- User Authentication (Login/Register)
- Dark/Light Theme Support
- Responsive Design (Mobile, Tablet, Desktop)
- Secure API Key Storage
- Chat History Management
- Platform Adaptive UI (Material Design & Cupertino)

## Setup Instructions

### 1. Clone the Repository

\`\`\`bash
git clone https://github.com/effdz/OneAi.git
cd OneAi
\`\`\`

### 2. Install Dependencies

\`\`\`bash
flutter pub get
\`\`\`

### 3. Setup API Keys

1. Copy the example environment file:
   \`\`\`bash
   cp .env.example .env
   \`\`\`

2. Edit `.env` file and add your actual API keys:
   \`\`\`
   OPENAI_API_KEY=your_actual_openai_key
   GEMINI_API_KEY=your_actual_gemini_key
   # ... add other keys
   \`\`\`

**IMPORTANT**: Never commit the `.env` file to version control. It contains sensitive API keys.

### 4. Run the Application

\`\`\`bash
flutter run
\`\`\`

## API Keys Setup

### OpenAI
1. Visit [OpenAI Platform](https://platform.openai.com/)
2. Create an account or sign in
3. Go to API Keys section
4. Create a new API key

### Google AI (Gemini)
1. Visit [Google AI Studio](https://makersuite.google.com/)
2. Sign in with Google account
3. Create a new API key

### Hugging Face
1. Visit [Hugging Face](https://huggingface.co/)
2. Create an account
3. Go to Settings > Access Tokens
4. Create a new token

### Mistral AI
1. Visit [Mistral AI](https://console.mistral.ai/)
2. Create an account
3. Go to API Keys section
4. Create a new API key

### DeepInfra
1. Visit [DeepInfra](https://deepinfra.com/)
2. Create an account
3. Go to API Keys section
4. Create a new API key

### OpenRouter
1. Visit [OpenRouter](https://openrouter.ai/)
2. Create an account
3. Go to Keys section
4. Create a new API key

## Security Best Practices

- API keys are stored securely using Flutter Secure Storage
- Environment variables are not committed to version control
- User authentication is implemented
- Input validation is performed on all forms
- Error handling prevents sensitive information leakage

## Project Structure

\`\`\`
lib/
├── models/           # Data models
├── providers/        # State management
├── screens/          # UI screens
├── services/         # API services
├── theme/           # App theming
├── utils/           # Utility classes
└── widgets/         # Reusable widgets
\`\`\`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Ensure no API keys are committed
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For support, please open an issue on GitHub or contact the development team.
