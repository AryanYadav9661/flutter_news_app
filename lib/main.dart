import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as env;

// Default NewsAPI REST base
const String _defaultBaseUrl = 'https://newsapi.org/v2';

// Prefer --dart-define, fallback to .env
String _getApiKey() {
  const fromDefine = String.fromEnvironment('NEWS_API_KEY', defaultValue: '');
  if (fromDefine.isNotEmpty) return fromDefine;

  final fromEnv = env.dotenv.maybeGet('NEWS_API_KEY') ?? '';
  if (fromEnv.isNotEmpty) return fromEnv;

  return '';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await env.dotenv.load(fileName: '.env', isOptional: true);
  runApp(const NewsApp());
}

class NewsApp extends StatelessWidget {
  const NewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pulse News',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HeadlinesScreen(),
    );
  }
}

class HeadlinesScreen extends StatefulWidget {
  const HeadlinesScreen({super.key});

  @override
  State<HeadlinesScreen> createState() => _HeadlinesScreenState();
}

class _HeadlinesScreenState extends State<HeadlinesScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchTopHeadlines(country: 'in', pageSize: 25);
  }

  Future<void> main() async {
    await env.dotenv.load(fileName: ".env");
  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('EEE, d MMM').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pulse News'),
        centerTitle: true,
        // ignore: prefer_const_literals_to_create_immutables
        actions: [
          // ignore: prefer_const_constructors
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Failed to load headlines:\n${snap.error}',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              );
            }
            final articles = snap.data ?? [];

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: articles.length + 1,
              itemBuilder: (context, idx) {
                if (idx == 0) {
                  return Card(
                    margin: const EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.today),
                      title: const Text('Top Headlines (India)'),
                      subtitle: Text(date),
                    ),
                  );
                }
                final a = articles[idx - 1];
                final title = (a['title'] ?? '') as String;
                final desc = (a['description'] ?? '') as String;
                final src = (a['source']?['name'] ?? '') as String;
                final url = (a['url'] ?? '') as String;
                final img = (a['urlToImage'] ?? '') as String;

                return GestureDetector(
                  onTap: () async {
                    final uri = Uri.tryParse(url);
                    if (uri != null && await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Card(
                    margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (img.isNotEmpty)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: CachedNetworkImage(
                              imageUrl: img,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                height: 200,
                                color: Colors.grey[300],
                                alignment: Alignment.center,
                                child: const CircularProgressIndicator(),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                height: 200,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(Icons.image_not_supported),
                                ),
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title.isEmpty ? 'Untitled' : title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (desc.isNotEmpty)
                                Text(
                                  desc,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.public, size: 16),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      src.isEmpty ? 'Unknown source' : src,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.open_in_new, size: 16),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchTopHeadlines({
    String country = 'in',
    int pageSize = 20,
  }) async {
    final key = _getApiKey();
    if (key.isEmpty) {
      throw Exception(
        'Missing NEWS_API_KEY. Add it to a .env file or pass with --dart-define.',
      );
    }

    final uri = Uri.parse(
      '$_defaultBaseUrl/top-headlines'
      '?country=$country'
      '&pageSize=$pageSize',
    );

    final res = await http.get(
      uri,
      headers: {'X-Api-Key': key},
    );

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
class _refresh {}
