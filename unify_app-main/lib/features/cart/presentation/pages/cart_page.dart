import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/cart_provider.dart';
import '../../../../shared/widgets/app_cached_image.dart';
import '../widgets/cart_item_edit_modal.dart';
import '../../../events/presentation/providers/event_details_provider.dart';
import '../../../events/presentation/providers/events_provider.dart';
import '../../../events/domain/models/event_model.dart';
import '../../../events/domain/models/booking_models.dart';

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  bool _isCheckingOut = false;

  Future<String?> _validateCart(List<dynamic> items) async {
    final events = ref.read(eventsProvider).valueOrNull ?? [];

    for (var item in items) {
      final itemId = item['id'];
      String eventId = '';
      if (item['event_id'] != null) {
        eventId = item['event_id'].toString();
      } else if (item['event'] is int) {
        eventId = item['event'].toString();
      } else if (item['event'] is Map) {
        eventId = item['event']['id'].toString();
      }

      // backend directly aliases event_name in CartItemSerializer
      final eventName = item['event_name'] ??
          (item['event'] is Map ? item['event']['name'] : null) ??
          events.firstWhere((e) => e.id.toString() == eventId, orElse: () => EventModel(id: 0, title: 'Event', description: '')).title;

      // 1. Check slot selection
      // Reading from structural representation target 'temp_timeslot' nested within CartItemSerializer
      final tempTimeslot = item['temp_timeslot'];
      if (tempTimeslot == null) {
        return "Please select a time slot for '$eventName'.";
      }
      final selectedSlotId = tempTimeslot['slot'];

      // 2. Check slot capacity
      final slots = await ref.read(slotsProvider(eventId).future);
      final slot = slots.where((s) => s.id == selectedSlotId).firstOrNull;
      if (slot == null) {
        return "Selected slot for '$eventName' is no longer available.";
      }
      final passesCount = item['participants_count'] ?? 1;
      if (!slot.unlimitedParticipants) {
        if (slot.availableParticipants == null || slot.availableParticipants! < passesCount) {
          return "Insufficient capacity in selected slot for '$eventName' (${slot.availableParticipants} spots left).";
        }
      }

      // Check participation constraints
      final constraint = await ref.read(constraintProvider(eventId).future);
      if (constraint != null) {
        if (constraint.bookingType == 'single') {
          if (passesCount != 1) {
            return "'$eventName' is restricted to a single participant. Please edit the count.";
          }
        } else if (constraint.bookingType == 'multiple') {
          if (constraint.fixed) {
            if (passesCount != constraint.upperLimit) {
              return "'$eventName' requires a fixed team size of exactly ${constraint.upperLimit} participants.";
            }
          } else {
            if (passesCount < constraint.lowerLimit || passesCount > constraint.upperLimit) {
              return "'$eventName' requires a team size between ${constraint.lowerLimit} and ${constraint.upperLimit} participants.";
            }
          }
        }
      }

      // 3. Check participants completeness
      final participants = await ref.read(tempBookingsProvider(itemId).future);
      if (participants.length != passesCount) {
        return "Participant list size mismatch for '$eventName'. Please edit the item to add details.";
      }
      for (var i = 0; i < participants.length; i++) {
        final p = participants[i];
        final name = p['name']?.toString().trim();
        if (name == null || name.isEmpty) {
          return "Please enter full name for Attendee ${i + 1} in '$eventName'.";
        }
      }
    }
    return null; // All valid
  }

  void _showValidationErrorDialog(String message) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, _, __) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.redAccent,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Checkout Blocked',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.breeSerif(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.breeSerif(
                        color: Colors.white54,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFECF65),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Go Back & Edit',
                          style: GoogleFonts.breeSerif(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartDataProvider);

    return cartAsync.when(
      data: (cartData) {
        num subtotal = 0;
        final eventsAsync = ref.watch(eventsProvider);
        final items = cartData['items'] as List<dynamic>? ?? [];

        // Compute Subtotal
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
            // Priority 1: direct field value from serialiser
            basePrice = num.tryParse(item['event_price'].toString()) ?? 0;
          } else if (item['price'] != null) {
            basePrice = num.tryParse(item['price'].toString()) ?? 0;
          } else if (item['event'] is Map) {
            basePrice = num.tryParse(
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

          subtotal += basePrice * bookingsCount;
        }

        // Sum dynamic ticket count
        final totalTickets = items.fold<int>(0, (sum, item) {
          final itemId = item['id'];
          final tempBookingsAsync = ref.read(tempBookingsProvider(itemId));
          final count = tempBookingsAsync.valueOrNull?.length ?? item['participants_count'] ?? 1;
          return sum + (count as int);
        });

        final grandTotal = subtotal;

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            title: Text(
              'My Cart',
              style: GoogleFonts.breeSerif(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            actions: [
              if (items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: TextButton(
                    onPressed: () async {
                      for (var item in items) {
                        await ref.read(cartActionProvider).removeCartItem(item['id']);
                      }
                      ref.invalidate(cartDataProvider);
                    },
                    child: Text(
                      'Clear All',
                      style: GoogleFonts.breeSerif(
                        color: const Color(0xFFFECF65),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: SafeArea(
            child: RefreshIndicator(
                  color: const Color(0xFFFECF65),
                  backgroundColor: const Color(0xFF16151A),
                  onRefresh: () async => ref.invalidate(cartDataProvider),
                  child: items.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                            Center(
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.shopping_cart_outlined,
                                    color: Colors.white24,
                                    size: 80,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Your cart is empty',
                                    style: GoogleFonts.breeSerif(
                                      color: Colors.white54,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : CustomScrollView(
                          slivers: [
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                                child: Text(
                                  '$totalTickets ${totalTickets == 1 ? 'ticket' : 'tickets'} selected',
                                  style: GoogleFonts.breeSerif(
                                    color: Colors.white54,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  return CartItemCard(item: items[index]);
                                }, childCount: items.length),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0).copyWith(
                                  bottom: 24.0,
                                ),
                                padding: const EdgeInsets.all(20.0),
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
                                      'BILLING SUMMARY',
                                      style: GoogleFonts.breeSerif(
                                        color: Colors.white38,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Subtotal',
                                          style: GoogleFonts.breeSerif(
                                            color: Colors.white70,
                                            fontSize: 15,
                                          ),
                                        ),
                                        Text(
                                          '₹${subtotal.toStringAsFixed(2)}',
                                          style: GoogleFonts.breeSerif(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const Divider(color: Colors.white10, height: 28),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Total Paid',
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
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
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
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '₹${grandTotal.toStringAsFixed(2)}',
                                  style: GoogleFonts.breeSerif(
                                    color: const Color(0xFFFECF65),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '($totalTickets ${totalTickets == 1 ? 'ticket' : 'tickets'})',
                                    style: GoogleFonts.breeSerif(
                                      color: Colors.white38,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 150, // Slightly reduced to avoid button text overflow risks
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFECF65),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _isCheckingOut
                              ? null
                              : () async {
                                  setState(() => _isCheckingOut = true);
                                  try {
                                    final errorMsg = await _validateCart(items);
                                    if (errorMsg != null) {
                                      _showValidationErrorDialog(errorMsg);
                                    } else {
                                      context.push('/checkout');
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Validation failed: $e',
                                          style: GoogleFonts.breeSerif(),
                                        ),
                                      ),
                                    );
                                  } finally {
                                    setState(() => _isCheckingOut = false);
                                  }
                                },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isCheckingOut)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                                )
                              else ...[
                                Text(
                                  'Checkout',
                                  style: GoogleFonts.breeSerif(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 16),
                              ]
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading cart',
                style: GoogleFonts.breeSerif(color: Colors.white),
              ),
              TextButton(
                onPressed: () => ref.invalidate(cartDataProvider),
                child: Text(
                  'RETRY',
                  style: GoogleFonts.breeSerif(color: const Color(0xFFFECF65)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CartItemCard extends ConsumerWidget {
  final Map<String, dynamic> item;

  const CartItemCard({super.key, required this.item});

  String formatEventDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'TBA';
    try {
      final dt = DateTime.tryParse(dateStr);
      if (dt != null) {
        final weekDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        final months = [
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December'
        ];
        return '${weekDays[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}';
      }
    } catch (_) {}
    return dateStr;
  }

  String formatTimeString(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return 'TBA';
    try {
      // Fix: If backend provides a pure time format like HH:MM or HH:MM:SS
      if (timeStr.contains(':') && !timeStr.contains('-') && !timeStr.contains('T')) {
        final parts = timeStr.split(':');
        final hours = int.parse(parts[0]);
        final minutes = int.parse(parts[1]);
        final period = hours >= 12 ? 'PM' : 'AM';
        final displayHour = hours > 12 ? hours - 12 : (hours == 0 ? 12 : hours);
        return '${displayHour.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')} $period';
      }

      final dt = DateTime.tryParse(timeStr);
      if (dt != null) {
        final hour = dt.hour;
        final minute = dt.minute;
        final period = hour >= 12 ? 'PM' : 'AM';
        final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        return '${h.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
      }
    } catch (_) {}
    return timeStr;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Priority mapping for aliased event data fields matching CartItemSerializer
    String eventName = item['event_name'] ?? 'Unknown Event';
    if (eventName == 'Unknown Event' && item['event'] is Map) {
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

    final itemId = item['id'];

    final tempBookingsAsync = ref.watch(tempBookingsProvider(itemId));
    final slotsAsync = ref.watch(slotsProvider(eventId));
    final constraintAsync = ref.watch(constraintProvider(eventId));
    final eventsAsync = ref.watch(eventsProvider);

    final eventMatch = eventsAsync.valueOrNull
        ?.where((e) => e.id.toString() == eventId)
        .firstOrNull;
    final imageKey = item['event_image'] ?? item['image_key'] ?? eventMatch?.bannerImage;

    num basePrice = 0;
    if (item['event_price'] != null) {
      basePrice = num.tryParse(item['event_price'].toString()) ?? 0;
    } else if (item['price'] != null) {
      basePrice = num.tryParse(item['price'].toString()) ?? 0;
    } else if (item['event'] is Map) {
      basePrice = num.tryParse(
            item['event']['price']?.toString() ??
                item['event']['fee']?.toString() ??
                '0',
          ) ??
          0;
    } else if (eventMatch != null) {
      basePrice = eventMatch.price ?? 0;
    }

    final bookingsCount =
        tempBookingsAsync.valueOrNull?.length ??
        item['participants_count'] ??
        1;
    final itemTotal = basePrice * bookingsCount;

    // Slot logic extraction matching the 'temp_timeslot' mapping dictionary payload structure
    Map<String, dynamic>? selectedSlotInfo;
    if (item['temp_timeslot'] != null) {
      selectedSlotInfo = item['temp_timeslot']['slot_info'];
    }

    final dateText = selectedSlotInfo?['date'] != null
        ? formatEventDate(selectedSlotInfo!['date'])
        : (eventMatch?.date != null ? formatEventDate(eventMatch!.date) : 'TBA');

    final timeText = (selectedSlotInfo?['start_time'] != null && selectedSlotInfo?['end_time'] != null)
        ? '${formatTimeString(selectedSlotInfo!['start_time'])} - ${formatTimeString(selectedSlotInfo['end_time'])}'
        : (eventMatch?.date != null ? formatTimeString(eventMatch!.date) : 'TBA');

    final detailsAsync = ref.watch(eventDetailsDataProvider(eventId));
    final venueText = detailsAsync.valueOrNull?['venue']?.toString() ?? 'TBA';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => CartItemEditModal(item: item),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: AppCachedImage(
                      imageKey: imageKey,
                      borderRadius: 16,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Main metadata panel wrapper
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eventName,
                        style: GoogleFonts.breeSerif(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Calendar row with overflow defenses
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2.0),
                            child: Icon(Icons.calendar_today_outlined, size: 14, color: Colors.white30),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              dateText,
                              style: GoogleFonts.breeSerif(color: Colors.white54, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Location row with overflow defenses
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2.0),
                            child: Icon(Icons.location_on_outlined, size: 14, color: Colors.white30),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              venueText,
                              style: GoogleFonts.breeSerif(color: Colors.white54, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Time row with overflow defenses
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2.0),
                            child: Icon(Icons.access_time, size: 14, color: Colors.white30),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              timeText,
                              style: GoogleFonts.breeSerif(color: Colors.white54, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Passes Count row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2.0),
                            child: Icon(Icons.people_outline, size: 14, color: Colors.white30),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$bookingsCount ${bookingsCount == 1 ? 'pass' : 'passes'}',
                              style: GoogleFonts.breeSerif(color: Colors.white54, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      constraintAsync.when(
                        data: (constraint) {
                          if (constraint == null) return const SizedBox();
                          String label = "Single Participant";
                          if (constraint.bookingType == 'multiple') {
                            if (constraint.fixed) {
                              label = "Multiple (Fixed: ${constraint.upperLimit})";
                            } else {
                              label = "Multiple (Team: ${constraint.lowerLimit}-${constraint.upperLimit})";
                            }
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2.0),
                                  child: Icon(Icons.info_outline_rounded, size: 14, color: Colors.white30),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    label,
                                    style: GoogleFonts.breeSerif(color: Colors.white54, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        loading: () => const SizedBox(),
                        error: (_, __) => const SizedBox(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                  onPressed: () async {
                    await ref.read(cartActionProvider).removeCartItem(itemId);
                    ref.invalidate(cartDataProvider);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Actions & pricing row wrapper
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${itemTotal.toStringAsFixed(2)}',
                  style: GoogleFonts.breeSerif(
                    color: const Color(0xFFFECF65),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),

                // Quantity Pill Selector Box
                constraintAsync.when(
                  data: (constraint) {
                    if (constraint == null) return const SizedBox();
                    final bool isFixed = constraint.fixed;
                    final bool isSingle = constraint.bookingType == 'single';

                    final bool canDecrement = !isSingle && !isFixed && bookingsCount > constraint.lowerLimit;
                    final bool canIncrement = !isSingle && !isFixed && bookingsCount < constraint.upperLimit;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1D24),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: canDecrement
                                ? () async {
                                    final newCount = bookingsCount - 1;
                                    await ref.read(cartActionProvider).updateCartItem(itemId, {
                                      'participants_count': newCount,
                                    });
                                    final bookings = tempBookingsAsync.valueOrNull ?? [];
                                    if (bookings.isNotEmpty) {
                                      await ref.read(cartActionProvider).removeParticipant(bookings.last['id']);
                                    }
                                    ref.invalidate(cartDataProvider);
                                    ref.invalidate(tempBookingsProvider(itemId));
                                  }
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.remove,
                                size: 16,
                                color: canDecrement ? const Color(0xFFFECF65) : Colors.white24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$bookingsCount',
                            style: GoogleFonts.breeSerif(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: canIncrement
                                ? () async {
                                    final newCount = bookingsCount + 1;
                                    await ref.read(cartActionProvider).updateCartItem(itemId, {
                                      'participants_count': newCount,
                                    });
                                    await ref.read(cartActionProvider).addParticipant({
                                      'cart_item': itemId,
                                      'name': '',
                                      'email': '',
                                      'phone': '',
                                    });
                                    ref.invalidate(cartDataProvider);
                                    ref.invalidate(tempBookingsProvider(itemId));
                                  }
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.add,
                                size: 16,
                                color: canIncrement ? const Color(0xFFFECF65) : Colors.white24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}