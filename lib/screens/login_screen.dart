import 'package:flutter/material.dart';
import '../services/local_storage.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  String _selectedRole = 'citizen'; // 'citizen' or 'official'

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final nameOrEmail = _usernameController.text.trim();
    await LocalStorageService.setCurrentUser(nameOrEmail, _selectedRole);
    if (mounted) {
      widget.onLoginSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.citizenBackground,
      appBar: AppBar(
        title: const Text(
          'TrashTrack Auth Portal',
          style: TextStyle(color: AppColors.primaryTextDark, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryTextLight,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              elevation: 3,
              color: AppColors.citizenCardSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.borderLight),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Icon & Title
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryTextLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cleaning_services_rounded,
                          color: AppColors.primaryTextDark,
                          size: 42,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'TrashTrack Command',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryTextLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Offline Municipal Waste Reporting & Tracking',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryTextLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),

                      // User Identity Input
                      TextFormField(
                        controller: _usernameController,
                        style: const TextStyle(color: AppColors.primaryTextLight),
                        decoration: InputDecoration(
                          labelText: 'Name / Identification ID',
                          labelStyle: const TextStyle(color: AppColors.primaryTextLight),
                          hintText: _selectedRole == 'official'
                              ? 'e.g. Inspector Officer #402'
                              : 'e.g. Resident Citizen',
                          hintStyle: const TextStyle(color: AppColors.secondaryTextLight, fontSize: 13),
                          filled: true,
                          fillColor: AppColors.citizenBackground,
                          prefixIcon: Icon(
                            _selectedRole == 'official' ? Icons.badge_outlined : Icons.person_outline,
                            color: AppColors.primaryTextLight,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.borderLight),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.primaryTextLight, width: 2),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter your name or user ID';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // Visual Role Selection Header
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Select Portal Access Role',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryTextLight,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Clear visual distinction cards for Citizen vs Official
                      Row(
                        children: [
                          Expanded(
                            child: _buildRoleCard(
                              roleKey: 'citizen',
                              title: 'Citizen Portal',
                              subtitle: 'Report & Track',
                              icon: Icons.person_pin_circle_outlined,
                              activeColor: AppColors.primaryTextLight,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildRoleCard(
                              roleKey: 'official',
                              title: 'Official Portal',
                              subtitle: 'BBMP Clearance',
                              icon: Icons.admin_panel_settings_outlined,
                              activeColor: AppColors.officialBackground,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // Login Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedRole == 'official'
                                ? AppColors.officialBackground
                                : AppColors.primaryTextLight,
                            foregroundColor: AppColors.primaryTextDark,
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _submitLogin,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _selectedRole == 'official'
                                    ? 'ENTER OFFICIAL PORTAL'
                                    : 'ENTER CITIZEN PORTAL',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
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
      ),
    );
  }

  Widget _buildRoleCard({
    required String roleKey,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color activeColor,
  }) {
    final bool isSelected = _selectedRole == roleKey;

    return InkWell(
      onTap: () => setState(() => _selectedRole = roleKey),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.1) : AppColors.citizenBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.borderLight,
            width: isSelected ? 2.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? activeColor : AppColors.secondaryTextLight,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? activeColor : AppColors.primaryTextLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? activeColor : AppColors.secondaryTextLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}