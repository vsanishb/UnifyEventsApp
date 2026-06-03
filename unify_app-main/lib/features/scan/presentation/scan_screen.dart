import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/sync/sync_service.dart';
import 'scan_controller.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> with TickerProviderStateMixin {
  late MobileScannerController cameraController;
  bool isPreviewOpen = false;
  bool isScanningLocked = false;
  String? lastScannedToken;

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _handleDetect(BarcodeCapture capture) async {
    if (isScanningLocked || isPreviewOpen) return;
    if (capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first;
    final String? raw = barcode.rawValue;
    if (raw == null || raw.isEmpty) return;

    String? token;
    try {
      final parsed = jsonDecode(raw);
      if (parsed is Map && parsed["type"] == "event_checkin") {
        token = parsed["token"]?.toString();
      }
    } catch (_) {
      token = raw; 
    }

    if (token == null || token.trim().isEmpty) {
      _triggerInvalid();
      return;
    }

    setState(() {
      isScanningLocked = true;
      lastScannedToken = token;
    });
    cameraController.stop();

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasConnection = !connectivityResult.contains(ConnectivityResult.none);

      if (!hasConnection) {
        ref.read(syncServiceProvider).addPendingCheckin(token);
        showOfflineQueueModal();
        return;
      }

      final preview = await ref.read(scanControllerProvider.notifier).fetchPreview(token);

      if (!mounted) return;

      if (preview != null) {
        final status = preview["status"];
        
        if (status == "already_checked_in") {
          showAlreadyCheckedInModal(preview);
        } else if (status == "valid") {
          showPreviewModal(preview, token);
        } else if (status == "forbidden") {
          showAccessDeniedModal();
        } else {
          showInvalidQRModal();
        }
      } else {
        showInvalidQRModal();
      }
    } catch (_) {
      if (!mounted) return;
      showInvalidQRModal();
    }
  }

  void _triggerInvalid() {
    cameraController.stop();
    showInvalidQRModal();
  }


  // --- UI MODALS REDESIGNED AS FULLSCREEN SCAFFOLD OVERLAYS ---

  void showInvalidQRModal() {
    _showStatusOverlay(
      icon: Icons.qr_code_scanner_rounded,
      iconColor: Colors.redAccent,
      title: "Invalid QR Code",
      subtitle: "This ticket is not recognized or may have been tampered with.",
    );
  }

  void showAccessDeniedModal() {
    _showStatusOverlay(
      icon: Icons.lock_person_rounded,
      iconColor: Colors.orange,
      title: "Access Denied",
      subtitle: "You are not an assigned organiser for this specific event.",
    );
  }

  void showAlreadyCheckedInModal(Map data) {
    _showStatusOverlay(
      icon: Icons.person_pin_circle_rounded,
      iconColor: Colors.blueAccent,
      title: "Already Checked In",
      subtitle: "${data["participant_name"]}\n${data["event_name"]}",
      timing: data["slot"],
    );
  }

  void showOfflineQueueModal() {
    _showStatusOverlay(
      icon: Icons.cloud_off_rounded,
      iconColor: Colors.grey,
      title: "Offline Mode",
      subtitle: "No active connection detected. Check-in saved locally and will sync once connection is restored.",
    );
  }

  void showSuccessModal(Map data) {
    _showStatusOverlay(
      icon: Icons.check_circle_rounded,
      iconColor: Colors.greenAccent,
      title: "Access Granted",
      subtitle: data["participant_name"] ?? "Participant",
      timing: "Verified at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}",
    );
  }

  void _showStatusOverlay({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? timing,
  }) {
    setState(() => isPreviewOpen = true);
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
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
                        color: iconColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: iconColor,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.breeSerif(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.breeSerif(
                        color: Colors.white54,
                        fontSize: 16,
                      ),
                    ),
                    if (timing != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Text(
                          timing,
                          style: GoogleFonts.breeSerif(
                            color: const Color(0xFFFECF65),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
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
                          resetScanner();
                        },
                        child: Text(
                          "CONTINUE SCANNING",
                          style: GoogleFonts.breeSerif(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void showPreviewModal(Map<String, dynamic> data, String token) {
    setState(() => isPreviewOpen = true);
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
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
                        Icons.qr_code_scanner_rounded,
                        color: Color(0xFFFECF65),
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      "PREVIEW CHECK-IN",
                      style: GoogleFonts.breeSerif(
                        color: Colors.white30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      data["participant_name"] ?? "Guest",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.breeSerif(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data["event_name"] ?? "Event",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.breeSerif(
                        color: const Color(0xFFFECF65),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.access_time_rounded, color: Colors.white54, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          data["slot"] ?? "TBA",
                          style: GoogleFonts.breeSerif(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
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
                          confirmCheckIn(token);
                        },
                        child: Text(
                          "CONFIRM ENTRY",
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
                          resetScanner();
                        },
                        child: Text(
                          "Cancel",
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
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Future<void> confirmCheckIn(String token) async {
    try {
      final res = await ref.read(scanControllerProvider.notifier).checkIn(token);
      showSuccessModal(res);
    } catch (e) {
      resetScanner();
    }
  }

  void resetScanner() {
    if (!mounted) return;
    setState(() {
      isPreviewOpen = false;
      isScanningLocked = false;
      lastScannedToken = null;
    });
    ref.read(scanControllerProvider.notifier).reset();
    cameraController.start();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scanControllerProvider);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(controller: cameraController, onDetect: _handleDetect),
          
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  "ENTRY SCANNER",
                  style: GoogleFonts.breeSerif(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Text(
                    "Scan to check in participants",
                    style: GoogleFonts.breeSerif(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          Center(
            child: CustomPaint(
              painter: QRScannerBorderPainter(
                color: state.isSuccess ? Colors.greenAccent : const Color(0xFFFECF65),
              ),
              child: const SizedBox(width: 260, height: 260),
            ),
          ),

          if (state.isProcessing)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFFFECF65)),
              ),
            ),
        ],
      ),
    );
  }
}

class QRScannerBorderPainter extends CustomPainter {
  final Color color;
  QRScannerBorderPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 6..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    const double len = 40;
    const double rad = 20;

    var path = Path()..moveTo(0, len)..lineTo(0, rad)..quadraticBezierTo(0, 0, rad, 0)..lineTo(len, 0);
    canvas.drawPath(path, paint);
    path = Path()..moveTo(size.width - len, 0)..lineTo(size.width - rad, 0)..quadraticBezierTo(size.width, 0, size.width, rad)..lineTo(size.width, len);
    canvas.drawPath(path, paint);
    path = Path()..moveTo(0, size.height - len)..lineTo(0, size.height - rad)..quadraticBezierTo(0, size.height, rad, size.height)..lineTo(len, size.height);
    canvas.drawPath(path, paint);
    path = Path()..moveTo(size.width - len, size.height)..lineTo(size.width - rad, size.height)..quadraticBezierTo(size.width, size.height, size.width, size.height - rad)..lineTo(size.width, size.height - len);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is QRScannerBorderPainter) {
      return oldDelegate.color != color;
    }
    return true;
  }
}