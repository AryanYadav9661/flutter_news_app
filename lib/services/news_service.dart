import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NewsService {
  // Reads from .env (local) or from --dart-define (Codemagic fallback)
  static String get _apiKey =>
      dotenv.env['NEWS_API_KEY'] ??
      const String.fromEnvironment('NEWS_API_KEY', defaultValue: '');

  static const _base = 'https://newsapi.org/v2';

  static Future<List<Map<String, dynamic>>> topHeadlines({
    String country = 'in',
    int pageSize = 20,
  }) async {
    final uri = Uri.parse(
      '$_base/top-headlines?country=$country&pageSize=$pageSize&apiKey=$_apiKey',
    );

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('NewsAPI error ${res.statusCode}: ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['status'] != 'ok') {
      throw Exception('NewsAPI returned status: ${data['status']}');
    }
    final List arts = (data['articles'] ?? []) as List;
    return arts.cast<Map<String, dynamic>>();
  }
}
