import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../events/presentation/providers/events_provider.dart';
import '../../../events/domain/models/event_model.dart';

final cartDataProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  final dio = ref.read(dioProvider);
  final events = await ref.watch(eventsProvider.future);

  try {
    // 1. Fetch Cart
    final cartRes = await dio.get('/cart/');
    final cartData = (cartRes.data is List && cartRes.data.isNotEmpty)
        ? _asStringMap(cartRes.data[0])
        : (cartRes.data is Map
              ? _asStringMap(cartRes.data)
              : <String, dynamic>{});

    final cartId = cartData['id'];
    if (cartId == null) return {'items': []};

    // 2. Fetch Cart Items
    final itemsRes = await dio.get(
      '/cartitems/',
      queryParameters: {'cart': cartId},
    );
    final rawItems = _parseList(itemsRes);

    // 3. Enrich Items with FullEvent and Participants
    final enrichedItems = await Future.wait(
      rawItems.map((item) async {
        final itemMap = _asStringMap(item);
        final eventId = itemMap['event'];
        FullEvent? fullEvent;
        try {
          fullEvent = events.firstWhere((e) => e.event.id == eventId);
        } catch (_) {
          fullEvent = null;
        }

        final pRes = await dio.get(
          '/tempbookings/',
          queryParameters: {'cart_item': itemMap['id']},
        );
        final participants = _parseList(pRes);

        final sRes = await dio.get(
          '/temp-timeslots/',
          queryParameters: {'cart_item': itemMap['id']},
        );
        final slots = _parseList(sRes);

        return {
          ...itemMap,
          'full_event': fullEvent,
          'temp_bookings': participants,
          'temp_timeslots': slots,
        };
      }),
    );

    return {...cartData, 'items': enrichedItems};
  } catch (e) {
    return {'items': []};
  }
});

// Needed for compatibility with PaymentPage
final tempBookingsProvider = FutureProvider.family<List<dynamic>, dynamic>((
  ref,
  itemId,
) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get(
    '/tempbookings/',
    queryParameters: {'cart_item': itemId},
  );
  return _parseList(res);
});

final tempTimeslotsProvider = FutureProvider.family<List<dynamic>, dynamic>((
  ref,
  itemId,
) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get(
    '/temp-timeslots/',
    queryParameters: {'cart_item': itemId},
  );
  return _parseList(res);
});

class CartActionService {
  final Dio _dio;
  CartActionService(this._dio);

  Future<void> addToCart({
    required String eventId,
    required List<Map<String, String>> participants,
    required int slotId,
  }) async {
    // Get/Create Cart
    final cartRes = await _dio.get('/cart/');
    var cartId = (cartRes.data is List && cartRes.data.isNotEmpty)
        ? cartRes.data[0]['id']
        : cartRes.data['id'];

    if (cartId == null) {
      final newCart = await _dio.post('/cart/');
      cartId = newCart.data['id'];
    }

    // Add Item
    final itemRes = await _dio.post(
      '/cartitems/',
      data: {
        'cart': cartId,
        'event': eventId,
        'participants_count': participants.length,
      },
    );
    final itemId = itemRes.data['id'];

    // Add Participants
    for (var p in participants) {
      await _dio.post('/tempbookings/', data: {...p, 'cart_item': itemId});
    }

    // Add Slot
    await _dio.post(
      '/temp-timeslots/',
      data: {'cart_item': itemId, 'slot': slotId},
    );
  }

  Future<void> removeFromCart(String itemId) async {
    await _dio.delete('/cartitems/$itemId/');
  }

  Future<void> updateParticipant(int id, Map<String, dynamic> data) async {
    await _dio.patch('/tempbookings/$id/', data: data);
  }

  Future<void> removeParticipant(int id) async {
    await _dio.delete('/tempbookings/$id/');
  }

  // Compatibility methods
  Future<void> updateCartItem(int id, Map<String, dynamic> data) async {
    await _dio.patch('/cartitems/$id/', data: data);
  }

  Future<void> addParticipant(Map<String, dynamic> data) async {
    await _dio.post('/tempbookings/', data: data);
  }

  Future<void> updateTimeSlot(Map<String, dynamic> data) async {
    // Usually updates or replaces the slot
    await _dio.post('/temp-timeslots/', data: data);
  }
}

final cartActionProvider = Provider<CartActionService>(
  (ref) => CartActionService(ref.read(dioProvider)),
);

List<dynamic> _parseList(Response res) {
  if (res.data is List) return res.data;
  if (res.data is Map) return res.data['results'] ?? [];
  return [];
}

Map<String, dynamic> _asStringMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  return <String, dynamic>{};
}
