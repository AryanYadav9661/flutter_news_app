import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/news_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final NewsService _service;
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _service = NewsService();
    _future = _service.fetchTopHeadlines(country: 'in', pageSize: 25);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _service.fetchTopHeadlines(country: 'in', pageSize: 25);
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
                      'Error loading news:\n${snap.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              );
            }
            final articles = snap.data ?? [];

            return ListView.builder(
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
                      title: const Text('Top Headlines'),
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
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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
                                height: 200,
                                alignment: Alignment.center,
                                child: const CircularProgressIndicator(),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                height: 200,
                                color: Colors.grey[200],
                                child: const Icon(Icons.broken_image),
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
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              if (desc.isNotEmpty)
                                Text(
                                  desc,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.black87),
                                ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.public, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    src.isEmpty ? 'Unknown source' : src,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.open_in_new, size: 14),
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
}
