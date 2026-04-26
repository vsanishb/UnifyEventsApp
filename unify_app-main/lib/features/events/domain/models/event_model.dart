class EventModel {
  final int id;
  final int? parentEventId;
  final String title;
  final String description;
  final String? bannerImage;
  final num? price;
  final String? date;

  EventModel({
    required this.id,
    this.parentEventId,
    required this.title,
    required this.description,
    this.bannerImage,
    this.price,
    this.date,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      parentEventId: int.tryParse(json['parent_event']?.toString() ?? ''),
      title: json['title']?.toString() ?? json['name']?.toString() ?? 'Unknown Event',
      description: json['description']?.toString() ?? '',
      bannerImage: json['image_key']?.toString() ?? json['banner_image']?.toString() ?? json['image']?.toString(),
      price: num.tryParse(json['price']?.toString() ?? json['fee']?.toString() ?? ''),
      date: json['date']?.toString() ?? json['start_time']?.toString(),
    );
  }
}


class EventDetails {
  final int id;
  final int eventId;
  final String? venue;
  final String? rules;
  final String? eligibility;

  EventDetails({
    required this.id,
    required this.eventId,
    this.venue,
    this.rules,
    this.eligibility,
  });

  factory EventDetails.fromJson(Map<String, dynamic> json) {
    return EventDetails(
      id: json['id'] ?? 0,
      eventId: json['event'] ?? 0,
      venue: json['venue'],
      rules: json['rules_and_regulations'] ?? json['rules'],
      eligibility: json['eligibility'],
    );
  }
}

class EventSlot {
  final int id;
  final int eventId;
  final String startTime;
  final String endTime;
  final int? availableParticipants;

  EventSlot({
    required this.id,
    required this.eventId,
    required this.startTime,
    required this.endTime,
    this.availableParticipants,
  });

  factory EventSlot.fromJson(Map<String, dynamic> json) {
    return EventSlot(
      id: json['id'] ?? 0,
      eventId: json['event_id'] ?? 0,
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      availableParticipants: json['available_participants'],
    );
  }
}

class EventConstraint {
  final int id;
  final int eventId;
  final String bookingType;
  final bool fixed;
  final int lowerLimit;
  final int upperLimit;

  EventConstraint({
    required this.id,
    required this.eventId,
    required this.bookingType,
    required this.fixed,
    required this.lowerLimit,
    required this.upperLimit,
  });

  factory EventConstraint.fromJson(Map<String, dynamic> json) {
    return EventConstraint(
      id: json['id'] ?? 0,
      eventId: json['event'] ?? 0,
      bookingType: json['booking_type']?.toString().toLowerCase() ?? 'single',
      fixed: json['fixed'] == true,
      lowerLimit: json['lower_limit'] ?? 1,
      upperLimit: json['upper_limit'] ?? 1,
    );
  }
}

class EventCategory {
  final int id;
  final String name;

  EventCategory({required this.id, required this.name});

  factory EventCategory.fromJson(Map<String, dynamic> json) {
    return EventCategory(id: json['id'] ?? 0, name: json['name'] ?? '');
  }
}

class ParentEvent {
  final int id;
  final String name;

  ParentEvent({required this.id, required this.name});

  factory ParentEvent.fromJson(Map<String, dynamic> json) {
    return ParentEvent(id: json['id'] ?? 0, name: json['name'] ?? '');
  }
}

class FullEvent {
  final EventModel event;
  final EventDetails? details;
  final List<EventSlot> slots;
  final EventConstraint? constraint;
  final EventCategory? category;
  final ParentEvent? parent;

  FullEvent({
    required this.event,
    this.details,
    this.slots = const [],
    this.constraint,
    this.category,
    this.parent,
  });
}
