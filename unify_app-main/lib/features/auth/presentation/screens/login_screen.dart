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
  bool _obscurePassword = true;

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
                    const SizedBox(height: 32),
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
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade400,
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
                            "Sign In",
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.grey.shade400,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildTextField(
                            controller: usernameController,
                            label: "Email",
                            hintText: "unify@gmail.com",
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: passwordController,
                            label: "Password",
                            hintText: "••••••••••••",
                            isPassword: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: Colors.grey.shade600,
                                size: 22,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
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
                                  : const Text("Sign In"),
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
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              "Or create a new account with Google",
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
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
    bool isPassword = false,
    Widget? suffixIcon,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white.withOpacity(0.2), fontSize: 15),
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
