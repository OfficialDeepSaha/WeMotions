import 'package:flutter/material.dart';
import 'profile_page.dart';

class VerifiedProfileScreen extends StatelessWidget {
  const VerifiedProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131421),
      appBar: AppBar(
        title: const Text('Verified Profile',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF131421),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(
                  'https://randomuser.me/api/portraits/men/32.jpg'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Michel',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Verified Account',
              style: TextStyle(
                fontSize: 16,
                color: Colors.greenAccent[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
