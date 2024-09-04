import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:cloudinary_api/uploader/cloudinary_uploader.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:cloudinary_api/src/request/model/uploader_params.dart';

class PostScreen extends StatefulWidget {
  @override
  _PostScreenState createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  File? _media;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  VideoPlayerController? _videoController;
  final TextEditingController _textController = TextEditingController();
  bool _isVideo = false;
  bool _isPlaying = false; // Track the video play/pause state

  // Initialize Cloudinary
  final cloudinary = Cloudinary.fromStringUrl(
      'cloudinary://764819777455659:1DXYXSbygsyiPzUr7bke6aObGBc@dwa1sm1f2');

  @override
  void dispose() {
    _videoController?.dispose();
    _textController.dispose();
    super.dispose();
  }

  // Method to handle media picking
  Future<void> _pickMedia(ImageSource source, bool isVideo) async {
    PermissionStatus permissionStatus;

    if (source == ImageSource.camera) {
      permissionStatus = await Permission.camera.request();
    } else {
      permissionStatus = await Permission.storage.request();
    }

    if (permissionStatus.isGranted) {
      final pickedFile = isVideo
          ? await _picker.pickVideo(source: source)
          : await _picker.pickImage(source: source);

      if (pickedFile != null) {
        setState(() {
          _media = File(pickedFile.path); // Ensure this path is valid
          _isVideo = isVideo;
        });

        // Set up video controller if it's a video
        if (isVideo) {
          if (_media != null && await _media!.exists()) {
            _videoController = VideoPlayerController.file(_media!)
              ..initialize().then((_) {
                setState(() {
                  _isPlaying = true;
                  _videoController!.play();
                });
              });
          }
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${source == ImageSource.camera ? 'Camera' : 'Storage'} permission is required.'),
        ),
      );
    }
  }

  // Method to toggle video play/pause
  void _togglePlayPause() {
    if (_videoController != null) {
      setState(() {
        if (_isPlaying) {
          _videoController!.pause();
        } else {
          _videoController!.play();
        }
        _isPlaying = !_isPlaying;
      });
    }
  }

  // Method to handle media upload
  Future<String?> _uploadMedia() async {
    if (_media == null) return null;

    setState(() {
      _isUploading = true;
    });

    try {
      var response = await cloudinary.uploader().upload(
            File(_media!.path),
            params: UploadParams(
              resourceType: 'auto', // Automatically determine the type
              publicId: 'customer',
              uniqueFilename: false,
              overwrite: true,
            ),
          );
      if (response?.data?.secureUrl != null) {
        return response!.data!.secureUrl; // Return the URL
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Media upload failed.')),
        );
        return null;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      return null;
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  // Method to save post to Firestore
  Future<void> _savePost() async {
    final mediaUrl = await _uploadMedia();
    if (mediaUrl == null) return;

    final FirebaseAuth _auth = FirebaseAuth.instance;
    User? user = _auth.currentUser;
    if (user == null) return;

    String formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Attempt to get the user's name from Firebase Authentication
    String userName = user.displayName ?? 'Anonymous';

    // If the display name is not set, fetch it from Firestore
    if (userName == 'Anonymous') {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection(
                'users') // Replace with your Firestore users collection name
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          userName = userDoc.get('name') ?? 'Anonymous';
        }
      } catch (e) {
        print('Error fetching user name from Firestore: $e');
        // Optionally handle the error
      }
    }

    // Collect post data
    Map<String, dynamic> postData = {
      'text': _textController.text,
      if (_isVideo) 'videoUrl': mediaUrl else 'imageUrl': mediaUrl,
      'createdAt': formattedDate,
      'userId': user.uid,
      'userName': userName,
    };

    print('Post Data: $postData'); // Debugging to check post data

    try {
      await FirebaseFirestore.instance.collection('posts').add(postData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post created successfully!'),
        ),
      );
    } catch (e) {
      print('Error adding document: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create post: $e')),
      );
    } finally {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Create a Post',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _isUploading
                ? const CircularProgressIndicator(color: Colors.white)
                : TextButton(
                    onPressed: _savePost,
                    child: const Text(
                      'Post',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(
                        'https://bsmedia.business-standard.com/_media/bs/img/article/2024-07/24/full/1721806332-4893.JPG?im=FeatureCrop,size=(826,465)'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      maxLines: 5,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "What's on your mind?",
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_media != null)
              Container(
                height: 200,
                margin: const EdgeInsets.symmetric(vertical: 10.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10.0,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    if (_videoController != null &&
                        _videoController!.value.isInitialized)
                      AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            VideoPlayer(_videoController!),
                            Positioned(
                              bottom: 8.0,
                              right: 8.0,
                              child: FloatingActionButton(
                                onPressed: _togglePlayPause,
                                mini: true,
                                backgroundColor: Colors.black54,
                                child: Icon(
                                  _isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (_media != null && _media!.path.endsWith('.mp4'))
                      const Center(child: CircularProgressIndicator())
                    else
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15.0),
                        child: Image.file(
                          _media!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    if (_videoController != null &&
                        _videoController!.value.isInitialized)
                      Positioned(
                        bottom: 8.0,
                        right: 8.0,
                        child: FloatingActionButton(
                          onPressed: _togglePlayPause,
                          mini: true,
                          backgroundColor: Colors.black54,
                          child: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  icon:
                      const Icon(Icons.camera_alt_outlined, color: Colors.grey),
                  onPressed: () => _pickMedia(ImageSource.camera, false),
                ),
                IconButton(
                  icon: const Icon(Icons.videocam_outlined, color: Colors.grey),
                  onPressed: () => _pickMedia(ImageSource.camera, true),
                ),
                IconButton(
                  icon: const Icon(Icons.photo_outlined, color: Colors.grey),
                  onPressed: () => _pickMedia(ImageSource.gallery, false),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        animatedIconTheme: const IconThemeData(size: 20.0),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        onOpen: () => print('Opening Speed Dial'),
        onClose: () => print('Closing Speed Dial'),
        children: [
          SpeedDialChild(
            child: const Icon(Icons.motion_photos_on),
            label: 'Motion',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MotionScreen()),
              );
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.star),
            label: 'Services',
            onTap: () {
              // Handle services icon action
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.event),
            label: 'Events',
            onTap: () {
              // Handle event icon action
            },
          ),
        ],
      ),
    );
  }
}

class MotionScreen extends StatefulWidget {
  @override
  _MotionScreenState createState() => _MotionScreenState();
}

class _MotionScreenState extends State<MotionScreen> {
  final TextEditingController _textController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _handleShare() async {
    print("Share button clicked");

    String text = _textController.text.trim();
    User? user = _auth.currentUser;

    print("Current text: $text");
    print("Current user ID: ${user?.uid}");
    print("User displayName: ${user?.displayName}");

    String userName = user?.displayName ?? 'Anonymous';

    if (userName == 'Anonymous' && user != null) {
      // Fetch the user's name from Firestore if displayName is not set
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users') // Assuming you have a users collection
          .doc(user.uid)
          .get();

      userName = userDoc.get('name') ?? 'Anonymous';
    }

    if (text.isNotEmpty && user != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      Map<String, dynamic> postData = {
        'text': text,
        'date': formattedDate,
        'userId': user.uid,
        'userName': userName,
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
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Motions',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.purpleAccent,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF131421),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E), // Light grey color
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: TextField(
                controller:
                    _textController, // Connect the TextField to the controller
                maxLines: 5,
                decoration: const InputDecoration.collapsed(
                  hintText: "What's on your mind?",
                  hintStyle: TextStyle(
                    color: Colors.grey, // Light grey color for the hint text
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _handleShare,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFFB262FF), // Purple color for the button
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
            ),
          ],
        ),
      ),
    );
  }
}
