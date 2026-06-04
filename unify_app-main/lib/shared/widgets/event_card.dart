import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../features/events/domain/models/event_model.dart';
import '../../../features/events/presentation/providers/event_details_provider.dart';

import '../../core/utils/datetime_utils.dart';
import 'app_cached_image.dart';

class EventCard extends ConsumerWidget {
  final EventModel event;
  final bool isFeatured;

  const EventCard({
    super.key,
    required this.event,
    this.isFeatured = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(eventDetailsDataProvider(event.id.toString()));
    final slotsAsync = ref.watch(slotsProvider(event.id.toString()));

    final venue = detailsAsync.valueOrNull?['venue']?.toString() ?? 'Venue TBA';
    final dt = EventDateTimeHelper.getEventDateTime(
      serializerDate: event.date,
      details: detailsAsync.valueOrNull,
      slots: slotsAsync.valueOrNull,
    );
    final displayDate = dt['date'] ?? 'Date TBA';
    final displayTime = dt['time'] ?? 'Time TBA';

    final priceStr = event.price != null && event.price! > 0
        ? "₹${event.price!.toStringAsFixed(0)}"
        : "Free";

    return GestureDetector(
      onTap: () => context.push('/event-details/${event.id}'),
      child: Container(
        width: 240,
        height: 250,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF16151A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.04),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Upper Portion: Image (Height: 130)
            SizedBox(
              height: 130,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: AppCachedImage(
                      imageKey: event.bannerImage,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (isFeatured)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFECF65),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "FEATURED",
                          style: GoogleFonts.breeSerif(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Lower Portion: Text Metadata
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.breeSerif(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Location (Venue)
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 12, color: Color(0xFFFECF65)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            venue,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.breeSerif(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Date / Time and Price Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 11, color: Colors.white30),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  displayDate,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.breeSerif(
                                    color: Colors.white38,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.access_time_rounded, size: 11, color: Colors.white30),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  displayTime,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.breeSerif(
                                    color: Colors.white38,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          priceStr,
                          style: GoogleFonts.breeSerif(
                            color: const Color(0xFFFECF65),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
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
    );
  }
}
