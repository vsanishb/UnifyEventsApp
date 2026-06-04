import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../events/presentation/providers/event_details_provider.dart';
import '../../domain/models/slot_info.dart';

final bookedEventProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>((ref, id) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/booked-events/$id/');
  return res.data;
});

class TicketPage extends ConsumerStatefulWidget {
  final int bookedEventId;

  const TicketPage({super.key, required this.bookedEventId});

  @override
  ConsumerState<TicketPage> createState() => _TicketPageState();
}

class _TicketPageState extends ConsumerState<TicketPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(bookedEventProvider(widget.bookedEventId));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookedAsync = ref.watch(bookedEventProvider(widget.bookedEventId));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Digital Pass',
          style: GoogleFonts.breeSerif(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: bookedAsync.when(
          data: (bookedEvent) {
            final participants = (bookedEvent['participants'] as List?) ?? [];
            if (participants.isEmpty) {
              return Center(
                child: Text(
                  "No passes found.",
                  style: GoogleFonts.breeSerif(color: Colors.white),
                ),
              );
            }

            return PageView.builder(
              itemCount: participants.length,
              physics: const BouncingScrollPhysics(),
              controller: PageController(viewportFraction: 0.88),
              itemBuilder: (context, index) {
                final p = participants[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6.0,
                    vertical: 12.0,
                  ),
                  child: ParticipantTicketCard(
                    participant: p,
                    bookedEvent: bookedEvent,
                    bookedEventId: widget.bookedEventId,
                    currentIndex: index + 1,
                    totalCount: participants.length,
                  ),
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFFFECF65)),
          ),
          error: (_, __) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.search_off,
                  color: Colors.white54,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'Ticket not found',
                  style: GoogleFonts.breeSerif(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(bookedEventProvider(widget.bookedEventId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ParticipantTicketCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> participant;
  final Map<String, dynamic> bookedEvent;
  final int bookedEventId;
  final int currentIndex;
  final int totalCount;

  const ParticipantTicketCard({
    super.key,
    required this.participant,
    required this.bookedEvent,
    required this.bookedEventId,
    required this.currentIndex,
    required this.totalCount,
  });

  @override
  ConsumerState<ParticipantTicketCard> createState() =>
      _ParticipantTicketCardState();
}

class _ParticipantTicketCardState extends ConsumerState<ParticipantTicketCard> {
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
        '${tempDir.path}/unify_ticket_${widget.bookedEventId}_${widget.participant['id']}.png',
      ).create();
      await file.writeAsBytes(buffer);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'My Unify Event Pass 🎉');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to share ticket.',
              style: GoogleFonts.breeSerif(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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

  @override
  Widget build(BuildContext context) {
    final eventName =
        widget.bookedEvent['event_name']?.toString() ?? 'EVENT';
    final p = widget.participant;
    final bool arrived = p['arrived'] == true || p['qr_used'] == true;
    final qrToken = p['qr_token'] ?? '';

    final eventIdRaw =
        widget.bookedEvent['event_id'] ?? widget.bookedEvent['event'] ?? '';
    final eventId = eventIdRaw is Map
        ? eventIdRaw['id'].toString()
        : eventIdRaw.toString();
    final eventDetailsAsync = ref.watch(eventDetailsDataProvider(eventId));

    // Calculate layout ratio block offsets
    const double ticketCutoutPositionRatio = 0.70;

    return Column(
      children: [
        Expanded(
          child: RepaintBoundary(
            key: _ticketKey,
            child: CustomPaint(
              painter: TicketPainter(
                backgroundColor: const Color(0xFF16151A),
                borderColor: Colors.white.withOpacity(0.08),
                cutoutRatio: ticketCutoutPositionRatio,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final totalHeight = constraints.maxHeight;
                  final topBlockHeight = totalHeight * ticketCutoutPositionRatio;
                  final bottomBlockHeight = totalHeight * (1.0 - ticketCutoutPositionRatio);

                  return Column(
                    children: [
                      // Top Half Content Block
                      Container(
                        height: topBlockHeight,
                        padding: const EdgeInsets.only(left: 24, right: 24, top: 28, bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Badge Metadata Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFECF65).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'PASS ${widget.currentIndex} OF ${widget.totalCount}',
                                    style: GoogleFonts.breeSerif(
                                      color: const Color(0xFFFECF65),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    arrived ? 'CHECKED IN' : 'VALID ENTRY',
                                    style: GoogleFonts.breeSerif(
                                      color: arrived ? Colors.greenAccent : Colors.white30,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Event Heading Name
                            Center(
                              child: Text(
                                eventName,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.breeSerif(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Spacer(),
                            // Scaled QR Container Block
                            Center(
                              child: Container(
                                width: 170,
                                height: 170,
                                alignment: Alignment.center,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: arrived
                                    ? const Center(
                                        child: Text(
                                          "Checked In",
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                    : QrImageView(
                                        data: """{"type": "event_checkin", "token": "$qrToken", "participant_id": ${p['id']}}""",
                                        version: QrVersions.auto,
                                        size: 150.0,
                                        gapless: false,
                                        eyeStyle: const QrEyeStyle(
                                          eyeShape: QrEyeShape.square,
                                          color: Colors.black,
                                        ),
                                        dataModuleStyle: const QrDataModuleStyle(
                                          dataModuleShape: QrDataModuleShape.square,
                                          color: Colors.black,
                                        ),
                                      ),
                              ),
                            ),
                            const Spacer(),
                            // User Info Meta Row
                            Center(
                              child: Text(
                                p['name']?.toString() ?? 'Attendee',
                                style: GoogleFonts.breeSerif(
                                  color: const Color(0xFFFECF65),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (p['email'] != null) ...[
                              const SizedBox(height: 2),
                              Center(
                                child: Text(
                                  p['email'].toString(),
                                  style: GoogleFonts.breeSerif(
                                    color: Colors.white54,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Bottom Half Content Block
                      Container(
                        height: bottomBlockHeight,
                        padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 20),
                        alignment: Alignment.center,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'DATE',
                                    style: GoogleFonts.breeSerif(color: Colors.white38, fontSize: 10),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _getDateText(widget.bookedEvent['slot_info'], eventDetailsAsync.valueOrNull),
                                    style: GoogleFonts.breeSerif(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'TIME',
                                    style: GoogleFonts.breeSerif(color: Colors.white38, fontSize: 10),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _getTimeText(widget.bookedEvent['slot_info'], eventDetailsAsync.valueOrNull),
                                    style: GoogleFonts.breeSerif(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'VENUE',
                                    style: GoogleFonts.breeSerif(color: Colors.white38, fontSize: 10),
                                  ),
                                  const SizedBox(height: 2),
                                  eventDetailsAsync.when(
                                    data: (details) => Text(
                                      '${details['venue']?.toString() ?? 'TBA'}${details['location'] != null && details['location'].toString().isNotEmpty ? '\n${details['location']}' : ''}',
                                      style: GoogleFonts.breeSerif(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    loading: () => const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white30),
                                    ),
                                    error: (_, __) => Text(
                                      'TBA',
                                      style: GoogleFonts.breeSerif(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Action Block Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFECF65),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: _isSaving ? null : _shareTicket,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.share, color: Colors.black),
              label: Text(
                _isSaving ? 'Processing...' : 'Export Pass',
                style: GoogleFonts.breeSerif(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  String _getDateText(dynamic rawSlotInfo, Map<String, dynamic>? details) {
    final slotInfo = SlotInfo.tryParse(rawSlotInfo);
    if (slotInfo?.date != null) return slotInfo!.date!;
    
    // fallback
    if (details != null) {
      final startDt = details['start_datetime']?.toString() ?? details['date']?.toString();
      if (startDt != null && startDt.isNotEmpty) {
        try {
          final parsed = DateTime.parse(startDt);
          final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
          return "${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}";
        } catch (_) {}
      }
    }
    return 'TBA';
  }

  String _getTimeText(dynamic rawSlotInfo, Map<String, dynamic>? details) {
    final slotInfo = SlotInfo.tryParse(rawSlotInfo);
    if (slotInfo?.startTime != null && slotInfo?.endTime != null) {
      return '${formatTimeHHMM(slotInfo!.startTime)} - ${formatTimeHHMM(slotInfo.endTime)}';
    }
    // fallback
    if (details != null) {
      final startDt = details['start_datetime']?.toString() ?? details['date']?.toString();
      if (startDt != null && startDt.isNotEmpty) {
        try {
          final parsed = DateTime.parse(startDt);
          final hour = parsed.hour > 12 ? parsed.hour - 12 : (parsed.hour == 0 ? 12 : parsed.hour);
          final period = parsed.hour >= 12 ? "PM" : "AM";
          final minuteStr = parsed.minute.toString().padLeft(2, '0');
          final hourStr = hour.toString().padLeft(2, '0');
          return "$hourStr:$minuteStr $period";
        } catch (_) {}
      }
    }
    return 'TBA';
  }
}

class TicketPainter extends CustomPainter {
  final Color backgroundColor;
  final Color borderColor;
  final double cutoutRatio;

  TicketPainter({
    required this.backgroundColor,
    required this.borderColor,
    required this.cutoutRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    const r = 24.0; 
    const cutoutR = 14.0; 
    final cutoutY = size.height * cutoutRatio;

    path.moveTo(r, 0);
    path.lineTo(size.width - r, 0);
    path.arcToPoint(Offset(size.width, r), radius: const Radius.circular(r));
    path.lineTo(size.width, cutoutY - cutoutR);
    path.arcToPoint(Offset(size.width, cutoutY + cutoutR),
        radius: const Radius.circular(cutoutR), clockwise: false);
    path.lineTo(size.width, size.height - r);
    path.arcToPoint(Offset(size.width - r, size.height), radius: const Radius.circular(r));
    path.lineTo(r, size.height);
    path.arcToPoint(Offset(0, size.height - r), radius: const Radius.circular(r));
    path.lineTo(0, cutoutY + cutoutR);
    path.arcToPoint(Offset(0, cutoutY - cutoutR),
        radius: const Radius.circular(cutoutR), clockwise: false);
    path.lineTo(0, r);
    path.arcToPoint(Offset(r, 0), radius: const Radius.circular(r));
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);

    final dashPaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    double startX = cutoutR + 4;
    double endX = size.width - cutoutR - 4;
    const dashWidth = 6.0;
    const dashSpace = 5.0;

    while (startX < endX) {
      canvas.drawLine(
        Offset(startX, cutoutY),
        Offset(startX + dashWidth, cutoutY),
        dashPaint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}