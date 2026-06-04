import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../bookings/presentation/providers/bookings_provider.dart';
import '../../../bookings/domain/models/slot_info.dart';
import '../../../../shared/widgets/app_cached_image.dart';
import '../../../events/domain/models/event_model.dart';
import '../../../events/presentation/providers/events_provider.dart';
import '../../../events/presentation/providers/event_details_provider.dart';
import '../../../../core/utils/datetime_utils.dart';

class BookingSuccessPage extends ConsumerWidget {
  final String bookingId;

  const BookingSuccessPage({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(singleBookingProvider(bookingId));
    final eventsAsync = ref.watch(eventsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: bookingAsync.when(
          data: (booking) {
            final bookedEvents = booking['booked_events'] as List<dynamic>? ?? [];
            final isOffline = booking['is_offline'] == true;
            final events = eventsAsync.valueOrNull ?? [];

            // Get first booked event for viewing single ticket fallback
            final firstEvent = bookedEvents.isNotEmpty ? bookedEvents.first : null;
            final firstBookedEventId = firstEvent?['id']?.toString() ?? bookingId;

            return Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 24),
                          // Success Checkmark Concentric Rings
                          Center(
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFFECF65).withOpacity(0.05),
                                border: Border.all(color: const Color(0xFFFECF65).withOpacity(0.1), width: 6),
                              ),
                              child: Center(
                                child: Container(
                                  width: 95,
                                  height: 95,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFFECF65).withOpacity(0.15),
                                    border: Border.all(color: const Color(0xFFFECF65).withOpacity(0.3), width: 4),
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 70,
                                      height: 70,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFFFECF65),
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.black,
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Title & Subtitle
                          Center(
                            child: Text(
                              'Booking Confirmed!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.breeSerif(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              'Payment Successful & Tickets Reserved!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.breeSerif(
                                color: const Color(0xFFFECF65),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Order Reference Section
                          Text(
                            'ORDER REFERENCE',
                            style: GoogleFonts.breeSerif(
                              color: Colors.white38,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16151A),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Order #$bookingId',
                                      style: GoogleFonts.breeSerif(
                                        color: Colors.white38,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: const Color(0xFFFECF65).withOpacity(0.5)),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '• CONFIRMED',
                                        style: GoogleFonts.breeSerif(
                                          color: const Color(0xFFFECF65),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '#EVT-$bookingId',
                                        style: GoogleFonts.breeSerif(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.copy, color: Colors.white54, size: 20),
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(text: '#EVT-$bookingId'));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Order reference copied to clipboard!',
                                              style: GoogleFonts.breeSerif(),
                                            ),
                                            backgroundColor: const Color(0xFF16151A),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const Divider(color: Colors.white10, height: 24),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time_filled, color: Colors.white38, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      isOffline ? 'Booked offline' : 'Booked on ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                                      style: GoogleFonts.breeSerif(
                                        color: Colors.white38,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(color: Colors.white10, height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.payment_rounded, color: Colors.white38, size: 16),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Total Paid',
                                          style: GoogleFonts.breeSerif(
                                            color: Colors.white38,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '₹${(booking['total_amount'] ?? booking['grand_total'] ?? 0.0).toString()}',
                                      style: GoogleFonts.breeSerif(
                                        color: const Color(0xFFFECF65),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Tickets Summary Section
                          Text(
                            'TICKETS SUMMARY',
                            style: GoogleFonts.breeSerif(
                              color: Colors.white38,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (bookedEvents.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Text(
                                  'No tickets found in this booking.',
                                  style: GoogleFonts.breeSerif(color: Colors.white30),
                                ),
                              ),
                            )
                          else
                            ...bookedEvents.map((be) => BookedEventSuccessCard(
                                  bookedEvent: be,
                                  events: events,
                                )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bottom Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16151A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: Colors.white.withOpacity(0.05)),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              context.go('/bookings');
                            },
                            child: Text(
                              'My Bookings',
                              style: GoogleFonts.breeSerif(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFECF65),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              context.push('/ticket/$firstBookedEventId');
                            },
                            child: Text(
                              'View Ticket',
                              style: GoogleFonts.breeSerif(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFFECF65)),
          ),
          error: (err, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error loading booking summary: $err',
                  style: GoogleFonts.breeSerif(color: Colors.white),
                ),
                TextButton(
                  onPressed: () => ref.invalidate(singleBookingProvider(bookingId)),
                  child: Text(
                    'RETRY',
                    style: GoogleFonts.breeSerif(color: const Color(0xFFFECF65)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BookedEventSuccessCard extends ConsumerWidget {
  final Map<String, dynamic> bookedEvent;
  final List<EventModel> events;

  const BookedEventSuccessCard({
    super.key,
    required this.bookedEvent,
    required this.events,
  });

  String formatTimeHHMM(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return 'TBA';
    try {
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
    final eventId = bookedEvent['event_id']?.toString() ?? '';
    final eventName = bookedEvent['event_name'] ?? 'Event';
    final eventMatch = events.where((e) {
      return e.id.toString() == eventId || e.title.toLowerCase() == eventName.toString().toLowerCase();
    }).firstOrNull;

    final imageKey = bookedEvent['event_image'] ?? bookedEvent['image_key'] ?? eventMatch?.bannerImage;
    final rawSlotInfo = bookedEvent['slot_info'];
    final slotInfo = SlotInfo.tryParse(rawSlotInfo);
    final participants = bookedEvent['participants'] as List<dynamic>? ?? [];

    String eventDateText = 'TBA';
    String eventTimeText = 'TBA';
    if (slotInfo != null) {
      if (slotInfo.date != null) {
        eventDateText = slotInfo.date!;
      }
      if (slotInfo.startTime != null && slotInfo.endTime != null) {
        eventTimeText = '${formatTimeHHMM(slotInfo.startTime)} - ${formatTimeHHMM(slotInfo.endTime)}';
      }
    }

    if ((eventDateText == 'TBA' || eventTimeText == 'TBA') && eventMatch != null) {
      final detailsAsync = ref.watch(eventDetailsDataProvider(eventMatch.id.toString()));
      final slotsAsync = ref.watch(slotsProvider(eventMatch.id.toString()));
      final dt = EventDateTimeHelper.getEventDateTime(
        serializerDate: eventMatch.date,
        details: detailsAsync.valueOrNull,
        slots: slotsAsync.valueOrNull,
      );
      if (eventDateText == 'TBA') {
        eventDateText = dt['date']!;
      }
      if (eventTimeText == 'TBA') {
        eventTimeText = dt['time']!;
      }
    } else if (eventMatch != null && eventMatch.date != null) {
      eventDateText = eventMatch.date!;
    }

    String venueText = 'TBA';
    if (eventMatch != null) {
      final detailsAsync = ref.watch(eventDetailsDataProvider(eventMatch.id.toString()));
      venueText = detailsAsync.valueOrNull?['venue']?.toString() ?? 'TBA';
    }

    final constraintAsync = ref.watch(constraintProvider(eventId));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16151A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: AppCachedImage(
                    imageKey: imageKey,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
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
                    const SizedBox(height: 4),
                    Text(
                      'Venue: $venueText',
                      style: GoogleFonts.breeSerif(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.white38, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '$eventDateText · $eventTimeText',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.breeSerif(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          constraintAsync.when(
            data: (c) {
              if (c == null) return const SizedBox.shrink();
              final constraintText = c.bookingType == 'single'
                  ? 'Single Participant'
                  : (c.fixed ? 'Multiple (Fixed)' : 'Multiple (Flexible)');
              final limitsText = c.bookingType == 'single'
                  ? '1'
                  : (c.fixed ? '${c.upperLimit}' : '${c.lowerLimit} - ${c.upperLimit}');
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Colors.white10, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CONSTRAINT TYPE',
                            style: GoogleFonts.breeSerif(
                              color: Colors.white38,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            constraintText,
                            style: GoogleFonts.breeSerif(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'TEAM SIZE LIMIT',
                            style: GoogleFonts.breeSerif(
                              color: Colors.white38,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            limitsText,
                            style: GoogleFonts.breeSerif(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          if (participants.isNotEmpty) ...[
            const Divider(color: Colors.white10, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ATTENDEES',
                  style: GoogleFonts.breeSerif(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  '${participants.length} Participant(s)',
                  style: GoogleFonts.breeSerif(
                    color: const Color(0xFFFECF65),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final p in participants)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, color: Color(0xFFFECF65), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      p['name'] ?? 'Attendee',
                      style: GoogleFonts.breeSerif(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
