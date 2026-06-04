import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/bookings_provider.dart';
import '../../domain/models/slot_info.dart';
import '../../../events/presentation/providers/events_provider.dart';
import '../../../events/presentation/providers/event_details_provider.dart';
import '../../../../shared/widgets/app_cached_image.dart';

class BookingsPage extends ConsumerStatefulWidget {
  final int? initialTab;
  const BookingsPage({super.key, this.initialTab});

  @override
  ConsumerState<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends ConsumerState<BookingsPage> {
  int _selectedSegment = 0; // 0 = Upcoming, 1 = Past

  @override
  void initState() {
    super.initState();
    if (widget.initialTab != null) {
      _selectedSegment = widget.initialTab!;
    }
  }

  @override
  void didUpdateWidget(covariant BookingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != null && widget.initialTab != oldWidget.initialTab) {
      _selectedSegment = widget.initialTab!;
    }
  }

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

  String formatEventDateShort(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'TBA';
    try {
      final dt = DateTime.tryParse(dateStr);
      if (dt != null) {
        final months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
      }
    } catch (_) {}
    return dateStr;
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(myBookingsProvider);
    final eventsAsync = ref.watch(eventsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'My Passes',
          style: GoogleFonts.breeSerif(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          bookingsAsync.maybeWhen(
            data: (bookings) => (bookings.isNotEmpty && bookings.first['is_offline'] == true)
                ? Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orangeAccent),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'OFFLINE MODE',
                      style: TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  )
                : const SizedBox(),
            orElse: () => const SizedBox(),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Segment Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Container(
                height: 55,
                decoration: BoxDecoration(
                  color: const Color(0xFF16151A),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedSegment = 0),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _selectedSegment == 0 ? const Color(0xFFFECF65) : Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            'Upcoming Passes',
                            style: GoogleFonts.breeSerif(
                              color: _selectedSegment == 0 ? Colors.black : Colors.white38,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedSegment = 1),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _selectedSegment == 1 ? const Color(0xFFFECF65) : Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            'Past Passes',
                            style: GoogleFonts.breeSerif(
                              color: _selectedSegment == 1 ? Colors.black : Colors.white38,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Passes List
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFFFECF65),
                backgroundColor: const Color(0xFF16151A),
                onRefresh: () async => ref.invalidate(myBookingsProvider),
                child: bookingsAsync.when(
                  data: (bookings) {
                    // flatMap booking orders to individual booked events
                    final List<Map<String, dynamic>> bookedEvents = [];
                    for (var booking in bookings) {
                      final items = booking['booked_events'] as List<dynamic>? ?? [];
                      for (var item in items) {
                        bookedEvents.add({
                          ...item,
                          'booking_id': booking['id'],
                          'booking_reference': '#EVT-${booking['id']}',
                          'total_amount': booking['total_amount'],
                          'is_offline': booking['is_offline'],
                        });
                      }
                    }

                    // Filter into upcoming and past based on date
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);

                    final upcoming = bookedEvents.where((e) {
                      final slotInfo = SlotInfo.tryParse(e['slot_info']);
                      if (slotInfo?.date == null) return true; // Default to upcoming if no date
                      final eventDate = DateTime.tryParse(slotInfo!.date!);
                      if (eventDate == null) return true;
                      return !eventDate.isBefore(today);
                    }).toList();

                    final past = bookedEvents.where((e) {
                      final slotInfo = SlotInfo.tryParse(e['slot_info']);
                      if (slotInfo?.date == null) return false;
                      final eventDate = DateTime.tryParse(slotInfo!.date!);
                      if (eventDate == null) return false;
                      return eventDate.isBefore(today);
                    }).toList();

                    final activeList = _selectedSegment == 0 ? upcoming : past;

                    if (activeList.isEmpty) {
                      return ListView(
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                          const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.confirmation_number_outlined,
                                  color: Colors.white24,
                                  size: 80,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No passes found',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }

                    final eventsList = eventsAsync.valueOrNull ?? [];

                    return ListView.builder(
                      padding: const EdgeInsets.all(20).copyWith(bottom: 120),
                      itemCount: activeList.length,
                      itemBuilder: (context, index) {
                        final eventItem = activeList[index];

                        // Find matching event from catalog for image/price details
                        final eventName = eventItem['event_name'] ?? 'Unknown Event';
                        final eventMatch = eventsList.where((e) {
                          return e.title.toLowerCase() == eventName.toString().toLowerCase();
                        }).firstOrNull;

                        final imageKey = eventItem['event_image'] ?? eventItem['image_key'] ?? eventMatch?.bannerImage;
                        final price = eventMatch?.price ?? eventItem['line_total'] ?? 0;

                        return GestureDetector(
                          onTap: () {
                            final id = eventItem['id'];
                            if (id != null) context.push('/ticket/$id');
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16151A),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Banner image with floating badges
                                Stack(
                                  children: [
                                    AppCachedImage(
                                      imageKey: imageKey,
                                      height: 160,
                                      borderRadius: 0,
                                      fit: BoxFit.cover,
                                    ),
                                    // Overlay gradient
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.black.withOpacity(0.4),
                                              Colors.transparent,
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Floating badges
                                    Positioned(
                                      top: 12,
                                      left: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _selectedSegment == 0 ? const Color(0xFF3B82F6) : Colors.white30,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _selectedSegment == 0 ? 'UPCOMING' : 'PAST',
                                          style: GoogleFonts.breeSerif(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 12,
                                      right: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFECF65),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          price > 0 ? '₹${price.toStringAsFixed(0)}' : 'Free',
                                          style: GoogleFonts.breeSerif(
                                            color: Colors.black,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Event Details
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              eventName,
                                              style: GoogleFonts.breeSerif(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            eventItem['booking_reference'] ?? '',
                                            style: GoogleFonts.breeSerif(
                                              color: const Color(0xFFFECF65),
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      // Date & Time
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today_outlined, color: Colors.white38, size: 14),
                                          const SizedBox(width: 6),
                                          Text(
                                            formatEventDateShort(_getDateText(eventItem['slot_info'])),
                                            style: GoogleFonts.breeSerif(
                                              color: Colors.white70,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          const Icon(Icons.access_time, color: Colors.white38, size: 14),
                                          const SizedBox(width: 6),
                                          Text(
                                            _getTimeText(eventItem['slot_info']),
                                            style: GoogleFonts.breeSerif(
                                              color: Colors.white70,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      // Venue
                                      Consumer(
                                        builder: (context, ref, child) {
                                          final detailsAsync = ref.watch(eventDetailsDataProvider(eventMatch?.id.toString() ?? ''));
                                          final venue = detailsAsync.valueOrNull?['venue']?.toString() ?? 'TBA';
                                          return Row(
                                            children: [
                                              const Icon(Icons.location_on_outlined, color: Colors.white38, size: 14),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  venue,
                                                  style: GoogleFonts.breeSerif(
                                                    color: Colors.white70,
                                                    fontSize: 13,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      const Divider(color: Colors.white10),
                                      const SizedBox(height: 4),

                                      // Attendees row
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 12,
                                            backgroundColor: Colors.white12,
                                            child: const Icon(
                                              Icons.person,
                                              color: Colors.white54,
                                              size: 14,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${eventItem['participants_count'] ?? 1} Attendee(s)',
                                            style: GoogleFonts.breeSerif(
                                              color: Colors.white38,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
                          'Error loading bookings',
                          style: GoogleFonts.breeSerif(color: Colors.white),
                        ),
                        TextButton(
                          onPressed: () => ref.invalidate(myBookingsProvider),
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
            ),
          ],
        ),
      ),
    );
  }

  String _getDateText(dynamic rawSlotInfo) {
    final slotInfo = SlotInfo.tryParse(rawSlotInfo);
    return slotInfo?.date ?? '';
  }

  String _getTimeText(dynamic rawSlotInfo) {
    final slotInfo = SlotInfo.tryParse(rawSlotInfo);
    if (slotInfo?.startTime != null) {
      return formatTimeHHMM(slotInfo!.startTime);
    }
    return 'General Slot';
  }
}
