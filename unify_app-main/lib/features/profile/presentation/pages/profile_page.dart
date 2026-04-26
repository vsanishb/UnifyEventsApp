import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../auth/presentation/providers/auth_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  void _showEditProfileModal(BuildContext context, String currentUsername, String currentEmail) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditProfileModal(initialUsername: currentUsername, initialEmail: currentEmail),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final username = user?.username ?? 'GUEST USER';
    final email = user?.email ?? 'NOT PROVIDED';
    final initial = username.isNotEmpty ? username[0].toUpperCase() : 'G';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF13131D),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: const Color(0xFFFF1C7C).withOpacity(0.3)),
                ),
                child: Center(child: Text(initial, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900))),
              ),
              const SizedBox(height: 24),
              Text(username.toUpperCase(), style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
              Text(email.toUpperCase(), style: GoogleFonts.plusJakartaSans(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showEditProfileModal(context, username, email),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text("EDIT PROFILE"),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.1), foregroundColor: Colors.redAccent),
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text("LOGOUT"),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              _buildActionItem(Icons.history, 'BOOKING HISTORY', () => context.go('/bookings')),
              if (user?.role == 'admin' || user?.role == 'organiser')
                _buildActionItem(Icons.dashboard_outlined, 'MANAGE DASHBOARD', () => context.go('/manage')),
              _buildActionItem(Icons.help_outline, 'HELP & SUPPORT', () => _showHelp(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF13131D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: const Color(0xFF00E5FF), size: 20),
        title: Text(title, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white12, size: 12),
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF13131D),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("HELP & SUPPORT", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 24),
            _buildContact("ANISH", "+91 99999 99999"),
            _buildContact("ANITEJ", "+91 99997 99997"),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildContact(String name, String phone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
          Text(phone, style: GoogleFonts.jetBrainsMono(color: const Color(0xFF00E5FF), fontSize: 14)),
        ],
      ),
    );
  }
}

class _EditProfileModal extends ConsumerStatefulWidget {
  final String initialUsername;
  final String initialEmail;
  const _EditProfileModal({required this.initialUsername, required this.initialEmail});

  @override
  ConsumerState<_EditProfileModal> createState() => _EditProfileModalState();
}

class _EditProfileModalState extends ConsumerState<_EditProfileModal> {
  late TextEditingController _userCtrl;
  late TextEditingController _emailCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _userCtrl = TextEditingController(text: widget.initialUsername);
    _emailCtrl = TextEditingController(text: widget.initialEmail);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF13131D), borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      padding: EdgeInsets.only(top: 24, left: 24, right: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("EDIT PROFILE", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 24),
          TextFormField(controller: _userCtrl, decoration: const InputDecoration(labelText: "USERNAME", prefixIcon: Icon(Icons.person_outline))),
          const SizedBox(height: 16),
          TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: "EMAIL", prefixIcon: Icon(Icons.email_outlined))),
          const SizedBox(height: 32),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _loading ? null : _save,
              child: _loading ? const CircularProgressIndicator() : const Text("SAVE CHANGES"),
            ),
          ),
        ],
      ),
    );
  }

  void _save() async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/auth/user/', data: {'username': _userCtrl.text, 'email': _emailCtrl.text});
      ref.invalidate(authProvider);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
