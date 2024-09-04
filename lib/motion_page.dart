import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Import intl package

class MotionScreen extends StatefulWidget {
  @override
  _MotionScreenState createState() => _MotionScreenState();
}

class _MotionScreenState extends State<MotionScreen> {
  final TextEditingController _textController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _handleShare() async {
    print("Share button clicked");

    String text = _textController.text;
    User? user = _auth.currentUser;

    print("Current text: $text");
    print("Current user ID: ${user?.uid}");
    print("User displayName: ${user?.displayName}");

    if (text.isNotEmpty && user != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      Map<String, dynamic> postData = {
        'text': text,
        'date': formattedDate,
        'userId': user.uid,
        'userName': user.displayName ?? 'Anonymous',
      };

      try {
        print("Adding document to Firestore...");
        await FirebaseFirestore.instance.collection('motions').add(postData);
        print("Document added successfully");
        _textController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Post shared successfully!')),
        );
      } catch (e) {
        print("Error adding document: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share post: $e')),
        );
      }
    } else {
      print("Text is empty or user is null");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please write something to share.')),
      );
    }
  }

  void _testButton() {
    print("Button pressed!");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Button pressed!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () {
            // Handle close action
          },
        ),
        title: const Text(
          'Motions',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F3), // Light grey color
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: TextField(
                controller: _textController,
                maxLines: 5,
                decoration: const InputDecoration.collapsed(
                  hintText: "What's on your mind?",
                  hintStyle: TextStyle(
                    color:
                        Color(0xFF9E9E9E), // Light grey color for the hint text
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _handleShare,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB262FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 100, vertical: 20),
              ),
              child: const Text(
                'Share',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
