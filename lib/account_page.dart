import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Account Template',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AccountPage(),
    );
  }
}

class AccountPage extends StatelessWidget {
  const AccountPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text(
            'Account',
            style: TextStyle(
              color: Colors.purpleAccent,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          )),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(),
            const SizedBox(height: 16),
            // Tags and Follow Button
            _buildTagsAndFollowButton(),
            const SizedBox(height: 16),
            // Stats
            _buildStats(),
            const Divider(thickness: 1),
            // Tabs and Grid
            _buildPostsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        const CircleAvatar(
          radius: 50,
          backgroundImage: NetworkImage(
              'https://encrypted-tbn1.gstatic.com/images?q=tbn:ANd9GcRy5QMODyHm-LaMpgXOqMIUHPbQ-Y51jAZR_UJYC-9Dv1IL3ovh'), // Your image asset
        ),
        const SizedBox(height: 8),
        const Text(
          'Elon Mask',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Age 53\nJoined in 2024',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildTagsAndFollowButton() {
    return Column(
      children: [
        OutlinedButton(
          onPressed: () {},
          child: const Text('Follow'),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: const [
            Chip(label: Text('Web designer')),
            Chip(label: Text('Artist')),
            Chip(label: Text('Hiking')),
            Chip(label: Text('Tennis')),
            Chip(label: Text('Roadtrip')),
            Chip(label: Text('Cooking')),
            Chip(label: Text('Poker')),
          ],
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          _StatItem(label: 'Following', value: '85'),
          _StatItem(label: 'Followers', value: '1091'),
          _StatItem(label: 'Likes', value: '4384'),
        ],
      ),
    );
  }

  Widget _buildPostsSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('Posts', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(width: 16),
            Text('Collections', style: TextStyle(color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4, // Number of posts
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 3 / 4,
            ),
            itemBuilder: (context, index) {
              return _PostItem(index: index);
            },
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }
}

class _PostItem extends StatelessWidget {
  final int index;

  const _PostItem({required this.index});

  @override
  Widget build(BuildContext context) {
    // Dummy images for posts
    final images = [
      'https://academy-public.coinmarketcap.com/srd-optimized-uploads/308b6187b3da4286bb13d2504b6f442e.jpeg',
      'https://akm-img-a-in.tosshub.com/businesstoday/images/story/202310/untitled_design_79-sixteen_nine.jpg?size=948:533',
      'https://i.insider.com/6557b23f22cf74a573997886?width=700',
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSFBP5_2bv23loBwEK7Tt1jX5TNidvF-Pdk6w&s',
    ];

    final titles = [
      'Hiking in North Bay',
      'Bought a New House',
      'Cooking My Favorite Recipe',
      'Got Some New Plants',
    ];

    final views = [
      '438 views',
      '293 views',
      '842 views',
      '748 views',
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Image
          Container(
            height: 150,
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              image: DecorationImage(
                image: NetworkImage(images[index]),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Post Title
                Text(
                  titles[index],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blueAccent.shade700, // Bright color for title
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Post Views
                Row(
                  children: [
                    const Icon(
                      Icons.visibility,
                      size: 16,
                      color: Colors.blueAccent, // Matching icon color
                    ),
                    const SizedBox(width: 4),
                    Text(
                      views[index],
                      style: TextStyle(
                        color: Colors
                            .blueAccent.shade200, // Softer color for views
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Like and Comment buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildActionButton(
                      icon: Icons.thumb_up,
                      label: 'Like',
                      color: Colors.pinkAccent,
                    ),
                    _buildActionButton(
                      icon: Icons.comment,
                      label: 'Comment',
                      color: Colors.tealAccent,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      {required IconData icon, required String label, required Color color}) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
