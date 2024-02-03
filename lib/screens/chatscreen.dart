import 'dart:async';

import 'package:chat_app/screens/details_screen.dart';
import 'package:chat_app/widgets/chat_messages.dart';
import 'package:chat_app/widgets/new_messages.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String? eMail;
  String? imgUrl;
  String? userName;
  void setUpPushNotification() async {
    final fcm = FirebaseMessaging.instance;
    await fcm.requestPermission();
    fcm.subscribeToTopic('chat');
  }

  StreamSubscription<DocumentSnapshot>? profileDataSnapshot;

  void listenForDataChanges() {
    final user = FirebaseAuth.instance.currentUser;
    final userDocRef =
        FirebaseFirestore.instance.collection('users').doc(user!.uid);
    profileDataSnapshot = userDocRef.snapshots().listen((docSnapshot) {
      if (docSnapshot.exists) {
        setState(() {
          eMail = docSnapshot['email'];
          imgUrl = docSnapshot['image_url'];
          userName = docSnapshot['username'];
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    setUpPushNotification();
    listenForDataChanges();
  }

  @override
  void dispose() {
    profileDataSnapshot?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          TextButton(
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (ctx) {
                      return AlertDialog(
                        content: Text(
                          'Are you sure?',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 20),
                        ),
                        actions: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Cancel action'),
                              ),
                              TextButton(
                                onPressed: () {
                                  FirebaseAuth.instance.signOut();
                                  Navigator.of(context).pop();
                                },
                                child: const Text(
                                  'Logout',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    });
              },
              child: Text(
                'Logout',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ))
        ],
      ),
      body: const Column(
        children: [
          Expanded(child: ChatMessages()),
          NewMessage(),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              child: Row(
                children: [
                  Text(
                    'Stay In Touch',
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: 24,
                        ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            ListTile(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (ctx) {
                  return DetailsScreen(
                    userId: FirebaseAuth.instance.currentUser!.toString(),
                    username: userName,
                    mail: eMail,
                    image: imgUrl,
                  );
                }));
              },
              leading: Icon(
                Icons.edit,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                'Edit your profile',
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 19,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
