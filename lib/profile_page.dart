import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import flutter_svg package
import 'package:random_avatar/random_avatar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:lottie/lottie.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Razorpay _razorpay;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _name;
  String? _email;
  String? _profileImageUrl;
  bool _isVerified = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      _email = user.email;
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;

        setState(() {
          _name = data['name'] ?? 'Unknown User';
          _profileImageUrl = data['profileImageUrl'] ?? '';
          _isVerified = data['verified'] ?? false;
          _isLoading = false;
        });
      } else {
        setState(() {
          _name = 'Unknown User';
          _profileImageUrl =
              'https://www.woolha.com/media/2020/03/flutter-circleavatar-radius.jpg';
          _isLoading = false;
        });
      }
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'verified': true,
      });

      setState(() {
        _isVerified = true;
      });
    }
    _showSuccessAnimation(context);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: ${response.message}')),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

  void _processPayment() {
    var options = {
      'key': 'rzp_test_GkajTwSfONYREd', // Replace with your Razorpay Key ID
      'amount': 2000 * 100, // Amount in smallest currency unit
      'name': 'WeMotions',
      'description': 'Payment for verification',
      'prefill': {'contact': '9876543210', 'email': _email},
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showSuccessAnimation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            width: 100,
            height: 100,
            child: Lottie.asset(
              'assets/verified_success.json', // Ensure this file is added
              repeat: false,
              onLoaded: (composition) {
                Future.delayed(composition.duration, () {
                  Navigator.of(context).pop();
                  _navigateToVerifiedScreen(context);
                });
              },
            ),
          ),
        );
      },
    );
  }

  void _navigateToVerifiedScreen(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => VerifiedProfileScreen(
          name: _name ?? 'User Name',
          profileImageUrl: _profileImageUrl ??
              'https://www.woolha.com/media/2020/03/flutter-circleavatar-radius.jpg',
        ),
      ),
    );
  }

  void _showAvatarSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Select an Avatar',
            style: TextStyle(
              color: Colors.purpleAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Container(
            width: double.maxFinite,
            height: 200,
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: 16, // Number of avatars you want to show
              itemBuilder: (context, index) {
                final avatarSeed =
                    'avatar$index'; // Unique seed for each avatar
                return GestureDetector(
                  onTap: () async {
                    User? user = _auth.currentUser;
                    if (user != null) {
                      final avatarUrl =
                          RandomAvatarString(avatarSeed, trBackground: true);
                      await _firestore
                          .collection('users')
                          .doc(user.uid)
                          .update({
                        'profileImageUrl': avatarUrl,
                      });

                      setState(() {
                        _profileImageUrl =
                            avatarUrl; // Update the profile image URL
                      });
                    }
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: RandomAvatar(
                    avatarSeed,
                    height: 50,
                    width: 50,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _logout() async {
    try {
      // Stop any active listeners or Firestore operations if needed

      // Sign out the user
      await FirebaseAuth.instance.signOut();

      // Navigate to the login page or other relevant screen
      Navigator.of(context).pushReplacementNamed(
          '/login'); // Make sure this route is defined in your app
    } catch (e) {
      // Handle errors if any
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during logout: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1D1E33),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.purpleAccent,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.purpleAccent,
              ),
            )
          : SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Use ClipOval to create a circular shape for the avatar
                      ClipOval(
                        child: _profileImageUrl != null &&
                                _profileImageUrl!.isNotEmpty
                            ? SvgPicture.string(
                                _profileImageUrl! ??
                                    'https://www.woolha.com/media/2020/03/flutter-circleavatar-radius.jpg',
                                height: 120,
                                width: 120,
                                fit: BoxFit.cover,
                              )
                            : CircleAvatar(
                                radius: 60,
                                backgroundImage: NetworkImage(
                                    'https://www.woolha.com/media/2020/03/flutter-circleavatar-radius.jpg'),
                              ),
                      ),
                      if (_isVerified)
                        Positioned(
                          bottom: 0,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            child: Image.network(
                              'https://res.cloudinary.com/dwa1sm1f2/image/upload/v1724625502/gwserts1qmr9sv4iey4r.png', // URL to your badge image
                              width: 35,
                              height: 35,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _name ?? 'User Name',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _email ?? 'Email',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 30),
                  _isVerified
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.greenAccent,
                              width: 2,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified,
                                color: Colors.greenAccent,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Verified Account',
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: _processPayment,
                          // Implement payment process

                          icon: const Icon(Icons.verified_user,
                              color: Colors.white),
                          label: const Text(
                            'Get Verified',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purpleAccent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 5,
                          ),
                        ),
                  const SizedBox(height: 40),
                  Divider(
                    color: Colors.grey[700],
                    thickness: 1,
                  ),
                  const SizedBox(height: 20),
                  _buildProfileOption(
                    icon: Icons.settings,
                    title: 'Settings',
                    onTap: () {
                      // Navigate to Settings Page
                    },
                  ),
                  _buildProfileOption(
                    icon: Icons.person_2_outlined,
                    title: 'Change Avatar',
                    onTap: _showAvatarSelectionDialog, // Handle avatar change
                  ),
                  _buildProfileOption(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () {
                      // Navigate to Help & Support Page
                    },
                  ),
                  _buildProfileOption(
                    icon: Icons.exit_to_app,
                    title: 'Logout',
                    onTap: _logout,
                    hasNavigation: false,
                    color: Colors.redAccent,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    bool hasNavigation = true,
    Color color = Colors.white,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: color,
        size: 28,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: hasNavigation
          ? const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            )
          : null,
      onTap: onTap,
    );
  }
}

class VerifiedProfileScreen extends StatelessWidget {
  final String name;
  final String profileImageUrl;

  const VerifiedProfileScreen({
    required this.name,
    required this.profileImageUrl,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131421),
      appBar: AppBar(
        title: const Text('Verified Profile'),
        backgroundColor: Colors.purpleAccent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipOval(
              child: profileImageUrl.endsWith('.svg')
                  ? SvgPicture.network(
                      profileImageUrl,
                      height: 120,
                      width: 120,
                      fit: BoxFit.cover,
                    )
                  : CircleAvatar(
                      radius: 60,
                      backgroundImage: NetworkImage(
                          'https://www.woolha.com/media/2020/03/flutter-circleavatar-radius.jpg'),
                    ),
            ),
            const SizedBox(height: 20),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.greenAccent, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.verified,
                    color: Colors.greenAccent,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Verified Account',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
