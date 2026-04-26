import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/cart_provider.dart';
import '../../../events/presentation/providers/event_details_provider.dart';

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

    if (widget.item['temp_timeslots'] != null &&
        (widget.item['temp_timeslots'] as List).isNotEmpty) {
      _selectedSlotId = (widget.item['temp_timeslots'] as List).first['slot'];
    }

    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    setState(() => _isLoading = true);
    try {
      final temp = widget.item['temp_bookings'] as List? ?? [];
      setState(() {
        _participants = temp
            .map(
              (t) => {
                'id': t['id'],
                'name': TextEditingController(text: t['name'] ?? ''),
                'email': TextEditingController(text: t['email'] ?? ''),
              },
            )
            .toList();
        _adjustParticipantsSize();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    for (var p in _participants) {
      (p['name'] as TextEditingController).dispose();
      (p['email'] as TextEditingController).dispose();
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
        });
      }
    } else if (_participants.length > _count) {
      int excess = _participants.length - _count;
      for (int i = 0; i < excess; i++) {
        var removed = _participants.removeLast();
        if (removed['id'] != null) _deletedParticipants.add(removed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventId = widget.item['event'].toString();
    final constraintAsync = ref.watch(constraintProvider(eventId));
    final slotsAsync = ref.watch(slotsProvider(eventId));

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF13131D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "EDIT ITEM",
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white38),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("TEAM SIZE"),
                  constraintAsync.when(
                    data: (c) => _buildTeamPicker(c),
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const Text("Error loading constraints"),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle("PARTICIPANTS"),
                  ...List.generate(
                    _participants.length,
                    (i) => _participantForm(i),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle("TIME SLOT"),
                  slotsAsync.when(
                    data: (slots) => Column(
                      children: slots.map((s) => _slotCard(s)).toList(),
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const Text("Error loading slots"),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("SAVE CHANGES"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white38,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildTeamPicker(dynamic constraint) {
    if (constraint == null) return const SizedBox();
    if (constraint.fixed)
      return Text(
        "${constraint.lowerLimit} PARTICIPANTS (FIXED)",
        style: GoogleFonts.plusJakartaSans(color: Colors.white70),
      );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _counterBtn(Icons.remove, () {
          if (_count > constraint.lowerLimit)
            setState(() {
              _count--;
              _adjustParticipantsSize();
            });
        }),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            "$_count",
            style: GoogleFonts.jetBrainsMono(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        _counterBtn(Icons.add, () {
          if (_count < constraint.upperLimit)
            setState(() {
              _count++;
              _adjustParticipantsSize();
            });
        }),
      ],
    );
  }

  Widget _counterBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Icon(icon, color: const Color(0xFFFF1C7C), size: 20),
      ),
    );
  }

  Widget _participantForm(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _participants[index]['name'],
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 14,
            ),
            decoration: const InputDecoration(
              labelText: "NAME",
              prefixIcon: Icon(Icons.person_outline, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _slotCard(dynamic slot) {
    final isSelected = _selectedSlotId == slot.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedSlotId = slot.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF1C7C).withOpacity(0.1)
              : Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF1C7C)
                : Colors.white.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            Text(
              "${slot.startTime} - ${slot.endTime}",
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFFFF1C7C),
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  void _save() async {
    setState(() => _isLoading = true);
    try {
      final action = ref.read(cartActionProvider);
      final itemId = int.tryParse(widget.item['id']?.toString() ?? '0') ?? 0;
      if (itemId == 0) {
        throw Exception('Invalid cart item');
      }

      await action.updateCartItem(itemId, {'participants_count': _count});

      for (final p in _participants) {
        final name = (p['name'] as TextEditingController).text.trim();
        final email = (p['email'] as TextEditingController).text.trim();
        final pid = int.tryParse(p['id']?.toString() ?? '');

        if (pid != null) {
          await action.updateParticipant(pid, {'name': name, 'email': email});
        } else {
          await action.addParticipant({
            'cart_item': itemId,
            'name': name,
            'email': email,
            'phone': '',
          });
        }
      }

      for (final removed in _deletedParticipants) {
        final pid = int.tryParse(removed['id']?.toString() ?? '');
        if (pid != null) {
          await action.removeParticipant(pid);
        }
      }

      if (_selectedSlotId != null) {
        final tempSlots = widget.item['temp_timeslots'] as List? ?? const [];
        final existingSlot = tempSlots.isNotEmpty ? tempSlots.first : null;
        final slotData = <String, dynamic>{
          'slot': _selectedSlotId,
          'cart_item': itemId,
        };
        if (existingSlot is Map && existingSlot['id'] != null) {
          slotData['id'] = existingSlot['id'];
        }
        await action.updateTimeSlot(slotData);
      }

      Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cart item updated'),
            backgroundColor: Color(0xFF39FF14),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save changes: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
