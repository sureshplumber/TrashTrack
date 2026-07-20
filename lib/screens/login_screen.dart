import 'package:flutter/material.dart';
import '../services/local_storage.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _role = 'citizen';

  void _submitAuth() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    await LocalStorageService.loginOrRegisterUser(_email, _role);
    widget.onLoginSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4E2CD), // Linen/Cream Primary Background
      appBar: AppBar(
        title: const Text('TrashTrack Authentication', style: TextStyle(color: Color(0xFFF4E2CD))),
        backgroundColor: const Color(0xFF331D0A), // Deep Espresso
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 2,
            color: const Color(0xFFFAF4EC), // Soft Warm White Surface Card
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF331D0A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.recycling, color: Color(0xFFF4E2CD), size: 40),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Welcome to TrashTrack',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF331D0A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Select your user role to enter portal',
                      style: TextStyle(fontSize: 12, color: Color(0xFF664D38)),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        labelStyle: const TextStyle(color: Color(0xFF331D0A)),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF331D0A)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF331D0A)),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) =>
                          val == null || !val.contains('@') ? 'Enter a valid email' : null,
                      onSaved: (val) => _email = val!.trim().toLowerCase(),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _role,
                      decoration: InputDecoration(
                        labelText: 'Select Portal Role',
                        labelStyle: const TextStyle(color: Color(0xFF331D0A)),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF331D0A)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF331D0A)),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'citizen', child: Text('Citizen Portal')),
                        DropdownMenuItem(value: 'official', child: Text('Government Official Portal')),
                      ],
                      onChanged: (val) => setState(() => _role = val!),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF331D0A), // Primary Dark
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _submitAuth,
                        child: const Text(
                          'ENTER PORTAL',
                          style: TextStyle(
                            color: Color(0xFFF4E2CD),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}