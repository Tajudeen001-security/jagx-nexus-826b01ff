/// Runtime config. Prefer --dart-define / CI secrets over hardcoding.
class AppConfig {
  static const version = '1.2.1';
  static const appName = 'JagX AI';

  static const openRouterApiKey = String.fromEnvironment(
    'OPENROUTER_API_KEY',
    defaultValue: '',
  );

  static const nvidiaApiKey = String.fromEnvironment(
    'NVIDIA_API_KEY',
    defaultValue: '',
  );

  static const authBaseUrl = String.fromEnvironment(
    'AUTH_BASE_URL',
    defaultValue: 'https://www.jagxai.name.ng',
  );

  static const openRouterBase = 'https://openrouter.ai/api/v1';
  static const nvidiaBase = 'https://integrate.api.nvidia.com/v1';

  static bool get hasAnyLlmKey =>
      nvidiaApiKey.isNotEmpty || openRouterApiKey.isNotEmpty;
}
