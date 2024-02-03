import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class DetailsScreen extends StatefulWidget {
  DetailsScreen({
    super.key,
    required this.userId,
    required this.username,
    required this.mail,
    required this.image,
  });
  final String? userId;
  String? username;
  String? mail;
  String? image;
  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  File? newImg;
  @override
  void initState() {
    super.initState();
    listenForDataChanges();
  }

  Future<void> _saveChanges(
      {String? newUserName, String? newImage, String? newMail}) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final userDocRef =
          FirebaseFirestore.instance.collection('users').doc(currentUser!.uid);
      final Map<String, dynamic> updatedData = {};
      if (newUserName != null) {
        updatedData['username'] = newUserName;
      }
      if (newMail != null) {
        updatedData['email'] = newMail;
      }
      if (newImage != null) {
        updatedData['image_url'] = newImage;
      }
      await userDocRef.update(updatedData);
      ScaffoldMessenger.of(context).clearMaterialBanners();
      ScaffoldMessenger.of(context).showMaterialBanner(
        MaterialBanner(
          content: const Text('Changes saved!.'),
          actions: [
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).clearMaterialBanners();
              },
              child: const Text('Okay'),
            ),
          ],
        ),
      );
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
              child: const Text('Okay'),
            ),
          ],
        ),
      );
    }
  }

  void _pickImage() async {
    try {
      final pickedImage = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 200,
      );
      if (pickedImage == null) {
        return;
      }
      setState(() {
        newImg = File(pickedImage.path);
      });
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_images')
          .child('${FirebaseAuth.instance.currentUser!.uid}.jpg');
      await storageRef.putFile(newImg!);
      final downloadUrl = await storageRef.getDownloadURL();
      FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({
        'image_url': downloadUrl,
      });
      setState(() {
        widget.image = downloadUrl;
      });
    } catch (e) {
      print(e);
    }
  }

  late StreamSubscription<DocumentSnapshot> profileDataSnapshot;
  void listenForDataChanges() {
    final user = FirebaseAuth.instance.currentUser;
    final userDocRef =
        FirebaseFirestore.instance.collection('users').doc(user!.uid);
    profileDataSnapshot = userDocRef.snapshots().listen((docSnapshot) {
      if (docSnapshot.exists) {
        setState(() {
          widget.username = docSnapshot['username'];
          widget.mail = docSnapshot['email'];
          widget.image = docSnapshot['image_url'];
        });
      }
    });
  }

  @override
  void dispose() {
    profileDataSnapshot.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController(text: widget.username);
    final mailController = TextEditingController(text: widget.mail);
    final uidController =
        TextEditingController(text: FirebaseAuth.instance.currentUser!.uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Info'),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CircleAvatar(
                    radius: 90,
                    backgroundImage: NetworkImage(widget.image!),
                  ),
                ),
              ],
            ),
            TextButton.icon(
              icon: const Icon(Icons.camera_alt_outlined),
              onPressed: () {
                _pickImage();
              },
              label: Text(
                'Edit display picture',
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 10, right: 10),
              child: Divider(
                color: Colors.white,
                thickness: 0.4,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: TextField(
                controller: nameController,
                decoration: InputDecoration(
                  label: const Text('Display Name'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: TextField(
                enabled: false,
                controller: mailController,
                decoration: InputDecoration(
                  label: const Text('Your mail'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).clearMaterialBanners();
                  ScaffoldMessenger.of(context).showMaterialBanner(
                    MaterialBanner(
                      content: const Text('You cannot modify your UID'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context)
                                .clearMaterialBanners();
                          },
                          child: const Text('Okay'),
                        ),
                      ],
                    ),
                  );
                },
                child: TextField(
                  controller: uidController,
                  enabled: false,
                  decoration: InputDecoration(
                    label: const Text('UID'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Discard',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                    ),
                    onPressed: () {
                      final updatedUserName = nameController.text.trim();
                      final updatedMail = mailController.text.trim();
                      _saveChanges(
                        newImage: widget.image,
                        newMail: updatedMail,
                        newUserName: updatedUserName,
                      );
                    },
                    child: const Text(
                      'Save changes',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
