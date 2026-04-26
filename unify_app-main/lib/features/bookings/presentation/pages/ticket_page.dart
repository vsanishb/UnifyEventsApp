import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../events/presentation/providers/event_details_provider.dart';
import '../providers/bookings_provider.dart';
import '../../domain/models/slot_info.dart';

final bookedEventProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>((ref, id) async {
      final dio = ref.read(dioProvider);

      try {
        final res = await dio.get('/booked-events/$id/');
        final data = _toMap(res.data);
        if (data.isNotEmpty) return data;
      } catch (_) {}

      final bookings = await ref.watch(myBookingsProvider.future);
      for (final booking in bookings) {
        final bookingMap = _toMap(booking);
        final bookedEvents =
            bookingMap['booked_events'] as List<dynamic>? ?? [];
        for (final bookedEvent in bookedEvents) {
          final bookedEventMap = _toMap(bookedEvent);
          final bookedEventId = int.tryParse(
            bookedEventMap['id']?.toString() ?? '',
          );
          if (bookedEventId == id) {
            return bookedEventMap;
          }
        }
      }

      return <String, dynamic>{};
    });

class TicketPage extends ConsumerWidget {
  final int bookedEventId;
  const TicketPage({super.key, required this.bookedEventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookedAsync = ref.watch(bookedEventProvider(bookedEventId));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "DIGITAL PASS",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: bookedAsync.when(
          data: (bookedEvent) {
            final participants = (bookedEvent['participants'] as List?) ?? [];
            if (participants.isEmpty)
              return Center(
                child: Text(
                  "NO PASSES FOUND",
                  style: GoogleFonts.plusJakartaSans(color: Colors.white24),
                ),
              );

            return PageView.builder(
              itemCount: participants.length,
              physics: const BouncingScrollPhysics(),
              controller: PageController(viewportFraction: 0.85),
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.all(12),
                child: ParticipantTicketCard(
                  participant: participants[index],
                  bookedEvent: bookedEvent,
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: Text(
              "ERROR LOADING PASS",
              style: GoogleFonts.plusJakartaSans(color: Colors.white24),
            ),
          ),
        ),
      ),
    );
  }
}

class ParticipantTicketCard extends StatefulWidget {
  final Map<String, dynamic> participant;
  final Map<String, dynamic> bookedEvent;

  const ParticipantTicketCard({
    super.key,
    required this.participant,
    required this.bookedEvent,
  });

  @override
  State<ParticipantTicketCard> createState() => _ParticipantTicketCardState();
}

class _ParticipantTicketCardState extends State<ParticipantTicketCard> {
  final GlobalKey _ticketKey = GlobalKey();
  bool _isSaving = false;

  Future<void> _shareTicket() async {
    setState(() => _isSaving = true);
    try {
      final boundary =
          _ticketKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = await File(
        '${tempDir.path}/unify_pass_${widget.participant['id']}.png',
      ).create();
      await file.writeAsBytes(buffer);
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'My Unify Event Pass 🎉');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.participant;
    final eventName =
        widget.bookedEvent['event_name']?.toString().toUpperCase() ?? 'EVENT';
    final qrToken = p['qr_token'] ?? '';
    final arrived = p['qr_used'] == true;

    return Column(
      children: [
        Expanded(
          child: RepaintBoundary(
            key: _ticketKey,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF13131D),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          "OFFICIAL PASS",
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF00E5FF),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          eventName,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: arrived
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 140,
                                )
                              : QrImageView(
                                  data:
                                      """{"token": "$qrToken", "id": ${p['id']}}""",
                                  size: 140,
                                  version: QrVersions.auto,
                                ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          p['name']?.toString().toUpperCase() ?? 'ATTENDEE',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFFFF1C7C),
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p['email']?.toString().toUpperCase() ?? '',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white38,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfo(
                          "DATE",
                          widget.bookedEvent['slot_info']?['date']
                                  ?.toUpperCase() ??
                              'TBA',
                        ),
                        _buildInfo("GATE", "MAIN"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _shareTicket,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share_outlined),
            label: const Text("SHARE PASS"),
          ),
        ),
      ],
    );
  }

  Widget _buildInfo(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

Map<String, dynamic> _toMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}
