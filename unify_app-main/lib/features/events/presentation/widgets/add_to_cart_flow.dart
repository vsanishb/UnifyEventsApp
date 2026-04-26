import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/models/event_model.dart';
import '../../../cart/presentation/providers/cart_provider.dart';

class AddToCartFlow extends ConsumerStatefulWidget {
  final FullEvent fullEvent;
  const AddToCartFlow({super.key, required this.fullEvent});

  @override
  ConsumerState<AddToCartFlow> createState() => _AddToCartFlowState();
}

class _AddToCartFlowState extends ConsumerState<AddToCartFlow> {
  int _currentStep = 0;
  int _participantCount = 1;
  final List<Map<String, String>> _participants = [];
  int? _selectedSlotId;

  @override
  void initState() {
    super.initState();
    _participantCount = widget.fullEvent.constraint?.lowerLimit ?? 1;
    // Pre-fill first participant if possible
    _participants.add({'name': '', 'email': '', 'phone': ''});
  }

  void _next() {
    setState(() => _currentStep++);
  }

  void _back() {
    if (_currentStep > 0)
      setState(() => _currentStep--);
    else
      Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          if (_currentStep == 0) _buildCountStep(),
          if (_currentStep == 1) _buildDetailsStep(),
          if (_currentStep == 2) _buildSlotStep(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCountStep() {
    final constraint = widget.fullEvent.constraint;
    final isFixed = constraint?.fixed ?? false;
    final lower = constraint?.lowerLimit ?? 1;
    final upper = constraint?.upperLimit ?? 1;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            "PARTICIPANT COUNT",
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isFixed
                ? "Fixed group of $lower"
                : "Choose between $lower and $upper",
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white38,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 32),
          if (!isFixed)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _counterBtn(Icons.remove, () {
                  if (_participantCount > lower) {
                    setState(() {
                      _participantCount--;
                      _participants.removeLast();
                    });
                  }
                }),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    "$_participantCount",
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _counterBtn(Icons.add, () {
                  if (_participantCount < upper) {
                    setState(() {
                      _participantCount++;
                      _participants.add({'name': '', 'email': '', 'phone': ''});
                    });
                  }
                }),
              ],
            )
          else
            Text(
              "$_participantCount",
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.w900,
              ),
            ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _next,
              child: const Text("CONTINUE"),
            ),
          ),
        ],
      ),
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
        child: Icon(icon, color: const Color(0xFFFF1C7C)),
      ),
    );
  }

  Widget _buildDetailsStep() {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              "PARTICIPANT DETAILS",
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 24),
            ...List.generate(_participantCount, (i) => _participantForm(i)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _back,
                    child: const Text("BACK"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _next,
                    child: const Text("CONTINUE"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _participantForm(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "PARTICIPANT ${index + 1}",
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF00E5FF),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            onChanged: (v) => _participants[index]['name'] = v,
            style: GoogleFonts.plusJakartaSans(color: Colors.white),
            decoration: const InputDecoration(
              labelText: "FULL NAME",
              prefixIcon: Icon(Icons.person_outline, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            onChanged: (v) => _participants[index]['email'] = v,
            style: GoogleFonts.plusJakartaSans(color: Colors.white),
            decoration: const InputDecoration(
              labelText: "EMAIL ADDRESS",
              prefixIcon: Icon(Icons.email_outlined, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotStep() {
    final slots = widget.fullEvent.slots ?? [];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            "SELECT TIMESLOT",
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 24),
          if (slots.isEmpty)
            Text(
              "No slots available for this event.",
              style: GoogleFonts.plusJakartaSans(color: Colors.white54),
            )
          else
            ...slots.map((s) => _slotCard(s)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _back,
                  child: const Text("BACK"),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _selectedSlotId == null ? null : _complete,
                  child: const Text("ADD TO CART"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _slotCard(EventSlot slot) {
    final isSelected = _selectedSlotId == slot.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedSlotId = slot.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF1C7C).withOpacity(0.1)
              : Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF1C7C)
                : Colors.white.withOpacity(0.05),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              color: isSelected ? const Color(0xFFFF1C7C) : Colors.white38,
              size: 20,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${_formatTime(slot.startTime)} - ${_formatTime(slot.endTime)}",
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${slot.availableParticipants ?? '∞'} SLOTS LEFT",
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFFFF1C7C)),
          ],
        ),
      ),
    );
  }

  void _complete() async {
    try {
      await ref
          .read(cartActionProvider)
          .addToCart(
            eventId: widget.fullEvent.event.id.toString(),
            participants: _participants,
            slotId: _selectedSlotId!,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Added to cart successfully!"),
            backgroundColor: Color(0xFF39FF14),
          ),
        );
      }
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Could not add event to cart. Please try again."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  String _formatTime(String time) {
    try {
      final parts = time.split(':');
      if (parts.length < 2) return time;
      final hr = int.parse(parts[0]);
      final min = parts[1];
      final ampm = hr >= 12 ? 'PM' : 'AM';
      final h12 = hr > 12 ? hr - 12 : (hr == 0 ? 12 : hr);
      return "$h12:$min $ampm";
    } catch (_) {
      return time;
    }
  }
}
