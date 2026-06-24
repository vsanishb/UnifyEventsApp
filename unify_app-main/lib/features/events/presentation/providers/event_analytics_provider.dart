import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Provider to fetch and cache Event Analytics.
/// Marked as autoDispose so the cached response is correctly released when the user navigates away.
final eventAnalyticsProvider = FutureProvider.family.autoDispose<Map<String, dynamic>, String>((ref, eventId) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get('/events/$eventId/analytics/');
    if (response.data is Map) {
      return Map<String, dynamic>.from(response.data);
    }
    throw Exception('Invalid response format');
  } on DioException catch (e) {
    final errorMsg = e.response?.data?['detail'] ?? e.response?.data?['error'] ?? 'Failed to load analytics';
    throw Exception(errorMsg);
  } catch (e) {
    throw Exception('Failed to connect to server: $e');
  }
});


class EventAttendanceFilters {
  final String search;
  final String status;
  final String type;
  final String ordering;

  EventAttendanceFilters({
    this.search = '',
    this.status = 'all',
    this.type = 'all',
    this.ordering = '-newest',
  });

  EventAttendanceFilters copyWith({
    String? search,
    String? status,
    String? type,
    String? ordering,
  }) {
    return EventAttendanceFilters(
      search: search ?? this.search,
      status: status ?? this.status,
      type: type ?? this.type,
      ordering: ordering ?? this.ordering,
    );
  }
}

final eventAttendanceFiltersProvider = StateProvider.family<EventAttendanceFilters, String>((ref, eventId) {
  return EventAttendanceFilters();
});

class EventAttendanceNotifier extends StateNotifier<AsyncValue<List<dynamic>>> {
  final Ref ref;
  final String eventId;
  int _currentPage = 1;
  bool _hasNext = true;
  bool _isLoadingMore = false;
  final List<dynamic> _records = [];

  EventAttendanceNotifier(this.ref, this.eventId) : super(const AsyncValue.loading()) {
    fetchFirstPage();
  }

  int get currentPage => _currentPage;
  bool get hasNext => _hasNext;
  bool get isLoadingMore => _isLoadingMore;

  Future<void> fetchFirstPage() async {
    _currentPage = 1;
    _hasNext = true;
    _records.clear();
    state = const AsyncValue.loading();
    await _fetch();
  }

  Future<void> fetchNextPage() async {
    if (!_hasNext || _isLoadingMore) return;
    _isLoadingMore = true;
    _currentPage++;
    await _fetch();
  }

  Future<void> _fetch() async {
    final dio = ref.read(dioProvider);
    final filters = ref.read(eventAttendanceFiltersProvider(eventId));

    final queryParams = {
      'search': filters.search,
      'status': filters.status == 'all' ? '' : filters.status,
      'type': filters.type == 'all' ? '' : filters.type,
      'ordering': filters.ordering,
      'page': _currentPage,
    };

    try {
      final response = await dio.get(
        '/events/$eventId/attendance/',
        queryParameters: queryParams,
      );

      final data = response.data;
      List<dynamic> newRecords = [];
      
      if (data is Map) {
        newRecords = data['results'] ?? [];
        _hasNext = data['next'] != null;
      } else if (data is List) {
        newRecords = data;
        _hasNext = false;
      }

      _records.addAll(newRecords);
      state = AsyncValue.data(List.from(_records));
    } on DioError catch (e, stack) {
      final errorMsg = e.response?.data?['detail'] ?? e.response?.data?['error'] ?? 'Failed to load attendance';
      if (_currentPage == 1) {
        state = AsyncValue.error(errorMsg, stack);
      } else {
        _currentPage--;
        state = AsyncValue.data(List.from(_records));
      }
    } catch (e, stack) {
      if (_currentPage == 1) {
        state = AsyncValue.error('Failed to load: $e', stack);
      } else {
        _currentPage--;
        state = AsyncValue.data(List.from(_records));
      }
    } finally {
      _isLoadingMore = false;
    }
  }
}

final eventAttendanceNotifierProvider = StateNotifierProvider.family.autoDispose<EventAttendanceNotifier, AsyncValue<List<dynamic>>, String>((ref, eventId) {
  return EventAttendanceNotifier(ref, eventId);
});

final checkInParticipantProvider = Provider((ref) {
  final dio = ref.read(dioProvider);
  return (int participantId) async {
    try {
      await dio.post('/booked-participants/$participantId/checkin/');
    } on DioError catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Check-in failed');
    }
  };
});

final reverseCheckInParticipantProvider = Provider((ref) {
  final dio = ref.read(dioProvider);
  return (int participantId) async {
    try {
      await dio.post('/booked-participants/$participantId/reverse-checkin/');
    } on DioError catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Reversal failed');
    }
  };
});

final bookedEventDetailProvider = FutureProvider.family.autoDispose<Map<String, dynamic>, String>((ref, bookedEventId) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get('/booked-events/$bookedEventId/');
    return Map<String, dynamic>.from(res.data);
  } on DioError catch (e) {
    throw Exception(e.response?.data?['detail'] ?? 'Failed to load booking details');
  }
});
