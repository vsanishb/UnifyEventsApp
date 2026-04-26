import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/cart_provider.dart';

class CheckoutPage extends ConsumerWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartDataProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("CHECKOUT", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: cartAsync.when(
        data: (cartData) {
          final items = cartData['items'] as List<dynamic>? ?? [];
          if (items.isEmpty) return const Center(child: Text("NO ITEMS TO CHECKOUT"));

          num total = 0;
          for (var item in items) {
            total += (item['price'] ?? 0) * (item['participants_count'] ?? 1);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("ORDER SUMMARY", style: GoogleFonts.plusJakartaSans(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2)),
                const SizedBox(height: 16),
                ...items.map((item) => _buildSummaryItem(item)),
                const Divider(color: Colors.white10, height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("TOTAL AMOUNT", style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontWeight: FontWeight.bold)),
                    Text("₹$total", style: GoogleFonts.jetBrainsMono(color: const Color(0xFF39FF14), fontSize: 24, fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.push('/payment', extra: total),
                    child: const Text("PAY NOW"),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("ERROR: $err")),
      ),
    );
  }

  Widget _buildSummaryItem(Map<String, dynamic> item) {
    final event = item['full_event']?.event;
    final pCount = item['participants_count'] ?? 1;
    final price = item['price'] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event?.title.toUpperCase() ?? "UNKNOWN EVENT", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
                Text("$pCount × ₹$price", style: GoogleFonts.plusJakartaSans(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          Text("₹${price * pCount}", style: GoogleFonts.jetBrainsMono(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
