import 'dart:convert';
import 'package:http/http.dart' as http;

const String _baseUrl = 'https://newsapi.org/v2';

class NewsService {
  final String apiKey;

  NewsService() : apiKey = _1fa0223b03bc45a28eeaaa50dc305ec4();

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

// ignore: camel_case_types
class _1fa0223b03bc45a28eeaaa50dc305ec4 {}
