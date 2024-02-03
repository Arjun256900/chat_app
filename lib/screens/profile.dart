import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.userId,
  });
  final String? userId;

  @override
  Widget build(BuildContext context) {
    Future<String> getImageUrl() async {
      final DocumentSnapshot doc =
          await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final String imageUrl = doc['image_url'];
      return imageUrl;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Display Picture'),
      ),
      body: FutureBuilder(
        future: getImageUrl(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text('Something went wrong :('),
            );
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: CircleAvatar(
                radius: double.infinity,
                backgroundImage: NetworkImage(snapshot.data!),
              ),
            ),
          );
        },
      ),
    );
  }
}
