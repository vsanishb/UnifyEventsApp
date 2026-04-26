import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/manage_event_card.dart';
import '../providers/manage_events_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/manage_event_modals.dart';

class ManageEventsPage extends ConsumerWidget {
  const ManageEventsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final isAdmin = user != null && user.role == 'admin';
    final eventsAsync = ref.watch(manageEventsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("MANAGE EVENTS", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Color(0xFFFF1C7C)),
              onPressed: () => ManageEventModals.showEventModal(context, ref),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(manageEventsProvider),
        color: const Color(0xFFFF1C7C),
        backgroundColor: Colors.black,
        child: eventsAsync.when(
          data: (events) {
            if (events.isEmpty) {
              return Center(child: Text("NO EVENTS ASSIGNED", style: GoogleFonts.plusJakartaSans(color: Colors.white24, fontWeight: FontWeight.bold)));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(24).copyWith(bottom: 120),
              itemCount: events.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ManageEventCard(event: events[index], isAdmin: isAdmin),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text("ERROR: $err", style: GoogleFonts.plusJakartaSans(color: Colors.white24))),
        ),
      ),
    );
  }
}
