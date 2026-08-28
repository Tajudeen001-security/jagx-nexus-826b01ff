/// Runtime config. Prefer --dart-define / CI secrets over hardcoding.
/// Never commit real API keys.
class AppConfig {
  static const version = '1.1.2';
  static const appName = 'JagX AI';

  /// OpenRouter — free + paid models (https://openrouter.ai/keys)
  static const openRouterApiKey = String.fromEnvironment(
    'OPENROUTER_API_KEY',
    defaultValue: '',
  );

  /// Kimi / Moonshot — OpenAI-compatible (https://platform.kimi.ai)
  /// Env: KIMI_API_KEY or MOONSHOT_API_KEY
  static const kimiApiKey = String.fromEnvironment(
    'KIMI_API_KEY',
    defaultValue: '',
  );
  static const moonshotApiKey = String.fromEnvironment(
    'MOONSHOT_API_KEY',
    defaultValue: '',
  );

  /// NVIDIA NIM — free tier available (https://build.nvidia.com)
  static const nvidiaApiKey = String.fromEnvironment(
    'NVIDIA_API_KEY',
    defaultValue: '',
  );

  /// Groq — generous free tier (https://console.groq.com/keys)
  static const groqApiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: '',
  );

  /// Better Auth / backend base (no trailing slash).
  static const authBaseUrl = String.fromEnvironment(
    'AUTH_BASE_URL',
    defaultValue: 'https://www.jagxai.name.ng',
  );

  static const openRouterBase = 'https://openrouter.ai/api/v1';
  static const kimiBase = 'https://api.moonshot.ai/v1';
  static const nvidiaBase = 'https://integrate.api.nvidia.com/v1';
  static const groqBase = 'https://api.groq.com/openai/v1';

  static String get effectiveKimiKey =>
      kimiApiKey.isNotEmpty ? kimiApiKey : moonshotApiKey;

  static bool get hasAnyLlmKey =>
      openRouterApiKey.isNotEmpty ||
      effectiveKimiKey.isNotEmpty ||
      nvidiaApiKey.isNotEmpty ||
      groqApiKey.isNotEmpty;
}
