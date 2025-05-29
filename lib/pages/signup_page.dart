import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:splitpal/pages/home_page.dart';
import 'package:splitpal/pages/login_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _passwordsMismatch = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool get _canSignUp {
    final usernameValid = _usernameController.text.trim().isNotEmpty;
    final emailValid = _emailController.text.contains('@');
    final passwordValid = _passwordController.text.length >= 6;
    final passwordsMatch = _passwordController.text == _confirmPasswordController.text;
    return usernameValid && emailValid && passwordValid && passwordsMatch;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onSignUp() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _passwordsMismatch = true);
      return;
    }

    setState(() {
      _isLoading = true;
      _passwordsMismatch = false;
    });

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await cred.user?.updateDisplayName(username);

      final counterRef = FirebaseFirestore.instance.collection('counters').doc('users');
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final counterSnap = await transaction.get(counterRef);
        int lastId = counterSnap.exists ? (counterSnap.data()?['lastId'] ?? 0) : 0;
        int newId = lastId + 1;
        String newUserId = 'U${newId.toString().padLeft(3, '0')}';

        // Create user document
        transaction.set(
          FirebaseFirestore.instance.collection('users').doc(newUserId),
          {
            'email': email,
            'username': username,
            'createdAt': FieldValue.serverTimestamp(),
            'currency': "\$",
            'friends': [],
            'groups': [],
          },
        );

        // Create userSummary subcollection with owe/owed initialized
        transaction.set(
          FirebaseFirestore.instance
              .collection('users')
              .doc(newUserId)
              .collection('userSummary')
              .doc('userSummary'),
          {
            'owe': 0,
            'owed': 0,
          },
        );

        // Update ID counter
        transaction.set(counterRef, {'lastId': newId});
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Sign up failed. Please try again.';
      if (e.code == 'email-already-in-use') {
        message = 'This email is already registered.';
      } else if (e.code == 'invalid-email') {
        message = 'That email address is invalid.';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak.';
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Sign Up',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                onChanged: (_) {
                  setState(() {
                    _passwordsMismatch =
                        _passwordController.text != _confirmPasswordController.text;
                  });
                },
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscureConfirmPassword,
                    onChanged: (_) {
                      setState(() {
                        _passwordsMismatch =
                            _passwordController.text != _confirmPasswordController.text;
                      });
                    },
                  ),
                  if (_passwordsMismatch)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Passwords do not match',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _canSignUp ? _onSignUp : null,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        child: Text('Sign Up', style: TextStyle(fontSize: 16)),
                      ),
                    ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                child: const Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
