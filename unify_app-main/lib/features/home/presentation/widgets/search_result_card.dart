import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unify_events/features/events/domain/models/event_model.dart';
import 'package:unify_events/shared/widgets/compact_event_row.dart';

class HomeSearchResultCard extends ConsumerWidget {
  final EventModel event;
  final String venue;

  const HomeSearchResultCard({
    super.key,
    required this.event,
    required this.venue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Align(
      alignment: Alignment.centerLeft,
      child: CompactEventRow(event: event),
    );
  }
}