import 'package:flutter/material.dart';
import 'account_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF131421),
        primaryColor: Colors.purpleAccent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF131421),
          foregroundColor: Colors.white,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1a1f33),
          selectedItemColor: Colors.purpleAccent,
          unselectedItemColor: Colors.white70,
        ),
      ),
      home: TrendingScreen(),
    );
  }
}

class TrendingScreen extends StatefulWidget {
  @override
  _TrendingScreenState createState() => _TrendingScreenState();
}

class _TrendingScreenState extends State<TrendingScreen> {
  final List<Map<String, String>> trendingItems = [
    {
      "title": "Steelers at Panthers",
      "category": "NFL",
      "imageUrl":
          "https://kubrick.htvapps.com/htv-prod-media.s3.amazonaws.com/images/steelers-panthers-0120-1514900765.jpg?crop=1.00xw:1.00xh;0,0&resize=1200:*",
    },
    {
      "title": "Elon Musk's new Tesla",
      "category": "Celebrities",
      "imageUrl":
          "https://i.cdn.newsbytesapp.com/images/l30820240228165340.jpeg",
    },
    {
      "title": "Elon Musk",
      "tweets": "1.2M Tweets",
      "imageUrl":
          "https://encrypted-tbn1.gstatic.com/images?q=tbn:ANd9GcRy5QMODyHm-LaMpgXOqMIUHPbQ-Y51jAZR_UJYC-9Dv1IL3ovh",
    },
    {
      "title": "Lady Gaga",
      "tweets": "876K Tweets",
      "imageUrl":
          "https://m.media-amazon.com/images/M/MV5BMjQ4MzIzMDkyOF5BMl5BanBnXkFtZTgwNzE4NjYwODM@._V1_QL75_UX500_CR0,35,500,281_.jpg",
    },
    {
      "title": "New York City",
      "tweets": "543K Tweets",
      "imageUrl":
          "https://cdn.britannica.com/48/179448-138-40EABF32/Overview-New-York-City.jpg",
    },
    {
      "title": "NFL",
      "tweets": "234K Tweets",
      "imageUrl":
          "https://cf-images.us-east-1.prod.boltdns.net/v1/static/854081161001/28841c18-9e46-4f9b-a64a-e0e3f939574f/3b37ed59-d7e7-4907-90f7-7edfce57d853/1280x720/match/image.jpg",
    },
    {
      "title": "Jeff Bezos",
      "tweets": "549K Tweets",
      "imageUrl":
          "https://image.cnbcfm.com/api/v1/image/105815446-1553624918736gettyimages-1078542150.jpeg?v=1612303414",
    },
    {
      "title": "Mark Zuckerberg",
      "tweets": "234K Tweets",
      "imageUrl": "https://i.insider.com/66be2b0c955b01c3294eeb8f?width=700",
    },
  ];

  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> filteredItems = trendingItems
        .where((item) =>
            item['title']!.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Trending",
          style: TextStyle(
            color: Colors.purpleAccent,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        elevation: 5,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.purpleAccent),
            onPressed: () {
              // Handle search action
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: "Search for a topic or person",
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon:
                    const Icon(Icons.search, color: Colors.purpleAccent),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[850],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: filteredItems.map((item) {
                  return item.containsKey('tweets')
                      ? buildTrendingSmallCard(
                          item['title']!, item['tweets']!, item['imageUrl']!)
                      : buildTrendingCard(
                          item['title']!, item['category']!, item['imageUrl']!);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTrendingCard(String title, String category, String imageUrl) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            spreadRadius: 1,
            offset: Offset(0, 4),
          ),
        ],
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
          colorFilter:
              ColorFilter.mode(Colors.black.withOpacity(0.6), BlendMode.darken),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    // Handle button press
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purpleAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text("Watch all"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTrendingSmallCard(String title, String tweets, String imageUrl) {
    return GestureDetector(
      onTap: () {
        // Navigate to the accountpage
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  const AccountPage()), // replace AccountPage with your actual page
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2C2B3E),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.6), BlendMode.darken),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(imageUrl),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tweets,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
