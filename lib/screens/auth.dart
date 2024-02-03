import 'dart:io';

import 'package:chat_app/widgets/user_image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();

  var _enterdUserName = '';
  var _enteredEmail = '';
  var _enteredPassword = '';
  File? selectedImage;
  bool _isLogin = true;
  bool isObscure = true;
  var _isAuthenticating = false;
  void _submit() async {
    final isValid = _form.currentState!.validate();
    if (!isValid || !_isLogin && selectedImage == null) {
      ScaffoldMessenger.of(context).clearMaterialBanners();
      ScaffoldMessenger.of(context).showMaterialBanner(
        MaterialBanner(
          content:
              const Text('Please add a profile to prove you are not a robot'),
          actions: [
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).clearMaterialBanners();
              },
              child: const Text('Dismiss'),
            ),
          ],
        ),
      );
      return;
    }
    _form.currentState!.save();
    try {
      setState(() {
        _isAuthenticating = true;
      });
      if (_isLogin) {
        final userCredentials = await _firebase.signInWithEmailAndPassword(
          email: _enteredEmail,
          password: _enteredPassword,
        );
      } else {
        final userCredentials = await _firebase.createUserWithEmailAndPassword(
          email: _enteredEmail,
          password: _enteredPassword,
        );
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child('${userCredentials.user!.uid}.jpg');
        await storageRef.putFile(selectedImage!);
        final imageUrl = await storageRef.getDownloadURL();
        FirebaseFirestore.instance
            .collection('users')
            .doc(userCredentials.user!.uid)
            .set({
          'username': _enterdUserName,
          'email': _enteredEmail,
          'image_url': imageUrl,
        });
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).clearMaterialBanners();
      ScaffoldMessenger.of(context).showMaterialBanner(MaterialBanner(
        content: Text(e.message ?? 'Authentication failed'),
        actions: [
          TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).clearMaterialBanners();
              },
              child: const Text('Dismiss'))
        ],
      ));
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 183, 42, 89),
              Color.fromARGB(255, 50, 101, 143),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 200,
                  width: 200,
                  padding: const EdgeInsets.only(
                    top: 30,
                    left: 20,
                    right: 20,
                    bottom: 20,
                  ),
                  child: Image.asset('lib/assets/images/chat.png'),
                ),
                Card(
                  margin: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _form,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!_isLogin)
                              UserImagePicker(
                                onPickImage: (pickedImage) {
                                  selectedImage = pickedImage;
                                },
                              ),
                            if (!_isLogin)
                              TextFormField(
                                onSaved: (value) {
                                  _enterdUserName = value!;
                                },
                                decoration: const InputDecoration(
                                  label: Text('Username'),
                                ),
                                enableSuggestions: false,
                                validator: (value) {
                                  if (value == null ||
                                      value.trim().length < 4) {
                                    return 'Please enter a username with 4 characters long';
                                  }
                                  return null;
                                },
                              ),
                            TextFormField(
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty ||
                                    !value.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                labelText: 'Email Address',
                              ),
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              textCapitalization: TextCapitalization.none,
                              onSaved: (value) {
                                _enteredEmail = value!;
                              },
                            ),
                            TextFormField(
                              onSaved: (value) {
                                _enteredPassword = value!;
                              },
                              validator: (value) {
                                if (value == null || value.trim().length < 6) {
                                  return 'Password must be atleast 6 characters long';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      isObscure = !isObscure;
                                    });
                                  },
                                  icon: Icon(isObscure
                                      ? Icons.remove_red_eye
                                      : Icons.highlight_remove),
                                ),
                                labelText: 'Password',
                              ),
                              obscureText: isObscure,
                            ),
                            const SizedBox(height: 22),
                            if (_isAuthenticating)
                              const CircularProgressIndicator(),
                            if (!_isAuthenticating)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                ),
                                onPressed: _submit,
                                child: Text(_isLogin ? 'Login' : 'Signup'),
                              ),
                            if (!_isAuthenticating)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isLogin = !_isLogin;
                                  });
                                },
                                child: Text(
                                  _isLogin
                                      ? 'Create an account'
                                      : 'I already have an account',
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
