import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class EventsPage extends ConsumerWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("USER DASHBOARD", style: GoogleFonts.plusJakartaSans(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              Text("DIRECTORY", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
              const SizedBox(height: 48),
              Text("SELECT DOMAIN", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 32),
              _buildDomainItem(context, 'PHASE SHIFT', 'TECH SYMPOSIUM', const Color(0xFF00E5FF), Icons.bolt, '/events-list?type=phaseshift'),
              _buildDomainItem(context, 'UTSAV', 'CULTURAL FEST', const Color(0xFFFF1C7C), Icons.auto_awesome, '/events-list?type=utsav'),
              _buildDomainItem(context, 'CLUB EVENTS', 'STUDENT GUILDS', const Color(0xFF39FF14), Icons.school, '/events-list?type=regular'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDomainItem(BuildContext context, String title, String subtitle, Color color, IconData icon, String route) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.only(bottom: 24),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10))),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF13131D), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                Text(subtitle, style: GoogleFonts.plusJakartaSans(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, color: Colors.white12, size: 16),
          ],
        ),
      ),
    );
  }
}
