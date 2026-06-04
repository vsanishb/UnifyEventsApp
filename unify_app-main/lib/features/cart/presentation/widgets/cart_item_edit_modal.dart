import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/cart_provider.dart';
import '../../../events/presentation/providers/event_details_provider.dart';
import '../../../events/domain/models/booking_models.dart';

class CartItemEditModal extends ConsumerStatefulWidget {
  final Map<String, dynamic> item;

  const CartItemEditModal({super.key, required this.item});

  @override
  ConsumerState<CartItemEditModal> createState() => _CartItemEditModalState();
}

class _CartItemEditModalState extends ConsumerState<CartItemEditModal> {
  int _count = 1;
  late List<Map<String, dynamic>> _participants;
  late List<Map<String, dynamic>> _deletedParticipants;
  int? _selectedSlotId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _count = widget.item['participants_count'] ?? 1;
    _participants = [];
    _deletedParticipants = [];

    // Initialize with current slot if any
    if (widget.item['temp_timeslot'] != null &&
        widget.item['temp_timeslot']['slot'] != null) {
      _selectedSlotId = widget.item['temp_timeslot']['slot'] as int?;
    } else if (widget.item['temp_timeslots'] != null &&
        (widget.item['temp_timeslots'] as List).isNotEmpty) {
      _selectedSlotId = (widget.item['temp_timeslots'] as List).first['slot'] as int?;
    }

    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    setState(() => _isLoading = true);
    try {
      final temp = await ref.read(
        tempBookingsProvider(widget.item['id']).future,
      );
      if (mounted) {
        setState(() {
          _participants = temp
              .map(
                (t) => {
                  'id': t['id'],
                  'name': TextEditingController(text: t['name'] ?? ''),
                  'email': TextEditingController(text: t['email'] ?? ''),
                  'phone': TextEditingController(text: t['phone'] ?? ''),
                },
              )
              .toList();
          _adjustParticipantsSize();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _adjustParticipantsSize();
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    for (var p in _participants) {
      (p['name'] as TextEditingController).dispose();
      (p['email'] as TextEditingController).dispose();
      (p['phone'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  void _adjustParticipantsSize() {
    if (_participants.length < _count) {
      int needed = _count - _participants.length;
      for (int i = 0; i < needed; i++) {
        _participants.add({
          'id': null,
          'name': TextEditingController(),
          'email': TextEditingController(),
          'phone': TextEditingController(),
        });
      }
    } else if (_participants.length > _count) {
      int excess = _participants.length - _count;
      for (int i = 0; i < excess; i++) {
        var removed = _participants.removeLast();
        if (removed['id'] != null) {
          _deletedParticipants.add(removed);
        }
      }
    }
  }

  Future<void> _saveChanges(int cartItemId) async {
    // Validation
    for (var p in _participants) {
      final nameCtrl = p['name'] as TextEditingController;
      if (nameCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'All participant names are required.',
              style: GoogleFonts.breeSerif(),
            ),
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    final actionService = ref.read(cartActionProvider);

    try {
      // 1. Update Team Size
      await actionService.updateCartItem(cartItemId, {
        'participants_count': _count,
      });

      // 2. Sync Participants
      for (var p in _participants) {
        final data = {
          'cart_item': cartItemId,
          'name': (p['name'] as TextEditingController).text.trim(),
          'email': (p['email'] as TextEditingController).text.trim(),
          'phone': (p['phone'] as TextEditingController).text.trim(),
        };

        if (p['id'] != null) {
          await actionService.updateParticipant(p['id'], data);
        } else {
          await actionService.addParticipant(data);
        }
      }

      for (var dp in _deletedParticipants) {
        await actionService.removeParticipant(dp['id']);
      }

      // 3. Update Slot
      if (_selectedSlotId != null) {
        await actionService.updateTimeSlot({
          'cart_item': cartItemId,
          'slot': _selectedSlotId,
        });
      }

      ref.invalidate(cartDataProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cart item updated successfully',
              style: GoogleFonts.breeSerif(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update: $e',
              style: GoogleFonts.breeSerif(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String eventId = '';
    if (widget.item['event_id'] != null) {
      eventId = widget.item['event_id'].toString();
    } else if (widget.item['event'] is int) {
      eventId = widget.item['event'].toString();
    } else if (widget.item['event'] is Map) {
      eventId = widget.item['event']['id'].toString();
    }

    final constraintAsync = ref.watch(constraintProvider(eventId));
    final slotsAsync = ref.watch(slotsProvider(eventId));
    final cartItemId = widget.item['id'];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Cart Item',
          style: GoogleFonts.breeSerif(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // Team Size Section
                      constraintAsync.when(
                        data: (constraint) {
                          if (constraint == null) return const SizedBox();

                          bool isFixed = constraint.fixed;
                          bool isSingle = constraint.bookingType == 'single';

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Passes Count',
                                style: GoogleFonts.breeSerif(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isSingle
                                    ? 'This is a single participant event.'
                                    : isFixed
                                        ? 'Fixed team size of ${constraint.upperLimit} required.'
                                        : 'Select between ${constraint.lowerLimit} and ${constraint.upperLimit} passes.',
                                style: GoogleFonts.breeSerif(color: Colors.white54, fontSize: 13),
                              ),
                              const SizedBox(height: 16),
                              if (!isSingle && !isFixed)
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF16151A),
                                      borderRadius: BorderRadius.circular(40),
                                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed: _count > constraint.lowerLimit
                                              ? () {
                                                  setState(() {
                                                    _count--;
                                                    _adjustParticipantsSize();
                                                  });
                                                }
                                              : null,
                                          icon: const Icon(Icons.remove, color: Colors.white),
                                        ),
                                        const SizedBox(width: 16),
                                        Text(
                                          '$_count',
                                          style: GoogleFonts.breeSerif(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        IconButton(
                                          onPressed: _count < constraint.upperLimit
                                              ? () {
                                                  setState(() {
                                                    _count++;
                                                    _adjustParticipantsSize();
                                                  });
                                                }
                                              : null,
                                          icon: const Icon(Icons.add, color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 24),
                            ],
                          );
                        },
                        loading: () => const Center(
                          child: CircularProgressIndicator(color: Color(0xFFFECF65)),
                        ),
                        error: (_, __) => Text(
                          'Failed to load constraints',
                          style: GoogleFonts.breeSerif(color: Colors.redAccent),
                        ),
                      ),

                      // Participants List
                      Text(
                        'Attendees Details',
                        style: GoogleFonts.breeSerif(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFECF65)))
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _participants.length,
                              itemBuilder: (ctx, i) {
                                final p = _participants[i];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF16151A),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Attendee ${i + 1}',
                                        style: GoogleFonts.breeSerif(
                                          color: const Color(0xFFFECF65),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: p['name'] as TextEditingController,
                                        style: GoogleFonts.breeSerif(color: Colors.white),
                                        decoration: InputDecoration(
                                          labelText: 'Full Name *',
                                          labelStyle: GoogleFonts.breeSerif(color: Colors.white54),
                                          filled: true,
                                          fillColor: Colors.black,
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: const BorderSide(color: Color(0xFFFECF65)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: p['email'] as TextEditingController,
                                        style: GoogleFonts.breeSerif(color: Colors.white),
                                        decoration: InputDecoration(
                                          labelText: 'Email (Optional)',
                                          labelStyle: GoogleFonts.breeSerif(color: Colors.white54),
                                          filled: true,
                                          fillColor: Colors.black,
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: const BorderSide(color: Color(0xFFFECF65)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                      const SizedBox(height: 24),

                      // Slot Picker
                      Text(
                        'Select Time Slot',
                        style: GoogleFonts.breeSerif(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      slotsAsync.when(
                        data: (slots) {
                          if (slots.isEmpty) {
                            return Text(
                              'No slots available.',
                              style: GoogleFonts.breeSerif(color: Colors.white54),
                            );
                          }

                          return Column(
                            children: slots.map((slot) {
                              bool hasCapacity =
                                  slot.unlimitedParticipants ||
                                  (slot.availableParticipants != null &&
                                      slot.availableParticipants! >= _count);
                              bool canSelect = hasCapacity || _selectedSlotId == slot.id;
                              bool isSelected = _selectedSlotId == slot.id;

                              return GestureDetector(
                                onTap: canSelect
                                    ? () => setState(() => _selectedSlotId = slot.id)
                                    : null,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFFECF65).withOpacity(0.1)
                                        : const Color(0xFF16151A),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFFFECF65) : Colors.white.withOpacity(0.05),
                                      width: isSelected ? 1.5 : 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${slot.startTime} - ${slot.endTime}',
                                            style: GoogleFonts.breeSerif(
                                              color: canSelect ? Colors.white : Colors.white24,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            slot.unlimitedParticipants
                                                ? 'Unlimited capacity'
                                                : '${slot.availableParticipants} spots left',
                                            style: GoogleFonts.breeSerif(
                                              color: canSelect ? Colors.greenAccent : Colors.redAccent,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_circle,
                                          color: Color(0xFFFECF65),
                                          size: 24,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                        loading: () => const Center(
                          child: CircularProgressIndicator(color: Color(0xFFFECF65)),
                        ),
                        error: (_, __) => Text(
                          'Error loading slots',
                          style: GoogleFonts.breeSerif(color: Colors.redAccent),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Save Button
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFECF65),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isLoading ? null : () => _saveChanges(cartItemId),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Save Changes',
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
  }
}
