import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import 'services/news_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load .env if present (local dev). On Codemagic we’ll also support dart-define.
  await dotenv.load(fileName: ".env", isOptional: true);
  runApp(const NewsApp());
}

class NewsApp extends StatelessWidget {
  const NewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pulse News',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
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
    _future = NewsService.topHeadlines(country: 'in', pageSize: 25);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = NewsService.topHeadlines(country: 'in', pageSize: 25);
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('EEE, d MMM').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pulse News'),
        centerTitle: true,
        actions: [
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
                  // Simple header card
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
                    elevation: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (img.isNotEmpty)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                            child: CachedNetworkImage(
                              imageUrl: img,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                  height: 200, color: Colors.grey[300]),
                              errorWidget: (_, __, ___) => Container(
                                height: 200,
                                color: Colors.grey[200],
                                child: const Center(
                                    child: Icon(Icons.image_not_supported)),
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
                                    fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              if (desc.isNotEmpty)
                                Text(desc,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 8),
                              if (src.isNotEmpty)
                                Text(src,
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[700])),
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
}
