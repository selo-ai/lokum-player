import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  late GenerativeModel _model;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Read API key from .env
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    
    if (apiKey.isEmpty || apiKey == 'your_api_key_here') {
      throw Exception('Gemini API Key bulunamadı. Lütfen .env dosyasını kontrol edin.');
    }

    // Initialize the Gemini Model (gemini-2.5-flash is the standard for 2026)
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
    );
    
    _isInitialized = true;
  }

  /// Send a prompt to Gemini and get a response.
  Future<String> askAssistant(String prompt) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? 'Üzgünüm, cevap oluşturulamadı.';
    } catch (e) {
      print('AI Service Error: $e');
      throw Exception('Yapay zeka ile iletişim kurulamadı: $e');
    }
  }
}
