import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity/connectivity.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> news = [];
  Timer? _debounceTimer;
  final apiKey = dotenv.env['API_KEY'];

  List<Map<String, String>> dummyNews = [
    {
      'title': 'Dummy News 1',
      'imageUrl': 'https://example.com/dummy1.jpg',
    },
    {
      'title': 'Dummy News 2',
      'imageUrl': 'https://example.com/dummy2.jpg',
    },
  ];

  @override
  void initState() {
    super.initState();
    getAllNews();
    _searchController.addListener(() {
      if (_debounceTimer != null) {
        _debounceTimer!.cancel();
      }
      _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
        _performSearch(_searchController.text);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1E1F),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () async {
                  try {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pop(context);
                    print('User logged out successfully');
                  } catch (e) {
                    print('Error logging out: $e');
                  }
                },
                child: const Text("Logout", style: TextStyle(fontSize: 15, color: Colors.white),),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search News',
                  labelStyle: TextStyle(color: Colors.white),
                  prefixIcon: Icon(Icons.search, color: Colors.white,),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                cursorColor: Colors.white,
                style: const TextStyle(color: Colors.white)
              ),
            ),
            FutureBuilder(
                future: Future.value(news),
                builder:
                    (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                        child: Text('Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.white)));
                  } else {
                    var list = snapshot.data;
                    return Expanded(
                      child: ListView.builder(
                        itemCount: list.length > 50 ? 50 : list.length,
                        itemBuilder: (context, index) {
                          final title = list[index]['title'];
                          final imageUrl = list[index]['urlToImage'];
                          final description = list[index]['description'];
                          final source = list[index]['source']['name'];
                          final publishedAt = list[index]['publishedAt'];
                          if (title == null || imageUrl == null || description == null || source == null || publishedAt == null) return const SizedBox.shrink();
                          return NewsCard(
                            title: title,
                            imageUrl: imageUrl,
                            description: description,
                            publishedAt: publishedAt,
                            source: source,
                          );
                        },
                      ),
                    );
                  }
                }),
          ],
        ),
      ),
    );
  }

  Future<List<dynamic>> getAllNews() async {
    final response = await http.get(
      Uri.parse('https://newsapi.org/v2/everything?q=sports&apiKey=$apiKey'),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      news = responseData['articles'];
      setState(() {});
      return news;
    } else {
      return dummyNews;
      // throw Exception('Failed to send message to News API.');
    }
  }

  Future<bool> isInternetConnected() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<List<dynamic>> _performSearch(String query) async {
    final response = await http.get(
      Uri.parse('https://newsapi.org/v2/everything?q=$query&apiKey=$apiKey'),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      news = responseData['articles'];
      setState(() {});
      return news;
    } else {
      return dummyNews;
      // throw Exception('Failed to send message to News API.');
    }
  }
}

class NewsCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final String description;
  final String publishedAt;
  final String source;

  NewsCard({required this.title, required this.imageUrl, required this.description, required this.publishedAt, required this.source});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey,
      margin: const EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      elevation: 3.0,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
            child: Row(
              children: [
                Text(publishedAt),
                const SizedBox(width: 20,),
                Text(source, style: const TextStyle(fontWeight: FontWeight.bold),)
              ],
            ),
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                      child: Text(
                        description,
                        style: const TextStyle(fontSize: 16.0),
                        maxLines: 3,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(
                    Radius.circular(12.0),
                  ),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    height: 90,
                    width: 120,
                    errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                      return const Center(child: Text("Error Loading Image"));
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}