import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/bookings_provider.dart';

class BookingsPage extends ConsumerWidget {
  const BookingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(myBookingsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("MY BOOKINGS", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        backgroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: bookingsAsync.when(
        data: (bookings) {
          if (bookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.confirmation_number_outlined, size: 64, color: Colors.white10),
                  const SizedBox(height: 16),
                  Text("NO BOOKINGS YET", style: GoogleFonts.plusJakartaSans(color: Colors.white24, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(24).copyWith(bottom: 120),
            itemCount: bookings.length,
            itemBuilder: (context, index) => _buildBookingCard(context, bookings[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("ERROR: $err")),
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, Map<String, dynamic> booking) {
    final bEvents = booking['booked_events'] as List<dynamic>? ?? [];
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF13131D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("ORDER #${booking['id']}", style: GoogleFonts.plusJakartaSans(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                Text("₹${booking['total_amount']}", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          ...bEvents.map((be) => _buildEventSegment(context, be)),
        ],
      ),
    );
  }

  Widget _buildEventSegment(BuildContext context, Map<String, dynamic> be) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(be['event_name']?.toString().toUpperCase() ?? "EVENT", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text("${be['participants_count']} TICKETS", style: GoogleFonts.plusJakartaSans(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => context.push('/ticket/${be['id']}'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
              textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
            child: const Text("VIEW TICKET"),
          ),
        ],
      ),
    );
  }
}
