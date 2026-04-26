import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
          CurvedAnimation(parent: _fadeController, curve: Curves.easeOutQuart),
        );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (prev, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFFF1C7C),
            content: Text(
              next.error!,
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Unified "UNIFY" Title Style
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'UNIFY',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 64,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF00E5FF),
                                  letterSpacing: 8,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                width: 10,
                                height: 10,
                                margin: const EdgeInsets.only(top: 40),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFFF1C7C),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "EVENTS",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              letterSpacing: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 64),

                    // Login Card (Clean style, no glassmorphism/shadows)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: const Color(0xFF13131D),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            "AUTHENTICATION_REQUIRED",
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF00E5FF).withOpacity(0.6),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildTextField(
                            controller: usernameController,
                            label: "USERNAME",
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: passwordController,
                            label: "PASSWORD",
                            icon: Icons.lock_outline,
                            isPassword: true,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: authState.isLoading
                                  ? null
                                  : () {
                                      ref.read(authProvider.notifier).login(
                                            usernameController.text,
                                            passwordController.text,
                                          );
                                    },
                              child: authState.isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text("INITIALIZE SESSION"),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.white10)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text("OR", style: GoogleFonts.plusJakartaSans(color: Colors.white24, fontSize: 12)),
                              ),
                              Expanded(child: Divider(color: Colors.white10)),
                            ],
                          ),
                          const SizedBox(height: 32),
                          // Google Login Button
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: Colors.white.withOpacity(0.1)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: authState.isLoading
                                ? null
                                : () => ref.read(authProvider.notifier).googleLogin(),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.network(
                                  'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1024px-Google_%22G%22_logo.svg.png',
                                  height: 20,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, color: Colors.white, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Continue with Google",
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF00E5FF), size: 20),
      ),
    );
  }
}
