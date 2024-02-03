import 'dart:async';

import 'package:chat_app/widgets/message_bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatMessages extends StatefulWidget {
  const ChatMessages({super.key});

  @override
  State<ChatMessages> createState() => _ChatMessagesState();
}

class _ChatMessagesState extends State<ChatMessages> {
  String? eMail;
  String? imgUrl;
  String? userName;
  Future<void> _deleteMessage(String messageId) async {
    try {
      final messageRef =
          FirebaseFirestore.instance.collection('chat').doc(messageId);
      await messageRef.delete();
    } catch (e) {
      ScaffoldMessenger.of(context).clearMaterialBanners();
      ScaffoldMessenger.of(context).showMaterialBanner(
        MaterialBanner(
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).clearMaterialBanners();
              },
              child: const Text('Dismiss'),
            )
          ],
        ),
      );
    }
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
    listenForDataChanges();
  }

  @override
  void dispose() {
    profileDataSnapshot?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authenticatedUser = FirebaseAuth.instance.currentUser!;
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('chat')
          .orderBy(
            'createdAt',
            descending: true,
          )
          .snapshots(),
      builder: (ctx, chatSnapshots) {
        if (chatSnapshots.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (!chatSnapshots.hasData || chatSnapshots.data!.docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'No messages found. Be the first to break the ice!',
                style: GoogleFonts.signika(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (chatSnapshots.hasError) {
          Center(
            child: Text(
              'Something went wrong, have a coffee while we figure out!',
              style: GoogleFonts.signika(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }
        final loadedMessages = chatSnapshots.data!.docs;
        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.only(bottom: 40, left: 15, right: 15),
          itemCount: loadedMessages.length,
          itemBuilder: (ctx, index) {
            final chatMessage = loadedMessages[index].data();
            final nextChatMessage = index + 1 < loadedMessages.length
                ? loadedMessages[index + 1].data()
                : null;
            final currentMessageUserId = chatMessage['userId'];
            final nextMessageUserId =
                nextChatMessage != null ? nextChatMessage['userId'] : null;
            final nextUserIsSame = nextMessageUserId == currentMessageUserId;
            if (nextUserIsSame) {
              return InkWell(
                onTap: () {},
                onLongPress: () {
                  authenticatedUser.uid == currentMessageUserId
                      ? showDialog(
                          context: context,
                          builder: (ctx) {
                            return AlertDialog(
                              title: const Text('Delete message'),
                              content: const Text(
                                  'Are you sure you wanna delete this message?'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    _deleteMessage(loadedMessages[index].id);
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text(
                                    'Delete Message',
                                    style: TextStyle(
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          })
                      : null;
                },
                child: MessageBubble.next(
                  message: chatMessage['text'],
                  userId: nextMessageUserId,
                  isMe: authenticatedUser.uid == currentMessageUserId,
                ),
              );
            } else {
              return InkWell(
                onTap: () {},
                onLongPress: () {
                  authenticatedUser.uid == currentMessageUserId
                      ? showDialog(
                          context: context,
                          builder: (ctx) {
                            return AlertDialog(
                              title: const Text('Delete message'),
                              content: const Text(
                                  'Are you sure you wanna delete this message?'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    _deleteMessage(loadedMessages[index].id);
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text(
                                    'Delete Message',
                                    style: TextStyle(
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          })
                      : null;
                },
                child: MessageBubble.first(
                  userImage: chatMessage['userImage'],
                  userId: currentMessageUserId,
                  username: chatMessage['username'],
                  message: chatMessage['text'],
                  isMe: authenticatedUser.uid == currentMessageUserId,
                ),
              );
            }
          },
        );
      },
    );
  }
}
