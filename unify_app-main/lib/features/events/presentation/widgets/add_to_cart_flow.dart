import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/booking_models.dart';
import '../../domain/models/event_model.dart';
import '../providers/event_details_provider.dart';
import '../../../cart/presentation/providers/cart_provider.dart';

class AddToCartFlow {
  static void start(
    BuildContext context,
    WidgetRef ref,
    EventModel event,
    ConstraintModel constraint,
    List<SlotModel> slots,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => AddToCartFlowPage(
          event: event,
          constraint: constraint,
          slots: slots,
        ),
      ),
    );
  }
}

class AddToCartFlowPage extends ConsumerStatefulWidget {
  final EventModel event;
  final ConstraintModel constraint;
  final List<SlotModel> slots;

  const AddToCartFlowPage({
    super.key,
    required this.event,
    required this.constraint,
    required this.slots,
  });

  @override
  ConsumerState<AddToCartFlowPage> createState() => _AddToCartFlowPageState();
}

class _AddToCartFlowPageState extends ConsumerState<AddToCartFlowPage> {
  int _currentStep = 0; // 0 = Count, 1 = Details, 2 = Slot
  int _count = 1;
  bool _isLoading = false;

  // Step 1 Details State
  late List<Map<String, TextEditingController>> _controllers;

  // Step 2 Slot State
  SlotModel? _selectedSlot;

  @override
  void initState() {
    super.initState();
    if (widget.constraint.bookingType == 'multiple' && widget.constraint.fixed) {
      _count = widget.constraint.upperLimit;
    } else {
      _count = widget.constraint.lowerLimit;
    }
    _initControllers();
  }

  void _initControllers() {
    _controllers = List.generate(
      _count,
      (index) => {
        'name': TextEditingController(),
        'email': TextEditingController(),
        'phone': TextEditingController(),
      },
    );
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c['name']!.dispose();
      c['email']!.dispose();
      c['phone']!.dispose();
    }
    super.dispose();
  }

  void _goToDetails() {
    setState(() {
      _initControllers();
      _currentStep = 1;
    });
  }

  void _goToSlot() {
    // Validate
    for (var c in _controllers) {
      if (c['name']!.text.trim().isEmpty) {
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
    setState(() {
      _currentStep = 2;
    });
  }

  Future<void> _completeBooking() async {
    if (_selectedSlot == null) return;
    setState(() => _isLoading = true);

    final participants = _controllers
        .map(
          (c) => {
            'name': c['name']!.text.trim(),
            'email': c['email']!.text.trim(),
            'phone': c['phone']!.text.trim(),
          },
        )
        .toList();

    try {
      await ref
          .read(cartServiceProvider)
          .addToCart(
            eventId: widget.event.id.toString(),
            participants: participants,
            slotId: _selectedSlot!.id,
          );

      // Force cart refresh
      ref.invalidate(cartDataProvider);

      if (mounted) {
        // Pop wizard page
        Navigator.pop(context);
        
        // Show Full Screen Success Screen
        _showFullScreenSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString(), style: GoogleFonts.breeSerif())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showFullScreenSuccess() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, _, __) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFECF65).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: Color(0xFFFECF65),
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Added to Cart!',
                      style: GoogleFonts.breeSerif(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Passes have been successfully added to your cart.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.breeSerif(
                        color: Colors.white54,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFECF65),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context); // Pop success overlay
                          context.go('/cart'); // Navigate to Cart
                        },
                        child: Text(
                          'Go To Cart',
                          style: GoogleFonts.breeSerif(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context); // Pop success overlay
                        },
                        child: Text(
                          'Continue Browsing',
                          style: GoogleFonts.breeSerif(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          widget.event.title,
          style: GoogleFonts.breeSerif(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Step Indicator
              Row(
                children: [
                  _buildStepBubble(0, 'Size'),
                  _buildStepLine(0),
                  _buildStepBubble(1, 'Details'),
                  _buildStepLine(1),
                  _buildStepBubble(2, 'Slot'),
                ],
              ),
              const SizedBox(height: 32),

              // Content depending on current step
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: _buildStepContent(),
                ),
              ),

              // Bottom Button
              const SizedBox(height: 20),
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
                  onPressed: _isLoading ? null : _handleNext,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                        )
                      : Text(
                          _currentStep == 2 ? 'Add To Cart' : 'Next Phase',
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

  Widget _buildStepBubble(int step, String label) {
    bool isCompleted = _currentStep > step;
    bool isActive = _currentStep == step;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? const Color(0xFFFECF65)
                : isActive
                    ? const Color(0xFFFECF65)
                    : Colors.white12,
            border: Border.all(
              color: isActive ? Colors.white : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 16, color: Colors.black)
                : Text(
                    '${step + 1}',
                    style: GoogleFonts.breeSerif(
                      color: isActive ? Colors.black : Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.breeSerif(
            color: isActive ? Colors.white : Colors.white38,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int afterStep) {
    bool isColored = _currentStep > afterStep;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        height: 1.5,
        color: isColored ? const Color(0xFFFECF65) : Colors.white12,
      ),
    );
  }

  Widget _buildStepContent() {
    if (_currentStep == 0) {
      return _buildCountStep();
    } else if (_currentStep == 1) {
      return _buildDetailsStep();
    } else {
      return _buildSlotStep();
    }
  }

  void _handleNext() {
    if (_currentStep == 0) {
      _goToDetails();
    } else if (_currentStep == 1) {
      _goToSlot();
    } else {
      _completeBooking();
    }
  }

  // STEP 0: PARTICIPANT COUNT
  Widget _buildCountStep() {
    bool isFixed = widget.constraint.fixed;
    bool isSingle = widget.constraint.bookingType == 'single';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How many passes?',
          style: GoogleFonts.breeSerif(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isSingle
              ? 'This is a single participant event. One pass is permitted.'
              : isFixed
                  ? 'This is a team event requiring exactly ${widget.constraint.upperLimit} attendees.'
                  : 'You can choose between ${widget.constraint.lowerLimit} and ${widget.constraint.upperLimit} passes.',
          style: GoogleFonts.breeSerif(
            color: Colors.white54,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 48),
        if (!isSingle && !isFixed)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF16151A),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _count > widget.constraint.lowerLimit
                        ? () => setState(() => _count--)
                        : null,
                    icon: const Icon(Icons.remove, color: Colors.white),
                    iconSize: 28,
                  ),
                  const SizedBox(width: 24),
                  Text(
                    '$_count',
                    style: GoogleFonts.breeSerif(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 24),
                  IconButton(
                    onPressed: _count < widget.constraint.upperLimit
                        ? () => setState(() => _count++)
                        : null,
                    icon: const Icon(Icons.add, color: Colors.white),
                    iconSize: 28,
                  ),
                ],
              ),
            ),
          )
        else
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF16151A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$_count Passes Selected',
                style: GoogleFonts.breeSerif(
                  color: const Color(0xFFFECF65),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // STEP 1: PARTICIPANT DETAILS
  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pass Details',
          style: GoogleFonts.breeSerif(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Please enter the attendee details for each ticket.',
          style: GoogleFonts.breeSerif(
            color: Colors.white54,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _count,
          itemBuilder: (context, i) {
            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(20),
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
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controllers[i]['name'],
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
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controllers[i]['email'],
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
      ],
    );
  }

  // STEP 2: SLOT PICKER
  Widget _buildSlotStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Time Slot',
          style: GoogleFonts.breeSerif(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Choose an available timing slot for this event.',
          style: GoogleFonts.breeSerif(
            color: Colors.white54,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),
        if (widget.slots.isEmpty)
          Center(
            child: Text(
              'No slots available for this event.',
              style: GoogleFonts.breeSerif(color: Colors.redAccent, fontSize: 16),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.slots.length,
            itemBuilder: (context, i) {
              final slot = widget.slots[i];
              bool hasCapacity =
                  slot.unlimitedParticipants ||
                  (slot.availableParticipants != null &&
                      slot.availableParticipants! >= _count);

              final isSelected = _selectedSlot == slot;

              return GestureDetector(
                onTap: hasCapacity
                    ? () => setState(() => _selectedSlot = slot)
                    : null,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFECF65).withOpacity(0.1)
                        : const Color(0xFF16151A),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFFECF65)
                          : Colors.white.withOpacity(0.05),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${slot.startTime} - ${slot.endTime}',
                              style: GoogleFonts.breeSerif(
                                color: hasCapacity ? Colors.white : Colors.white24,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              slot.unlimitedParticipants
                                  ? 'Unlimited spots available'
                                  : '${slot.availableParticipants} spots left',
                              style: GoogleFonts.breeSerif(
                                color: hasCapacity ? Colors.greenAccent : Colors.redAccent,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFFFECF65),
                          size: 24,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
