import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../features/events/domain/models/event_model.dart';
import '../../../features/events/presentation/providers/event_details_provider.dart';
import '../../core/utils/datetime_utils.dart';
import 'app_cached_image.dart';

class CompactEventRow extends ConsumerWidget {
  final EventModel event;

  const CompactEventRow({
    super.key,
    required this.event,
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF16151A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.04),
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 76,
                height: 76,
                child: AppCachedImage(
                  imageKey: event.bannerImage,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.breeSerif(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
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
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 11, color: Colors.white30),
                      const SizedBox(width: 4),
                      Text(
                        displayDate,
                        style: GoogleFonts.breeSerif(color: Colors.white38, fontSize: 10),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.access_time_rounded, size: 11, color: Colors.white30),
                      const SizedBox(width: 4),
                      Text(
                        displayTime,
                        style: GoogleFonts.breeSerif(color: Colors.white38, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              priceStr,
              style: GoogleFonts.breeSerif(
                color: const Color(0xFFFECF65),
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
