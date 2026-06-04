import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';

import '../providers/cart_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../bookings/presentation/providers/bookings_provider.dart';

class PaymentPage extends ConsumerStatefulWidget {
  final num totalAmount;

  const PaymentPage({super.key, required this.totalAmount});

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  bool _isProcessing = false;
  String _selectedPaymentMethod = "simulated";

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.breeSerif(color: Colors.white)),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _handlePayment() async {
    setState(() => _isProcessing = true);

    try {
      final cartState = ref.read(cartDataProvider);
      final cartData = cartState.valueOrNull;

      if (cartData == null ||
          cartData['items'] == null ||
          (cartData['items'] as List).isEmpty) {
        throw "Your cart is empty or could not be loaded.";
      }

      final items = cartData['items'] as List;
      for (final item in items) {
        final itemId = item['id'];

        final timeslots = await ref.read(tempTimeslotsProvider(itemId).future);
        if (timeslots.isEmpty) {
          throw "Slot not selected for ${item['event_name'] ?? 'an event'}";
        }

        final tempBookings = await ref.read(
          tempBookingsProvider(itemId).future,
        );
        final pCount = item['participants_count'] ?? 1;

        if (tempBookings.length != pCount) {
          throw "Participants incomplete for ${item['event_name'] ?? 'an event'}";
        }
      }

      // API CALL
      final dio = ref.read(dioProvider);
      final res = await dio.post("/bookings/place/");

      final bookingId = res.data["id"];

      // Clear cart and invalidate bookings list
      ref.invalidate(cartDataProvider);
      ref.invalidate(myBookingsProvider);

      if (mounted) {
        context.go("/booking-success/$bookingId");
      }
    } catch (e) {
      if (e is DioError) {
        _showError(
          e.response?.data?.toString() ??
              e.message ??
              "Network error placing booking",
        );
      } else {
        _showError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final grandTotal = widget.totalAmount;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => _isProcessing ? null : context.pop(),
        ),
        title: Text(
          'Secure Payment',
          style: GoogleFonts.breeSerif(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Price Breakdown Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF16151A),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Price Breakdown',
                      style: GoogleFonts.breeSerif(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Subtotal',
                          style: GoogleFonts.breeSerif(color: Colors.white70, fontSize: 15),
                        ),
                        Text(
                          '₹${widget.totalAmount.toStringAsFixed(2)}',
                          style: GoogleFonts.breeSerif(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(color: Colors.white10, height: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Grand Total',
                          style: GoogleFonts.breeSerif(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '₹${grandTotal.toStringAsFixed(2)}',
                          style: GoogleFonts.breeSerif(
                            color: const Color(0xFFFECF65),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Payment Method',
                style: GoogleFonts.breeSerif(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Method: Simulated Gateway
              _buildPaymentMethodTile(
                id: "simulated",
                title: "Simulated Gateway (Fast Test)",
                icon: Icons.flash_on_rounded,
              ),
              const SizedBox(height: 10),

              // Method: UPI
              _buildPaymentMethodTile(
                id: "upi",
                title: "UPI (Google Pay, PhonePe, BHIM)",
                icon: Icons.bolt_rounded,
              ),
              const SizedBox(height: 10),

              // Method: Credit/Debit Card
              _buildPaymentMethodTile(
                id: "card",
                title: "Credit or Debit Card",
                icon: Icons.credit_card_rounded,
              ),
              const SizedBox(height: 20),

              // Conditional Display depending on selected method
              if (_selectedPaymentMethod == "upi") ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16151A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFECF65).withOpacity(0.3), width: 1.5),
                  ),
                  child: TextField(
                    style: GoogleFonts.breeSerif(color: Colors.white),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "username@okhdfcbank",
                      hintStyle: GoogleFonts.breeSerif(color: Colors.white30),
                      icon: const Icon(Icons.alternate_email_rounded, color: Color(0xFFFECF65)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ] else if (_selectedPaymentMethod == "card") ...[
                Container(
                  height: 170,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E2C38), Color(0xFF16151A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFECF65).withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "UNIFY PREMIUM PASS",
                            style: GoogleFonts.breeSerif(color: Colors.white60, fontSize: 12, letterSpacing: 1.5),
                          ),
                          const Icon(Icons.credit_card, color: Color(0xFFFECF65), size: 28),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        "••••  ••••  ••••  4321",
                        style: GoogleFonts.breeSerif(color: Colors.white, fontSize: 20, letterSpacing: 2.0),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("CARD HOLDER", style: GoogleFonts.breeSerif(color: Colors.white30, fontSize: 8)),
                              const SizedBox(height: 4),
                              Text("ANISH S", style: GoogleFonts.breeSerif(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("EXPIRES", style: GoogleFonts.breeSerif(color: Colors.white30, fontSize: 8)),
                              const SizedBox(height: 4),
                              Text("08/30", style: GoogleFonts.breeSerif(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
          ),
        ),
        child: SizedBox(
          height: 55,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFECF65),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              disabledBackgroundColor: const Color(0xFFFECF65).withOpacity(0.5),
              elevation: 0,
            ),
            onPressed: _isProcessing ? null : _handlePayment,
            child: _isProcessing
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.black,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Pay ₹${grandTotal.toStringAsFixed(0)} Securely',
                    style: GoogleFonts.breeSerif(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile({
    required String id,
    required String title,
    required IconData icon,
  }) {
    final isSelected = _selectedPaymentMethod == id;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = id;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF16151A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFFECF65) : Colors.white.withOpacity(0.08),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFFECF65) : Colors.white54,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.breeSerif(
                  color: Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            Radio(
              value: id,
              groupValue: _selectedPaymentMethod,
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedPaymentMethod = val;
                  });
                }
              },
              activeColor: const Color(0xFFFECF65),
            ),
          ],
        ),
      ),
    );
  }
}
