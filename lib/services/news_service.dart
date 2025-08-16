import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart' as env;

const String _baseUrl = 'https://newsapi.org/v2';

class NewsService {
  final String apiKey;

  NewsService() : apiKey = _loadApiKey();

  static String _loadApiKey() {
    const fromDefine = String.fromEnvironment('NEWS_API_KEY', defaultValue: '');
    if (fromDefine.isNotEmpty) return fromDefine;

    final fromEnv = env.dotenv.maybeGet('NEWS_API_KEY') ?? '';
    if (fromEnv.isNotEmpty) return fromEnv;

    throw Exception(
        'Missing NEWS_API_KEY. Add to .env or pass with --dart-define.');
  }

  Future<List<Map<String, dynamic>>> fetchTopHeadlines({
    String country = 'in',
    int pageSize = 20,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/top-headlines?country=$country&pageSize=$pageSize',
    );

    final res = await http.get(uri, headers: {'X-Api-Key': apiKey});

    if (res.statusCode != 200) {
      throw Exception('NewsAPI error ${res.statusCode}: ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['status'] != 'ok') {
      throw Exception('NewsAPI returned status: ${data['status']}');
    }

    final list = (data['articles'] ?? []) as List;
    return list.cast<Map<String, dynamic>>();
  }
}
