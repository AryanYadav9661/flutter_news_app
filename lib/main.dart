import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
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
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List articles = [];
  bool loading = true;
  String weather = "Loading...";

  @override
  void initState() {
    super.initState();
    fetchNews();
    fetchWeather();
  }

  Future<void> fetchNews() async {
    try {
      // Replace with your NewsAPI key
      const apiKey = "YOUR_NEWSAPI_KEY";
      const url =
          "https://newsapi.org/v2/top-headlines?country=in&apiKey=$apiKey";
      final res = await http.get(Uri.parse(url));
      final data = jsonDecode(res.body);

      if (data["status"] == "ok") {
        setState(() {
          articles = data["articles"];
          loading = false;
        });
      }
    } catch (e) {
      setState(() => loading = false);
    }
  }

  Future<void> fetchWeather() async {
    try {
      // Replace with your OpenWeather API key
      const apiKey = "YOUR_OPENWEATHER_KEY";
      const url =
          "https://api.openweathermap.org/data/2.5/weather?q=Mumbai&appid=$apiKey&units=metric";
      final res = await http.get(Uri.parse(url));
      final data = jsonDecode(res.body);

      if (data["main"] != null) {
        setState(() {
          weather =
              "${data["main"]["temp"].toString()}°C • ${data["weather"][0]["description"]}";
        });
      }
    } catch (e) {
      setState(() => weather = "Weather unavailable");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pulse News"),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await fetchNews();
          await fetchWeather();
        },
        child: ListView(
          children: [
            // Weather Card
            Card(
              margin: const EdgeInsets.all(12),
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.cloud, size: 40, color: Colors.indigo),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Mumbai • $weather",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // News List
            if (loading)
              const Center(
                  child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ))
            else
              ...articles.map((article) {
                return GestureDetector(
                  onTap: () async {
                    final url = article["url"];
                    if (await canLaunchUrl(Uri.parse(url))) {
                      launchUrl(Uri.parse(url),
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (article["urlToImage"] != null)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                            child: CachedNetworkImage(
                              imageUrl: article["urlToImage"],
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (c, s) => Container(
                                height: 200,
                                color: Colors.grey[300],
                              ),
                              errorWidget: (c, s, e) => Container(
                                height: 200,
                                color: Colors.grey,
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
                                article["title"] ?? "No title",
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                article["description"] ?? "",
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                article["publishedAt"] != null
                                    ? DateFormat.yMMMd().add_jm().format(
                                        DateTime.parse(article["publishedAt"]))
                                    : "",
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }
}
