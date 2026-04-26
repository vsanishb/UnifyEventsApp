import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../events/domain/models/event_model.dart';
import '../providers/events_provider.dart';
import '../../../../shared/widgets/r2_image_widget.dart';
import '../widgets/add_to_cart_flow.dart';

class EventDetailPage extends ConsumerWidget {
  final String eventId;

  const EventDetailPage({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: eventsAsync.when(
        data: (events) {
          final fullEvent = events.firstWhere(
            (e) => e.event.id.toString() == eventId,
            orElse: () => throw Exception("Event not found"),
          );
          final event = fullEvent.event;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.black,
                expandedHeight: 300,
                pinned: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      R2ImageWidget(imageKey: event.bannerImage, height: 300, borderRadius: 0),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.black87, Colors.transparent, Colors.black],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildTag('EVENT', const Color(0xFFFF1C7C)),
                          const SizedBox(width: 8),
                          _buildTag(event.date != null ? _formatDate(event.date) : 'TBA', const Color(0xFF00E5FF)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "DESCRIPTION",
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        event.description,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white70,
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (fullEvent.details?.rules != null) ...[
                        Text(
                          "RULES & REGULATIONS",
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white38,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          fullEvent.details!.rules!,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("ERROR: $err")),
      ),
      bottomNavigationBar: eventsAsync.maybeWhen(
        data: (events) {
          final fullEvent = events.firstWhere((e) => e.event.id.toString() == eventId);
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF13131D),
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("PRICE", style: GoogleFonts.plusJakartaSans(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w800)),
                        Text(
                          fullEvent.event.price != null && fullEvent.event.price! > 0 
                            ? "₹${fullEvent.event.price}" 
                            : "FREE ACCESS",
                          style: GoogleFonts.plusJakartaSans(color: const Color(0xFFFF1C7C), fontSize: 20, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => AddToCartFlow(fullEvent: fullEvent),
                        );
                      },
                      child: const Text("BOOK NOW"),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        orElse: () => const SizedBox(),
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return "TBA";
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
      return "${months[dt.month - 1]} ${dt.day.toString().padLeft(2, '0')}";
    } catch (_) { return "TBA"; }
  }
}
