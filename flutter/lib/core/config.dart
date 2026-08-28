/// Runtime config. Prefer --dart-define over hardcoding secrets.
class AppConfig {
  static const version = '1.1.2';
  static const appName = 'JagX AI';

  static const openRouterApiKey = String.fromEnvironment(
    'OPENROUTER_API_KEY',
    defaultValue: '',
  );
  static const xaiApiKey = String.fromEnvironment(
    'XAI_API_KEY',
    defaultValue: '',
  );
  static const nvidiaApiKey = String.fromEnvironment(
    'NVIDIA_API_KEY',
    defaultValue: '',
  );

  /// Better Auth / backend base (no trailing slash).
  static const authBaseUrl = String.fromEnvironment(
    'AUTH_BASE_URL',
    defaultValue: 'https://www.jagxai.name.ng',
  );

  static const openRouterBase = 'https://openrouter.ai/api/v1';
  static const xaiBase = 'https://api.x.ai/v1';
  static const nvidiaBase = 'https://integrate.api.nvidia.com/v1';

  static bool get hasAnyLlmKey =>
      openRouterApiKey.isNotEmpty ||
      xaiApiKey.isNotEmpty ||
      nvidiaApiKey.isNotEmpty;
}
