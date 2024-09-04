import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MotionsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'All Motions',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: Colors.purpleAccent),
        ),
        backgroundColor: const Color(0xFF131421),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('motions').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final motions = snapshot.data?.docs ?? [];

          if (motions.isEmpty) {
            return Center(child: Text('No motions found'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: motions.length,
            itemBuilder: (context, index) {
              final motion = motions[index];
              final motionData = motion.data() as Map<String, dynamic>?;

              return MotionCard(
                name: motionData?['userName'] ?? 'Anonymous',
                suggestion: motionData?['text'] ?? '',
                aiScore: motionData?['aiScore'] ?? 0,
                upVotes: motionData?['upVotes'] ?? 0,
                downVotes: motionData?['downVotes'] ?? 0,
                date: motionData?['date'] ?? '',
                postId: motion.id, // Provide the document ID here
              );
            },
          );
        },
      ),
    );
  }
}

class MotionCard extends StatefulWidget {
  final String name;
  final String suggestion;
  final int aiScore;
  final int upVotes;
  final int downVotes;
  final String date;
  final String postId; // Document ID to update the post

  const MotionCard({
    required this.name,
    required this.suggestion,
    required this.aiScore,
    required this.upVotes,
    required this.downVotes,
    required this.date,
    required this.postId,
  });

  @override
  _MotionCardState createState() => _MotionCardState();
}

class _MotionCardState extends State<MotionCard> {
  late int upVotes;
  late int downVotes;
  late String currentVote; // Track current user's vote

  @override
  void initState() {
    super.initState();
    upVotes = widget.upVotes;
    downVotes = widget.downVotes;
    currentVote = ''; // Initialize based on user's voting history
    fetchUserVote();
  }

  Future<void> fetchUserVote() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final postRef =
          FirebaseFirestore.instance.collection('motions').doc(widget.postId);
      final postSnapshot = await postRef.get();
      final postData = postSnapshot.data() as Map<String, dynamic>?;

      if (postData != null) {
        final userVotes = postData['userVotes'] as Map<String, dynamic>?;
        currentVote = userVotes?[userId] ?? '';
        setState(() {});
      }
    } catch (e) {
      print('Error fetching user vote: $e');
    }
  }

  Future<void> updateVote(String voteType) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final postRef =
          FirebaseFirestore.instance.collection('motions').doc(widget.postId);
      final postSnapshot = await postRef.get();
      final postData = postSnapshot.data() as Map<String, dynamic>?;

      if (postData != null) {
        final userVotes = postData['userVotes'] as Map<String, dynamic>?;

        final updates = <String, dynamic>{};
        if (voteType == 'upvote') {
          if (currentVote == 'downvote') {
            downVotes--;
          }
          if (currentVote != 'upvote') {
            upVotes++;
            updates['userVotes.$userId'] = 'upvote';
            currentVote = 'upvote';
          }
        } else if (voteType == 'downvote') {
          if (currentVote == 'upvote') {
            upVotes--;
          }
          if (currentVote != 'downvote') {
            downVotes++;
            updates['userVotes.$userId'] = 'downvote';
            currentVote = 'downvote';
          }
        }

        // Remove the user's vote if they switch their vote or cancel it
        if (voteType == '') {
          if (currentVote == 'upvote') {
            upVotes--;
          } else if (currentVote == 'downvote') {
            downVotes--;
          }
          updates.remove('userVotes.$userId');
          currentVote = '';
        }

        await postRef.update({
          'upVotes': upVotes,
          'downVotes': downVotes,
          ...updates,
        });
        setState(() {});
      }
    } catch (e) {
      print('Error updating vote: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF131421),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.green),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.date,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            widget.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            widget.suggestion,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.thumb_up,
                      color:
                          currentVote == 'upvote' ? Colors.green : Colors.grey,
                    ),
                    onPressed: () => updateVote('upvote'),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'UpVotes: $upVotes',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.thumb_down,
                      color:
                          currentVote == 'downvote' ? Colors.red : Colors.grey,
                    ),
                    onPressed: () => updateVote('downvote'),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'DownVotes: $downVotes',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Text(
                'Ai Score: ${widget.aiScore}',
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
