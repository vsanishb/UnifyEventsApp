import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/router/app_router.dart';

import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/storage/secure_storage_service.dart';
import 'features/bookings/data/models/cached_ticket.dart';
import 'features/events/data/models/cached_participant.dart';
import 'core/sync/models/pending_checkin.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // Handle Encryption Key
  final secureStorage = SecureStorageService();
  String? keyStr = await secureStorage.getHiveKey();
  late List<int> encryptionKeyAsUint8List;
  if (keyStr == null) {
    final key = Hive.generateSecureKey();
    await secureStorage.saveHiveKey(base64UrlEncode(key));
    encryptionKeyAsUint8List = key;
  } else {
    encryptionKeyAsUint8List = base64Url.decode(keyStr);
  }

  final cipher = HiveAesCipher(encryptionKeyAsUint8List);

  // Register Adapters
  Hive.registerAdapter(CachedTicketAdapter());
  Hive.registerAdapter(CachedParticipantAdapter());
  Hive.registerAdapter(PendingCheckinAdapter());

  // Open Boxes
  await Hive.openBox<CachedTicket>('tickets', encryptionCipher: cipher);
  await Hive.openBox<CachedParticipant>('participants', encryptionCipher: cipher);
  await Hive.openBox<PendingCheckin>('checkin_queue', encryptionCipher: cipher);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Colors.black,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFF1C7C),
            brightness: Brightness.dark,
            surface: const Color(0xFF13131D),
          ),
          textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF1C7C),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF13131D),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF1C7C), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          cardTheme: CardThemeData(
            color: const Color(0xFF13131D),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
          ),
        ),
        builder: (context, child) {
          return Container(
            color: Colors.black,
            child: child ?? const SizedBox(),
          );
        },
      ),
    );
  }
}
