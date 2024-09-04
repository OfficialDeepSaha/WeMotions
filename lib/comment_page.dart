import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:page_transition/page_transition.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:swipeable_button_view/swipeable_button_view.dart';
import 'package:wemotions/confirm_page.dart';
import 'package:wemotions/home_page.dart';

class CommentScreen extends StatefulWidget {
  final String postId;

  CommentScreen({Key? key, required this.postId}) : super(key: key);

  @override
  _CommentScreenState createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final Record _recorder;
  bool _isRecording = false;
  late AudioPlayer _audioPlayer;
  String? _selectedCommentId;
  bool _isFinalizing = false;
  bool _isSwipeFinished = false; // Initialize this flag
  bool _hasSwiped = false;
  late FirebaseMessaging _firebaseMessaging;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _recorder = Record();
    _audioPlayer = AudioPlayer();
    _firebaseMessaging = FirebaseMessaging.instance;

    _firebaseMessaging.requestPermission();
    _firebaseMessaging.subscribeToTopic(widget.postId);
    _firebaseMessaging.getToken().then((token) {
      print("FCM Token: $token");
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    var status = await Permission.microphone.request();
    if (!status.isGranted) {
      print('Microphone permission not granted');
      return;
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      try {
        final path = await _recorder.stop();
        setState(() {
          _isRecording = false;
        });

        if (path != null) {
          final file = File(path);
          final storageRef = FirebaseStorage.instance.ref().child(
              'voice_records/${DateTime.now().millisecondsSinceEpoch}.aac');
          final uploadTask = storageRef.putFile(file);

          await uploadTask.whenComplete(() async {
            final voiceUrl = await storageRef.getDownloadURL();
            _addComment(voiceUrl: voiceUrl);
          });
        }
      } catch (e) {
        print('Error stopping recorder: $e');
      }
    } else {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = path.join(directory.path, 'recording.aac');

        await _recorder.start(
          path: filePath,
          encoder: AudioEncoder.aacLc,
        );
        setState(() {
          _isRecording = true;
        });
      } catch (e) {
        print('Error starting recorder: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start recording: $e')),
        );
      }
    }
  }

  void _playVoiceMessage(String url) async {
    await _audioPlayer.play(UrlSource(url));
  }

  void _addComment({String? voiceUrl}) async {
    if (_commentController.text.isNotEmpty || voiceUrl != null) {
      final user = _auth.currentUser;
      if (user != null && !user.isAnonymous) {
        try {
          final newComment = {
            'userId': user.uid,
            'profileImageUrl':
                user.photoURL ?? 'https://via.placeholder.com/150',
            'name': user.displayName ?? '',
            'timeAgo': _getCurrentTimeAgo(),
            'commentText': _commentController.text,
            'voiceUrl': voiceUrl,
            'commentId': '',
          };
          _commentController.clear();
          final docRef = await _firestore
              .collection('posts')
              .doc(widget.postId)
              .collection('comments')
              .add(newComment);

          await docRef.update({'commentId': docRef.id});

          // Send notification to users subscribed to this post
          _sendNotification(
              'New Comment', '${user.displayName} added a comment');
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add comment: $e')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to comment.')),
        );
      }
    }
  }

  String _getCurrentTimeAgo() {
    final now = DateTime.now();
    final timeAgo = now.toLocal().toString().split(' ')[1];
    return timeAgo.substring(0, 5);
  }

  void _finalizeDiscussion() async {
    if (_selectedCommentId != null) {
      final user = _auth.currentUser;
      try {
        // Update the specific comment in Firestore
        await _firestore
            .collection('posts')
            .doc(widget.postId)
            .collection('comments')
            .doc(_selectedCommentId)
            .update({
          'isFinalized': true,
          'postId': widget.postId, // Store the postId in the comment
        });

        // Mark the entire post as finalized by updating the 'isFinalized' field
        await _firestore.collection('posts').doc(widget.postId).update({
          'isFinalized': true,
        });

        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': user?.uid, // Replace with the actual user ID
          'message': 'A post has been finalized!',
          'postId': widget.postId,
          'timestamp': Timestamp.now(),
          'read': false,
        });

        setState(() {
          _isFinalizing = false;
          _selectedCommentId = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Discussion finalized successfully.')),
        );

        // Send notification to users subscribed to this post
        _sendNotification('Discussion Finalized',
            'The discussion on this post has been finalized.');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to finalize post and comment: $e')),
        );
      }
    }
  }

  Future<void> _sendNotification(String title, String message) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'title': title,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'postId': widget.postId,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Discussion',
          style: TextStyle(
            color: Colors.purpleAccent,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('posts')
                      .doc(widget.postId)
                      .collection('comments')
                      .orderBy('timeAgo', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No comments yet.'));
                    }

                    final comments = snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return Comment(
                        userId: data['userId'],
                        profileImageUrl: data['profileImageUrl'],
                        name: data['name'],
                        timeAgo: data['timeAgo'],
                        commentText: data['commentText'],
                        commentId: data['commentId'],
                        voiceUrl: data['voiceUrl'],
                      );
                    }).toList();

                    return FutureBuilder<Map<String, String>>(
                      future: _fetchUsernames(
                          comments.map((c) => c.userId).toSet().toList()),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData) {
                          return const Center(
                              child: Text('Failed to fetch usernames.'));
                        }

                        final userNames = snapshot.data!;

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            final comment = comments[index];
                            final username =
                                userNames[comment.userId] ?? 'Unknown';

                            return GestureDetector(
                              onLongPress: () {
                                setState(() {
                                  _selectedCommentId = comment.commentId;
                                  _isFinalizing =
                                      true; // Trigger swipe process.
                                });
                                print('Comment selected: ${comment.commentId}');
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 16,
                                ),
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 3,
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundImage:
                                          NetworkImage(comment.profileImageUrl),
                                    ),
                                    title: Row(
                                      children: [
                                        Text(
                                          username,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.purple,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          comment.timeAgo,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (comment.commentText?.isNotEmpty ??
                                            false)
                                          Text(comment.commentText!),
                                        if (comment.voiceUrl != null)
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                    Icons.play_arrow),
                                                onPressed: () =>
                                                    _playVoiceMessage(
                                                        comment.voiceUrl!),
                                              ),
                                              const Text('Play voice message'),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          hintText: 'Write your comment...',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                      color: _isRecording ? Colors.red : Colors.purpleAccent,
                      onPressed: _toggleRecording,
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.purpleAccent),
                      onPressed: () => _addComment(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isFinalizing)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: SwipeableButtonView(
                buttonText: 'Finalize',
                buttonWidget: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey,
                ),
                activeColor: Colors.purpleAccent,
                buttonColor: Colors.white,
                isFinished: _isSwipeFinished, // Change the flag accordingly
                onWaitingProcess: () {
                  Future.delayed(const Duration(seconds: 2), () {
                    setState(() {
                      _isSwipeFinished = true;
                    });
                    _finalizeDiscussion();
                  });
                },
                onFinish: () async {
                  setState(() {
                    _hasSwiped = true; // Ensure the swipe action is complete
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<Map<String, String>> _fetchUsernames(List<String> userIds) async {
    final userNames = <String, String>{};

    for (var userId in userIds) {
      try {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final userData = userDoc.data();
        userNames[userId] = userData?['name'] ?? 'Unknown';
      } catch (e) {
        print('Failed to fetch username for $userId: $e');
      }
    }

    return userNames;
  }
}

class Comment {
  final String userId;
  final String profileImageUrl;
  final String name;
  final String timeAgo;
  final String? commentText;
  final String commentId;
  final String? voiceUrl;

  Comment({
    required this.userId,
    required this.profileImageUrl,
    required this.name,
    required this.timeAgo,
    required this.commentId,
    this.commentText,
    this.voiceUrl,
  });

  factory Comment.fromMap(Map<String, dynamic> data, String commentId) {
    return Comment(
      userId: data['userId'],
      profileImageUrl:
          data['profileImageUrl'] ?? 'https://via.placeholder.com/150',
      name: data['name'] ?? 'Unknown',
      timeAgo: data['timeAgo'] ?? '',
      commentText: data['commentText'],
      voiceUrl: data['voiceUrl'],
      commentId: commentId,
    );
  }
}
