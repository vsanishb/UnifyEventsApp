import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../events/domain/models/event_model.dart';
import '../../../events/domain/models/booking_models.dart';
import '../providers/event_details_provider.dart';
import '../providers/events_provider.dart';
import '../providers/manage_events_provider.dart';
import '../../../../shared/widgets/app_cached_image.dart';
import '../widgets/add_to_cart_flow.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../../core/utils/datetime_utils.dart';

class EventDetailPage extends ConsumerWidget {
  final String eventId;

  const EventDetailPage({super.key, required this.eventId});

  void _showAlreadyInCartOverlay(BuildContext context) {
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
                        color: const Color(0xFFFECF65).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shopping_cart_outlined,
                        color: Color(0xFFFECF65),
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'This event is already in your cart',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.breeSerif(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'You cannot add duplicate tickets for this event. You can modify your existing ticket in the cart.',
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
                          context.go('/cart');
                        },
                        child: Text(
                          'Go To Cart',
                          style: GoogleFonts.breeSerif(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Continue Browsing',
                          style: GoogleFonts.breeSerif(
                            color: Colors.white,
                            fontSize: 16,
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
  Widget build(BuildContext context, WidgetRef ref) {
    final eventList = ref.watch(eventsProvider).valueOrNull ?? [];
    final baseEvent = eventList.firstWhere(
      (e) => e.id.toString() == eventId,
      orElse: () => EventModel(
        id: int.tryParse(eventId) ?? 0,
        title: 'Loading...',
        description: '',
      ),
    );

    final detailsAsync = ref.watch(eventDetailsDataProvider(eventId));
    final constraintAsync = ref.watch(constraintProvider(eventId));
    final slotsAsync = ref.watch(slotsProvider(eventId));
    final parentEventsAsync = ref.watch(parentEventsProvider);
    final cartAsync = ref.watch(cartDataProvider);

    final isOrganiser = false; // Check role via AuthState if needed

    // Check if duplicate event exists in cart
    final cartItems = cartAsync.valueOrNull?['items'] as List<dynamic>? ?? [];
    final isAlreadyInCart = cartItems.any((item) {
      final itemEventId = item['event_id']?.toString() ??
          (item['event'] is Map ? item['event']['id']?.toString() : item['event']?.toString());
      return itemEventId == eventId;
    });

    final parentEvent = parentEventsAsync.valueOrNull?.firstWhere(
      (pe) => pe['id'] == baseEvent.parentEventId,
      orElse: () => null,
    );
    final parentEventName = parentEvent?['name'] ?? 'PhaseShift';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Events Details',
          style: GoogleFonts.breeSerif(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Banner
              Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                ),
                clipBehavior: Clip.antiAlias,
                child: AppCachedImage(
                  imageKey: baseEvent.bannerImage,
                  height: 220,
                  borderRadius: 24,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),

              // Status Row
              detailsAsync.when(
                data: (details) {
                  final startStr = details['start_datetime']?.toString() ?? baseEvent.date;
                  final endStr = details['end_datetime']?.toString();
                  final venueName = details['venue']?.toString() ?? 'Venue TBA';

                  String status = "Upcoming";
                  Color statusColor = const Color(0xFFFECF65); // gold for upcoming
                  Color textColor = Colors.black;

                  if (startStr != null) {
                    final start = DateTime.tryParse(startStr);
                    final end = endStr != null ? DateTime.tryParse(endStr) : null;
                    final now = DateTime.now();
                    if (start != null) {
                      if (now.isAfter(start)) {
                        if (end == null || now.isBefore(end)) {
                          status = "Going On";
                          statusColor = const Color(0xFFE52E50); // red for active
                          textColor = Colors.white;
                        } else {
                          status = "Completed";
                          statusColor = Colors.white30; // grey for completed
                          textColor = Colors.white70;
                        }
                      }
                    }
                  }

                  final dt = EventDateTimeHelper.getEventDateTime(
                    serializerDate: baseEvent.date,
                    details: details,
                    slots: slotsAsync.valueOrNull,
                  );
                  final timeFormatted = dt['time']!;

                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status,
                          style: GoogleFonts.breeSerif(
                            color: textColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$timeFormatted · $venueName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.breeSerif(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox(height: 25),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(height: 16),

              // Large Title
              Text(
                baseEvent.title,
                style: GoogleFonts.breeSerif(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),

              // Parent Event
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: const Color(0xFFC084FC),
                    child: const Icon(
                      Icons.stars_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    parentEventName,
                    style: GoogleFonts.breeSerif(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Information Card
              detailsAsync.when(
                data: (details) {
                  final dt = EventDateTimeHelper.getEventDateTime(
                    serializerDate: baseEvent.date,
                    details: details,
                    slots: slotsAsync.valueOrNull,
                  );
                  final dateFormatted = dt['date']!;
                  final timeFormatted = dt['time']!;
                  final venueName = details['venue']?.toString() ?? 'TBA';
                  final venueSub = details['location']?.toString() ?? '';

                  final price = baseEvent.price ?? 0;
                  final priceText = price > 0 ? '₹${price.toStringAsFixed(0)}' : 'Free';

                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16151A),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          icon: Icons.confirmation_number_outlined,
                          title: 'Event type',
                          value: priceText,
                          valueColor: const Color(0xFFFECF65),
                        ),
                        const Divider(color: Colors.white10, height: 24),
                        _buildInfoRow(
                          icon: Icons.calendar_today_outlined,
                          title: dateFormatted,
                          value: timeFormatted,
                        ),
                        const Divider(color: Colors.white10, height: 24),
                        _buildInfoRow(
                          icon: Icons.location_on_outlined,
                          title: venueName,
                          value: venueSub,
                        ),
                        if (constraintAsync.valueOrNull != null) ...[
                          const Divider(color: Colors.white10, height: 24),
                          _buildInfoRow(
                            icon: Icons.people_outline_rounded,
                            title: 'Participation constraint',
                            value: () {
                              final c = constraintAsync.valueOrNull!;
                              if (c.bookingType == 'single') return 'Single Participant';
                              if (c.fixed) return 'Multiple (Fixed Team Size of ${c.upperLimit})';
                              return 'Multiple (Flexible Team Size: Min ${c.lowerLimit} - Max ${c.upperLimit})';
                            }(),
                          ),
                        ],
                      ],
                    ),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(color: Color(0xFFFECF65)),
                  ),
                ),
                error: (_, __) => Text(
                  'Error loading info card',
                  style: GoogleFonts.breeSerif(color: Colors.redAccent),
                ),
              ),
              const SizedBox(height: 24),

              // Full Event Description
              Text(
                'About Event',
                style: GoogleFonts.breeSerif(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              detailsAsync.when(
                data: (details) {
                  final description = details['description'] ?? baseEvent.description;
                  return Text(
                    description,
                    style: GoogleFonts.breeSerif(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  );
                },
                loading: () => Text(
                  baseEvent.description,
                  style: GoogleFonts.breeSerif(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
                error: (_, __) => Text(
                  baseEvent.description,
                  style: GoogleFonts.breeSerif(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              ),

              const SizedBox(height: 120), // Padding for bottom fixed button
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        color: Colors.black,
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFECF65),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            onPressed: isOrganiser
                ? null
                : () {
                    if (isAlreadyInCart) {
                      _showAlreadyInCartOverlay(context);
                      return;
                    }

                    final constraint = constraintAsync.valueOrNull;
                    final slots = slotsAsync.valueOrNull ?? [];
                    if (constraint == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Constraints not loaded yet',
                            style: GoogleFonts.breeSerif(),
                          ),
                        ),
                      );
                      return;
                    }
                    AddToCartFlow.start(
                      context,
                      ref,
                      baseEvent,
                      constraint,
                      slots,
                    );
                  },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Book Passes',
                  style: GoogleFonts.breeSerif(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward,
                  color: Colors.black,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0E11),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFFECF65),
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.breeSerif(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.breeSerif(
                  color: valueColor ?? Colors.white54,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
