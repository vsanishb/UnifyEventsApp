import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unify_events/features/events/domain/models/event_model.dart';
import 'package:unify_events/shared/widgets/app_cached_image.dart';

class HomeSearchResultCard extends StatelessWidget {
  final EventModel event;
  final String venue;
  final String? rawDateTime; // Pulls down backend start_datetime asynchronously

  const HomeSearchResultCard({
    super.key,
    required this.event,
    required this.venue,
    this.rawDateTime,
  });

  String _formatEventDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return "Date TBA";
    try {
      final parsed = DateTime.parse(rawDate);
      final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
      return "${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}";
    } catch (_) {
      if (rawDate.contains(' ')) {
        return rawDate.split(' ').first;
      }
      return rawDate;
    }
  }

  String _formatEventTime(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return "Time TBA";
    try {
      final parsed = DateTime.parse(rawDate);
      final hour = parsed.hour > 12 ? parsed.hour - 12 : (parsed.hour == 0 ? 12 : parsed.hour);
      final period = parsed.hour >= 12 ? "PM" : "AM";
      final minuteStr = parsed.minute.toString().padLeft(2, '0');
      final hourStr = hour.toString().padLeft(2, '0');
      return "$hourStr:$minuteStr $period";
    } catch (_) {
      if (rawDate.contains(' ')) {
        return rawDate.split(' ').last;
      }
      return "08:00 AM";
    }
  }

  @override
  Widget build(BuildContext context) {
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
                        _formatEventDate(rawDateTime),
                        style: GoogleFonts.breeSerif(color: Colors.white38, fontSize: 10),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.access_time_rounded, size: 11, color: Colors.white30),
                      const SizedBox(width: 4),
                      Text(
                        _formatEventTime(rawDateTime),
                        style: GoogleFonts.breeSerif(color: Colors.white38, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              event.price != null && event.price! > 0 ? "₹${event.price!.toStringAsFixed(0)}" : "Free",
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