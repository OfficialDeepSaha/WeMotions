import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_page.dart';
import 'post_page.dart';
import 'motions_page.dart';
import 'trending_page.dart';
import 'comment_page.dart';
import 'package:video_player/video_player.dart'; // Import the video player package
import 'notifications_page.dart';
import 'package:intl/intl.dart'; // Import the intl package
import 'package:google_fonts/google_fonts.dart';
import 'package:badges/badges.dart' as badges;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _notificationCount = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Navigate to the corresponding screen
    switch (index) {
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MotionsScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PostScreen()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TrendingScreen()),
        );
        break;

      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    _updateNotificationCount();
  }

  void _updateNotificationCount() async {
    // Stream to count unread notifications
    FirebaseFirestore.instance
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get()
        .then((snapshot) {
      setState(() {
        _notificationCount = snapshot.docs.length;
      });
    });
  }

  void _markNotificationsAsRead() async {
    // Mark all unread notifications as read
    final querySnapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();

    for (var doc in querySnapshot.docs) {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(doc.id)
          .update({'read': true});
    }
    _updateNotificationCount(); // Update badge count
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'We',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 21,
                  color: Colors.white,
                  shadows: [
                    const Shadow(
                      blurRadius: 10.0,
                      color: Colors.black26,
                      offset: Offset(2.0, 2.0),
                    ),
                  ],
                ),
              ),
              TextSpan(
                text: 'Motions',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 21,
                  foreground: Paint()
                    ..shader = const LinearGradient(
                      colors: <Color>[Colors.purple, Colors.pink],
                    ).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                  shadows: [
                    const Shadow(
                      blurRadius: 10.0,
                      color: Colors.black26,
                      offset: Offset(2.0, 2.0),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('userId',
                    isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                .where('read', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  margin: const EdgeInsets.only(right: 16.0),
                );
              }

              int notificationCount =
                  snapshot.hasData ? snapshot.data!.docs.length : 0;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotificationsScreen(),
                        ),
                      ).then((_) {
                        _markNotificationsAsRead();
                      });
                    },
                  ),
                  if (notificationCount > 0)
                    Positioned(
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2.0),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '$notificationCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('posts').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No posts available.'));
          }

          // Separate finalized and non-finalized posts
          List<QueryDocumentSnapshot> finalizedPosts = [];
          List<QueryDocumentSnapshot> nonFinalizedPosts = [];

          for (var doc in snapshot.data!.docs) {
            final post = doc.data() as Map<String, dynamic>;
            final isFinalized = post['isFinalized'] ?? false;

            if (isFinalized) {
              finalizedPosts.add(doc);
            } else {
              nonFinalizedPosts.add(doc);
            }
          }

          // Combine finalized posts at the top with non-finalized posts
          List<QueryDocumentSnapshot> allPosts = [
            ...finalizedPosts,
            ...nonFinalizedPosts,
          ];

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mood of the day',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...allPosts.map((doc) {
                    final post = doc.data() as Map<String, dynamic>;
                    final user = FirebaseAuth.instance.currentUser;
                    final currentUser = user != null ? user.uid : '';

                    final profilePicture = post['profileImageUrl'] ?? '';
                    final userName = post['userName'] ?? 'Unknown User';
                    final text = post['text'] ?? 'No text';
                    final imageUrl = post['imageUrl'] ?? '';
                    final videoUrl = post['videoUrl'] ?? '';
                    final createdAt = post['createdAt'] ?? 'Unknown Date';
                    final likes = List<String>.from(post['likes'] ?? []);
                    final dislikes = List<String>.from(post['dislikes'] ?? []);
                    final commentsCount = post['commentsCount'] ?? 0;
                    final sharesCount = post['sharesCount'] ?? 0;
                    final likesCount = post['likesCount'] ?? 0;
                    final dislikesCount = post['dislikesCount'] ?? 0;
                    final isFinalized = post['isFinalized'] ?? false;

                    DateTime parsedDate = DateTime.parse(createdAt);
                    String formattedDate =
                        DateFormat('d MMMM yyyy').format(parsedDate);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: NetworkImage(profilePicture),
                              radius: 25,
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 15,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  formattedDate,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          text,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (imageUrl.isNotEmpty)
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: NetworkImage(imageUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        else if (videoUrl.isNotEmpty)
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: VideoPlayerWidget(videoUrl: videoUrl),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildIconWithText(
                              icon: likes.contains(currentUser)
                                  ? Icons.thumb_up
                                  : Icons.thumb_up_alt_outlined,
                              text: '$likesCount',
                              onPressed: () => _toggleLike(doc.id),
                            ),
                            _buildIconWithText(
                              icon: dislikes.contains(currentUser)
                                  ? Icons.thumb_down
                                  : Icons.thumb_down_alt_outlined,
                              text: '$dislikesCount',
                              onPressed: () => _toggleDislike(doc.id),
                            ),
                            _buildIconWithText(
                              icon: Icons.comment_rounded,
                              text: '$commentsCount',
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CommentScreen(postId: doc.id),
                                ),
                              ),
                            ),
                            _buildIconWithText(
                              icon: Icons.share_outlined,
                              text: '$sharesCount',
                              onPressed: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (isFinalized)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Icon(Icons.verified,
                                    color: Colors.amber[300], size: 24),
                                const SizedBox(width: 8),
                                Text(
                                  'Finalized',
                                  style: TextStyle(
                                    color: Colors.amber[300],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const Divider(
                          color: Colors.grey,
                          height: 32,
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.pinkAccent,
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle_outline),
            label: 'Motions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Post',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up_sharp),
            label: 'Trending',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildIconWithText({
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 4),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

Future<void> _toggleLike(String postId) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);

  await FirebaseFirestore.instance.runTransaction((transaction) async {
    final postDoc = await transaction.get(postRef);
    if (!postDoc.exists) return;

    final post = postDoc.data()!;
    final likes = List<String>.from(post['likes'] ?? []);
    final dislikes = List<String>.from(post['dislikes'] ?? []);

    if (likes.contains(user.uid)) {
      likes.remove(user.uid);
    } else {
      likes.add(user.uid);
      dislikes.remove(user.uid);
    }

    await transaction.update(postRef, {
      'likes': likes,
      'dislikes': dislikes,
      'likesCount': likes.length,
      'dislikesCount': dislikes.length,
    });
  });
}

Future<void> _toggleDislike(String postId) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);

  await FirebaseFirestore.instance.runTransaction((transaction) async {
    final postDoc = await transaction.get(postRef);
    if (!postDoc.exists) return;

    final post = postDoc.data()!;
    final likes = List<String>.from(post['likes'] ?? []);
    final dislikes = List<String>.from(post['dislikes'] ?? []);

    if (dislikes.contains(user.uid)) {
      dislikes.remove(user.uid);
    } else {
      dislikes.add(user.uid);
      likes.remove(user.uid);
    }

    await transaction.update(postRef, {
      'likes': likes,
      'dislikes': dislikes,
      'likesCount': likes.length,
      'dislikesCount': dislikes.length,
    });
  });
}

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({Key? key, required this.videoUrl}) : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _isPlaying = false;
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
      } else {
        _controller.play();
        _isPlaying = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                ),
              ),
              Positioned(
                child: IconButton(
                  iconSize: 50,
                  icon: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _controller.value.isPlaying
                          ? _controller.pause()
                          : _controller.play();
                    });
                  },
                ),
              ),
            ],
          )
        : const Center(child: CircularProgressIndicator());
  }
}
