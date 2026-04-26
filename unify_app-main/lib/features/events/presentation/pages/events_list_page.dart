import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../events/presentation/providers/events_provider.dart';
import '../../../events/domain/models/event_model.dart';
import '../../../../shared/widgets/r2_image_widget.dart';

class EventsListPage extends ConsumerWidget {
  final String type;

  const EventsListPage({super.key, required this.type});

  String get _title {
    final normalizedType = type.toLowerCase().replaceAll(' ', '');
    if (normalizedType == 'phaseshift') return 'PhaseShift Events';
    if (normalizedType == 'utsav') return 'Utsav Events';
    if (normalizedType == 'clubevents') return 'Club Events';
    return 'Regular Events';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredEventsAsync = ref.watch(filteredEventsProvider(type));

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
          _title.toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(filteredEventsProvider(type));
        },
        color: const Color(0xFFFF1C7C),
        backgroundColor: Colors.black,
        child: filteredEventsAsync.when(
          data: (events) {
            if (events.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.event_busy,
                          color: Colors.white24,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No events found for $_title',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white54,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ).copyWith(bottom: 120),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: events.length,
              itemBuilder: (context, index) {
                return _buildEventCard(context, events[index]);
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF1C7C)),
          ),
          error: (err, stack) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
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
                        'Failed to load events. Network error.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            ref.invalidate(filteredEventsProvider(type)),
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, FullEvent fullEvent) {
    final event = fullEvent.event;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF13131D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push('/event-details/${event.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                R2ImageWidget(
                  imageKey: event.bannerImage,
                  height: 160,
                  borderRadius: 0,
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDate(event.date),
                            style: GoogleFonts.jetBrainsMono(
                              color: const Color(0xFF00E5FF),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            event.price != null && event.price! > 0
                                ? '₹${event.price}'
                                : 'FREE',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFFFF1C7C),
                              fontWeight: FontWeight.w800,
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
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return "TBA";
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final months = [
        'JAN',
        'FEB',
        'MAR',
        'APR',
        'MAY',
        'JUN',
        'JUL',
        'AUG',
        'SEP',
        'OCT',
        'NOV',
        'DEC',
      ];
      return "${months[dt.month - 1]} ${dt.day.toString().padLeft(2, '0')}";
    } catch (_) {
      return "TBA";
    }
  }
}
