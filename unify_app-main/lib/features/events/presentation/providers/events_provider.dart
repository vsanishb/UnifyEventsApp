import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/event_model.dart';
import '../../../../core/errors/app_exception.dart';

final eventsProvider = FutureProvider<List<FullEvent>>((ref) async {
  final dio = ref.read(dioProvider);

  try {
    final results = await Future.wait([
      dio.get('/events/'),
      dio.get('/event-details/'),
      dio.get('/event-slots/'),
      dio.get('/constraints/'),
      dio.get('/categories/'),
      dio.get('/parent-events/'),
    ]);

    final rawEvents = _parseList(results[0]);
    final rawDetails = _parseList(results[1]);
    final rawSlots = _parseList(results[2]);
    final rawConstraints = _parseList(results[3]);
    final rawCategories = _parseList(results[4]);
    final rawParents = _parseList(results[5]);

    return rawEvents.map((eJson) {
      final eMap = Map<String, dynamic>.from(eJson);
      final event = EventModel.fromJson(eMap);

      final detailsJson = rawDetails.firstWhere(
        (d) => (d['event'] == event.id || d['event_id'] == event.id),
        orElse: () => null,
      );

      final slotsJson = rawSlots
          .where((s) => (s['event'] == event.id || s['event_id'] == event.id))
          .toList();

      final constraintJson = rawConstraints.firstWhere(
        (c) => (c['event'] == event.id || c['event_id'] == event.id),
        orElse: () => null,
      );

      final categoryId = eMap['category'];
      final categoryJson = rawCategories.firstWhere(
        (c) => c['id'] == categoryId,
        orElse: () => null,
      );

      final parentId = event.parentEventId;
      final parentJson = rawParents.firstWhere(
        (p) => p['id'] == parentId,
        orElse: () => null,
      );

      return FullEvent(
        event: event,
        details: detailsJson != null
            ? EventDetails.fromJson(Map<String, dynamic>.from(detailsJson))
            : null,
        slots: slotsJson
            .map((s) => EventSlot.fromJson(Map<String, dynamic>.from(s)))
            .toList(),
        constraint: constraintJson != null
            ? EventConstraint.fromJson(
                Map<String, dynamic>.from(constraintJson),
              )
            : null,
        category: categoryJson != null
            ? EventCategory.fromJson(Map<String, dynamic>.from(categoryJson))
            : null,
        parent: parentJson != null
            ? ParentEvent.fromJson(Map<String, dynamic>.from(parentJson))
            : null,
      );
    }).toList();
  } on DioError catch (e) {
    throw AppException(
      e.response?.data?['error'] ?? "Network Error: ${e.message}",
    );
  } catch (e) {
    throw AppException("Mapping Error: $e");
  }
});

final filteredEventsProvider = FutureProvider.family<List<FullEvent>, String>((
  ref,
  type,
) async {
  final allEvents = await ref.watch(eventsProvider.future);
  final normalizedType = type.toLowerCase().replaceAll(' ', '');

  bool isPhaseShift(FullEvent event) {
    final parentName = event.parent?.name.toLowerCase().replaceAll(' ', '');
    return event.event.parentEventId == 1 ||
        parentName == 'phaseshift' ||
        parentName == 'phase shift';
  }

  bool isUtsav(FullEvent event) {
    final parentName = event.parent?.name.toLowerCase().replaceAll(' ', '');
    return event.event.parentEventId == 2 || parentName == 'utsav';
  }

  if (normalizedType == 'phaseshift')
    return allEvents.where(isPhaseShift).toList();
  if (normalizedType == 'utsav') return allEvents.where(isUtsav).toList();
  if (normalizedType == 'regular' || normalizedType == 'clubevents') {
    return allEvents.where((e) => !isPhaseShift(e) && !isUtsav(e)).toList();
  }
  return allEvents;
});

List<dynamic> _parseList(Response res) {
  if (res.data is List) return res.data;
  if (res.data is Map) {
    if (res.data['results'] is List) return res.data['results'];
    if (res.data['data'] is List) return res.data['data'];
    return [res.data];
  }
  return [];
}
