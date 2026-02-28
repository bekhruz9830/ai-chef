/// Set GROQ_API_KEY via --dart-define=GROQ_API_KEY=your_key or in keys.dart (local only).
class ApiConfig {
  static const String groqApiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: '',
  );
}
