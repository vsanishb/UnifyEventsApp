import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/cart_provider.dart';
import '../../../events/presentation/providers/events_provider.dart';
import '../../../events/presentation/providers/event_details_provider.dart';

class CheckoutPage extends ConsumerWidget {
  const CheckoutPage({super.key});

  @override
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartDataProvider);

    return cartAsync.when(
      data: (cartData) {
        num grandTotal = 0;
        final eventsAsync = ref.watch(eventsProvider);
        final items = cartData['items'] as List<dynamic>? ?? [];

        for (var item in items) {
          final itemId = item['id'];
          final tempBookingsAsync = ref.watch(tempBookingsProvider(itemId));
          final bookingsCount =
              tempBookingsAsync.valueOrNull?.length ??
              item['participants_count'] ??
              1;

          String eventId = '';
          if (item['event_id'] != null) {
            eventId = item['event_id'].toString();
          } else if (item['event'] is int) {
            eventId = item['event'].toString();
          } else if (item['event'] is Map) {
            eventId = item['event']['id'].toString();
          }

          num basePrice = 0;
          if (item['event_price'] != null) {
            basePrice = num.tryParse(item['event_price'].toString()) ?? 0;
          } else if (item['price'] != null) {
            basePrice = num.tryParse(item['price'].toString()) ?? 0;
          } else if (item['event'] is Map) {
            basePrice =
                num.tryParse(
                  item['event']['price']?.toString() ??
                      item['event']['fee']?.toString() ??
                      '0',
                ) ??
                0;
          } else if (eventsAsync.valueOrNull != null) {
            final eventMatch = eventsAsync.value!
                .where((e) => e.id.toString() == eventId)
                .firstOrNull;
            if (eventMatch != null) basePrice = eventMatch.price ?? 0;
          }

          grandTotal += basePrice * bookingsCount;
        }

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'Checkout Summary',
              style: GoogleFonts.breeSerif(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            backgroundColor: Colors.black,
            elevation: 0,
            centerTitle: true,
          ),
          body: SafeArea(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      "Your cart is empty",
                      style: GoogleFonts.breeSerif(color: Colors.white54, fontSize: 18),
                    ),
                  )
                : CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((context, index) {
                            return CheckoutItemCard(item: items[index]);
                          }, childCount: items.length),
                        ),
                      ),
                      const SliverPadding(
                        padding: EdgeInsets.only(bottom: 24),
                      ),
                    ],
                  ),
          ),
          bottomNavigationBar: items.isEmpty
              ? null
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border(
                      top: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'TOTAL AMOUNT',
                              style: GoogleFonts.breeSerif(
                                color: Colors.white38,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${grandTotal.toStringAsFixed(2)}',
                              style: GoogleFonts.breeSerif(
                                color: const Color(0xFFFECF65),
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 200,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFECF65),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            context.push('/payment', extra: grandTotal);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Proceed to Payment',
                                style: GoogleFonts.breeSerif(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFECF65)),
        ),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Error loading checkout',
            style: GoogleFonts.breeSerif(color: Colors.redAccent),
          ),
        ),
      ),
    );
  }
}

class CheckoutItemCard extends ConsumerWidget {
  final Map<String, dynamic> item;

  const CheckoutItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String eventName = 'Unknown Event';
    if (item['event_name'] != null) {
      eventName = item['event_name'];
    } else if (item['event'] is Map) {
      eventName = item['event']['name'] ?? 'Unknown Event';
    }

    String eventId = '';
    if (item['event_id'] != null) {
      eventId = item['event_id'].toString();
    } else if (item['event'] is int) {
      eventId = item['event'].toString();
    } else if (item['event'] is Map) {
      eventId = item['event']['id'].toString();
    }

    num basePrice = 0;
    if (item['event_price'] != null) {
      basePrice = num.tryParse(item['event_price'].toString()) ?? 0;
    } else if (item['price'] != null) {
      basePrice = num.tryParse(item['price'].toString()) ?? 0;
    } else if (item['event'] is Map) {
      basePrice =
          num.tryParse(
            item['event']['price']?.toString() ??
                item['event']['fee']?.toString() ??
                '0',
          ) ??
          0;
    }

    final itemId = item['id'];

    final tempBookingsAsync = ref.watch(tempBookingsProvider(itemId));
    final tempTimeslotsAsync = ref.watch(tempTimeslotsProvider(itemId));
    final slotsAsync = ref.watch(slotsProvider(eventId));

    final bookingsCount =
        tempBookingsAsync.valueOrNull?.length ??
        item['participants_count'] ??
        1;
    final itemTotal = basePrice * bookingsCount;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF16151A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    eventName,
                    style: GoogleFonts.breeSerif(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '₹$itemTotal (${bookingsCount} × ₹$basePrice)',
                  style: GoogleFonts.breeSerif(
                    color: const Color(0xFFFECF65),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          // Slot Details
          tempTimeslotsAsync.when(
            data: (tempSlots) {
              if (tempSlots.isEmpty) return const SizedBox();
              final selectedSlotId = tempSlots.first['slot'];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: slotsAsync.when(
                  data: (slots) {
                    try {
                      final matchingSlot = slots.firstWhere(
                        (s) => s.id == selectedSlotId,
                      );
                      return Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Colors.white54,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${matchingSlot.startTime} - ${matchingSlot.endTime}',
                            style: GoogleFonts.breeSerif(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      );
                    } catch (_) {
                      return Text(
                        'Slot selected but unavailable',
                        style: GoogleFonts.breeSerif(color: Colors.white54, fontSize: 14),
                      );
                    }
                  },
                  loading: () => Text(
                    'Loading slot details...',
                    style: GoogleFonts.breeSerif(color: Colors.white54, fontSize: 14),
                  ),
                  error: (_, __) => Text(
                    'Error loading slot',
                    style: GoogleFonts.breeSerif(color: Colors.white54, fontSize: 14),
                  ),
                ),
              );
            },
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
          tempBookingsAsync.when(
            data: (bookings) {
              if (bookings.isEmpty) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: bookings
                      .map(
                        (booking) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.person,
                                color: Colors.white54,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                booking['name'] ?? 'Participant',
                                style: GoogleFonts.breeSerif(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              );
            },
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
    );
  }
}
