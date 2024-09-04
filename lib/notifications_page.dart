import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart'; // For formatting timestamp

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: NotificationsScreen(),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: Colors.purpleAccent,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Handle settings action
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          const SectionTitle(title: 'Today'),
          const NotificationItem(
            icon: Icons.notifications_none,
            title: 'Account updates',
            subtitle: 'Your account logged in from a new device',
            trailingText: '1m',
          ),
          const SectionTitle(title: 'Previous'),
          const NotificationItem(
            icon: Icons.tv,
            title: 'LIVE: Elon Musk is live!',
            subtitle: 'Watch him reunite with his family!',
            trailingText: '9min',
          ),
          const NotificationItem(
            icon: Icons.person_outline,
            title: 'Profile views',
            subtitle: '5 people viewed your profile',
            trailingText: '10h',
          ),
          NotificationItem(
            icon: Icons.card_giftcard,
            title: 'Special offer',
            subtitle: 'Enjoy 20% off on your next purchase',
            trailingButton: TextButton(
              onPressed: () {
                // Handle claim action
              },
              child: const Text('Claim Now'),
            ),
          ),
          const SectionTitle(title: 'Finalized Posts'),
          FinalizedPostsSection(),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}

class NotificationItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailingText;
  final Widget? trailingButton;

  const NotificationItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailingText,
    this.trailingButton,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(8.0),
        child: Icon(icon, color: Colors.black),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: trailingButton ??
          Text(
            trailingText ?? '',
            style: const TextStyle(color: Colors.grey),
          ),
    );
  }
}

class FinalizedPostsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('title', isEqualTo: 'Discussion Finalized')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'No finalized posts yet.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;

            // Format the timestamp
            String formattedTime = '';
            if (data['timestamp'] != null) {
              var timestamp = data['timestamp'] as Timestamp;
              formattedTime =
                  DateFormat('d MMMM yyyy, h:mm a').format(timestamp.toDate());
            }

            return NotificationItem(
              icon: Icons.star,
              title: data['title'] ?? 'Discussion Finalized',
              subtitle: data['message'] ??
                  'The discussion on this post has been finalized.',
              trailingText: formattedTime,
            );
          }).toList(),
        );
      },
    );
  }
}
