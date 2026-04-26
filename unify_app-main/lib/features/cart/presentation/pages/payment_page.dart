import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';

import '../providers/cart_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class PaymentPage extends ConsumerStatefulWidget {
  final num totalAmount;
  const PaymentPage({super.key, required this.totalAmount});

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  bool _isProcessing = false;

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  void _handlePayment() async {
    setState(() => _isProcessing = true);
    try {
      final cartState = ref.read(cartDataProvider);
      final cartData = cartState.valueOrNull;

      if (cartData == null || cartData['items'] == null || (cartData['items'] as List).isEmpty) {
        throw "Your cart is empty or could not be loaded.";
      }

      final items = cartData['items'] as List;
      for (final item in items) {
        final itemId = item['id'];
        final timeslots = await ref.read(tempTimeslotsProvider(itemId).future);
        if (timeslots.isEmpty) throw "Slot not selected for ${item['event_name'] ?? 'an event'}";

        final tempBookings = await ref.read(tempBookingsProvider(itemId).future);
        final pCount = item['participants_count'] ?? 1;
        if (tempBookings.length != pCount) throw "Participants incomplete for ${item['event_name'] ?? 'an event'}";
      }

      final dio = ref.read(dioProvider);
      final res = await dio.post("/bookings/place/");
      final bookingId = res.data["id"];

      ref.invalidate(cartDataProvider);
      if (mounted) context.go("/booking-success/$bookingId");
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final taxes = widget.totalAmount * 0.18;
    final grandTotal = widget.totalAmount + taxes;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("PAYMENT", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF13131D),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  children: [
                    _buildPriceRow("SUBTOTAL", "₹${widget.totalAmount}"),
                    const SizedBox(height: 12),
                    _buildPriceRow("TAXES (18%)", "₹${taxes.toStringAsFixed(2)}"),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.white10)),
                    _buildPriceRow("TOTAL AMOUNT", "₹${grandTotal.toStringAsFixed(2)}", isTotal: true),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text("SELECT METHOD", style: GoogleFonts.plusJakartaSans(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF1C7C).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFF1C7C)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFFFF1C7C)),
                    const SizedBox(width: 16),
                    Text("SECURE GATEWAY", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    const Icon(Icons.check_circle, color: Color(0xFFFF1C7C)),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _handlePayment,
                  child: _isProcessing ? const CircularProgressIndicator(color: Colors.white) : const Text("CONFIRM & PAY"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(color: isTotal ? Colors.white : Colors.white38, fontSize: isTotal ? 14 : 12, fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700)),
        Text(value, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: isTotal ? 20 : 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
