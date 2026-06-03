import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/manage_events_provider.dart';

class ManageEventSubModals {
  static void showDetailsModal(
    BuildContext context,
    WidgetRef ref,
    int eventId,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => _DetailsModal(eventId: eventId),
      ),
    );
  }

  static void showConstraintsModal(
    BuildContext context,
    WidgetRef ref,
    int eventId,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => _ConstraintsModal(eventId: eventId),
      ),
    );
  }

  static void showSlotsModal(BuildContext context, WidgetRef ref, int eventId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => _SlotsListModal(eventId: eventId),
      ),
    );
  }
}

// --------------------------------------------------------------------------
// EVENT DETAILS FULL SCREEN Scaffold
// --------------------------------------------------------------------------
class _DetailsModal extends ConsumerStatefulWidget {
  final int eventId;
  const _DetailsModal({required this.eventId});
  @override
  ConsumerState<_DetailsModal> createState() => _DetailsModalState();
}

class _DetailsModalState extends ConsumerState<_DetailsModal> {
  bool _isFetching = true;
  bool _isLoading = false;
  Map<String, dynamic>? _details;
  final venueCtrl = TextEditingController();
  final aboutCtrl = TextEditingController();
  DateTime? startDateTime;
  DateTime? endDateTime;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  @override
  void dispose() {
    venueCtrl.dispose();
    aboutCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchDetails() async {
    try {
      final res = await ref
          .read(dioProvider)
          .get('/event-details/', queryParameters: {'event': widget.eventId});
      List<dynamic> data = [];
      if (res.data is List)
        data = res.data;
      else if (res.data is Map && res.data['results'] != null)
        data = res.data['results'];

      if (data.isNotEmpty) {
        _details = data.first;
        venueCtrl.text = _details!['venue']?.toString() ?? '';
        aboutCtrl.text =
            _details!['description']?.toString() ??
            _details!['about']?.toString() ??
            '';
        startDateTime = _details!['start_datetime'] != null
            ? DateTime.tryParse(_details!['start_datetime'])
            : null;
        endDateTime = _details!['end_datetime'] != null
            ? DateTime.tryParse(_details!['end_datetime'])
            : null;
      }
    } catch (_) {}
    if (mounted) setState(() => _isFetching = false);
  }

  Future<void> _pickDateTime(bool isStart) async {
    final current = isStart ? startDateTime : endDateTime;
    final date = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFECF65),
              onPrimary: Colors.black,
              surface: Color(0xFF16151A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(current ?? DateTime.now()),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFFFECF65),
                onPrimary: Colors.black,
                surface: Color(0xFF16151A),
                onSurface: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );
      if (time != null && mounted) {
        setState(() {
          final dt = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
          if (isStart)
            startDateTime = dt;
          else
            endDateTime = dt;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool exists = _details != null;

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
          exists ? 'Edit Details' : 'Add Details',
          style: GoogleFonts.breeSerif(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isFetching
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFECF65)))
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            TextField(
                              controller: venueCtrl,
                              style: GoogleFonts.breeSerif(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Venue',
                                labelStyle: GoogleFonts.breeSerif(color: Colors.white54),
                                filled: true,
                                fillColor: const Color(0xFF16151A),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Color(0xFFFECF65)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: aboutCtrl,
                              maxLines: 4,
                              style: GoogleFonts.breeSerif(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Description',
                                labelStyle: GoogleFonts.breeSerif(color: Colors.white54),
                                filled: true,
                                fillColor: const Color(0xFF16151A),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Color(0xFFFECF65)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: Colors.white.withOpacity(0.05)),
                              ),
                              tileColor: const Color(0xFF16151A),
                              title: Text(
                                'Start Date & Time',
                                style: GoogleFonts.breeSerif(color: Colors.white54, fontSize: 12),
                              ),
                              subtitle: Text(
                                startDateTime?.toString().split('.')[0] ?? 'Select...',
                                style: GoogleFonts.breeSerif(color: Colors.white, fontSize: 16),
                              ),
                              trailing: const Icon(
                                Icons.calendar_month,
                                color: Color(0xFFFECF65),
                              ),
                              onTap: () => _pickDateTime(true),
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: Colors.white.withOpacity(0.05)),
                              ),
                              tileColor: const Color(0xFF16151A),
                              title: Text(
                                'End Date & Time',
                                style: GoogleFonts.breeSerif(color: Colors.white54, fontSize: 12),
                              ),
                              subtitle: Text(
                                endDateTime?.toString().split('.')[0] ?? 'Select...',
                                style: GoogleFonts.breeSerif(color: Colors.white, fontSize: 16),
                              ),
                              trailing: const Icon(
                                Icons.calendar_month,
                                color: Color(0xFFFECF65),
                              ),
                              onTap: () => _pickDateTime(false),
                            ),
                          ],
                        ),
                      ),
                    ),
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
                        onPressed: _isLoading
                            ? null
                            : () async {
                                setState(() => _isLoading = true);
                                try {
                                  final payload = {
                                    "event": widget.eventId,
                                    "venue": venueCtrl.text,
                                    "description": aboutCtrl.text,
                                    if (startDateTime != null)
                                      "start_datetime": startDateTime!.toIso8601String(),
                                    if (endDateTime != null)
                                      "end_datetime": endDateTime!.toIso8601String(),
                                  };
                                  payload.removeWhere((k, v) => v == null || v == "");

                                  if (exists) {
                                    await ref
                                        .read(dioProvider)
                                        .patch(
                                          '/event-details/${_details!['id']}/',
                                          data: payload,
                                        );
                                  } else {
                                    await ref
                                        .read(dioProvider)
                                        .post('/event-details/', data: payload);
                                  }
                                  if (mounted) {
                                    Navigator.pop(context);
                                    ref.invalidate(manageEventsProvider);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Details saved successfully', style: GoogleFonts.breeSerif()),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed: $e', style: GoogleFonts.breeSerif()),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                } finally {
                                  if (mounted) setState(() => _isLoading = false);
                                }
                              },
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                              )
                            : Text(
                                'Save Details',
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

// --------------------------------------------------------------------------
// CONSTRAINTS FULL SCREEN Scaffold
// --------------------------------------------------------------------------
class _ConstraintsModal extends ConsumerStatefulWidget {
  final int eventId;
  const _ConstraintsModal({required this.eventId});
  @override
  ConsumerState<_ConstraintsModal> createState() => _ConstraintsModalState();
}

class _ConstraintsModalState extends ConsumerState<_ConstraintsModal> {
  bool _isFetching = true;
  bool _isLoading = false;
  Map<String, dynamic>? _constraint;

  String bookingType = 'single';
  final lowerLimitCtrl = TextEditingController(text: '1');
  final upperLimitCtrl = TextEditingController(text: '1');
  bool isFixed = true;

  @override
  void initState() {
    super.initState();
    _fetchConstraints();
  }

  @override
  void dispose() {
    lowerLimitCtrl.dispose();
    upperLimitCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchConstraints() async {
    try {
      final res = await ref
          .read(dioProvider)
          .get('/constraints/', queryParameters: {'event': widget.eventId});
      List<dynamic> data = [];
      if (res.data is List)
        data = res.data;
      else if (res.data is Map && res.data['results'] != null)
        data = res.data['results'];

      if (data.isNotEmpty) {
        _constraint = data.first;
        bookingType =
            _constraint!['booking_type']?.toString().toLowerCase() ?? 'single';
        lowerLimitCtrl.text = _constraint!['lower_limit']?.toString() ?? '1';
        upperLimitCtrl.text = _constraint!['upper_limit']?.toString() ?? '1';
        isFixed = _constraint!['fixed'] == true;
      }
    } catch (_) {}
    if (mounted) setState(() => _isFetching = false);
  }

  @override
  Widget build(BuildContext context) {
    final bool exists = _constraint != null;

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
          exists ? 'Edit Constraints' : 'Add Constraints',
          style: GoogleFonts.breeSerif(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isFetching
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFECF65)))
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              value: bookingType,
                              dropdownColor: const Color(0xFF16151A),
                              style: GoogleFonts.breeSerif(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Booking Type',
                                labelStyle: GoogleFonts.breeSerif(color: Colors.white54),
                                filled: true,
                                fillColor: const Color(0xFF16151A),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Color(0xFFFECF65)),
                                ),
                              ),
                              items: [
                                DropdownMenuItem(value: 'single', child: Text('Single', style: GoogleFonts.breeSerif())),
                                DropdownMenuItem(value: 'multiple', child: Text('Multiple', style: GoogleFonts.breeSerif())),
                              ],
                              onChanged: (v) => setState(() => bookingType = v!),
                            ),
                            if (bookingType == 'multiple') ...[
                              const SizedBox(height: 20),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF16151A),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                                ),
                                child: SwitchListTile(
                                  title: Text(
                                    'Fixed Size Team',
                                    style: GoogleFonts.breeSerif(color: Colors.white, fontSize: 15),
                                  ),
                                  activeColor: const Color(0xFFFECF65),
                                  value: isFixed,
                                  onChanged: (v) => setState(() => isFixed = v),
                                ),
                              ),
                              const SizedBox(height: 20),
                               Row(
                                children: [
                                  if (!isFixed) ...[
                                    Expanded(
                                      child: TextField(
                                        controller: lowerLimitCtrl,
                                        keyboardType: TextInputType.number,
                                        style: GoogleFonts.breeSerif(color: Colors.white),
                                        decoration: InputDecoration(
                                          labelText: 'Minimum Team Size',
                                          labelStyle: GoogleFonts.breeSerif(color: Colors.white54),
                                          filled: true,
                                          fillColor: const Color(0xFF16151A),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: const BorderSide(color: Color(0xFFFECF65)),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                  ],
                                  Expanded(
                                    child: TextField(
                                      controller: upperLimitCtrl,
                                      keyboardType: TextInputType.number,
                                      style: GoogleFonts.breeSerif(color: Colors.white),
                                      decoration: InputDecoration(
                                        labelText: isFixed ? 'Fixed Team Size' : 'Maximum Team Size',
                                        labelStyle: GoogleFonts.breeSerif(color: Colors.white54),
                                        filled: true,
                                        fillColor: const Color(0xFF16151A),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: const BorderSide(color: Color(0xFFFECF65)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
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
                        onPressed: _isLoading
                            ? null
                            : () async {
                                if (bookingType == 'multiple') {
                                  if (isFixed) {
                                    final val = int.tryParse(upperLimitCtrl.text);
                                    if (val == null || val <= 0) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Please enter a valid fixed team size (> 0)')),
                                      );
                                      return;
                                    }
                                  } else {
                                    final minVal = int.tryParse(lowerLimitCtrl.text);
                                    final maxVal = int.tryParse(upperLimitCtrl.text);
                                    if (minVal == null || minVal <= 0) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Please enter a valid minimum team size (> 0)')),
                                      );
                                      return;
                                    }
                                    if (maxVal == null || maxVal <= 0) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Please enter a valid maximum team size (> 0)')),
                                      );
                                      return;
                                    }
                                    if (minVal > maxVal) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Minimum team size cannot be greater than maximum team size')),
                                      );
                                      return;
                                    }
                                  }
                                }
                                setState(() => _isLoading = true);
                                try {
                                  final Map<String, dynamic> payload = {
                                    "event": widget.eventId,
                                    "booking_type": bookingType,
                                    "fixed": bookingType == 'multiple' ? isFixed : false,
                                  };

                                  if (bookingType == 'multiple') {
                                    if (isFixed) {
                                      payload["upper_limit"] = int.parse(upperLimitCtrl.text);
                                    } else {
                                      payload["lower_limit"] = int.parse(lowerLimitCtrl.text);
                                      payload["upper_limit"] = int.parse(upperLimitCtrl.text);
                                    }
                                  }

                                  payload.removeWhere((k, v) => v == null || v == "");

                                  if (exists) {
                                    await ref
                                        .read(dioProvider)
                                        .put(
                                          '/constraints/${_constraint!['id']}/',
                                          data: payload,
                                        );
                                  } else {
                                    await ref
                                        .read(dioProvider)
                                        .post('/constraints/', data: payload);
                                  }
                                  if (mounted) {
                                    Navigator.pop(context);
                                    ref.invalidate(manageEventsProvider);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Constraints saved successfully', style: GoogleFonts.breeSerif()),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed: $e', style: GoogleFonts.breeSerif()),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                } finally {
                                  if (mounted) setState(() => _isLoading = false);
                                }
                              },
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                              )
                            : Text(
                                'Save Constraints',
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

// --------------------------------------------------------------------------
// SLOTS FULL SCREEN LIST + FORM Scaffold
// --------------------------------------------------------------------------
class _SlotsListModal extends ConsumerStatefulWidget {
  final int eventId;
  const _SlotsListModal({required this.eventId});
  @override
  ConsumerState<_SlotsListModal> createState() => _SlotsListModalState();
}

class _SlotsListModalState extends ConsumerState<_SlotsListModal> {
  bool _isFetching = true;
  List<dynamic> _slots = [];

  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final _capacityCtrl = TextEditingController();
  bool _isUnlimited = false;
  bool _isLoading = false;
  int? _editingSlotId;

  @override
  void initState() {
    super.initState();
    _fetchSlots();
  }

  @override
  void dispose() {
    _capacityCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchSlots() async {
    try {
      final res = await ref
          .read(dioProvider)
          .get('/event-slots/', queryParameters: {'event_id': widget.eventId});
      if (res.data is List) {
        _slots = res.data;
      } else if (res.data is Map && res.data['results'] != null) {
        _slots = res.data['results'];
      }
    } catch (_) {
      try {
        final res2 = await ref
            .read(dioProvider)
            .get('/slots/', queryParameters: {'event': widget.eventId});
        if (res2.data is List)
          _slots = res2.data;
        else if (res2.data is Map && res2.data['results'] != null)
          _slots = res2.data['results'];
      } catch (_) {}
    }
    if (mounted) setState(() => _isFetching = false);
  }

  void _editSlot(Map<String, dynamic> slot) {
    setState(() {
      _editingSlotId = slot['id'];
      _selectedDate = slot['date'] != null ? DateTime.tryParse(slot['date']) : null;
      _startTime = slot['start_time'] != null
          ? TimeOfDay(
              hour: int.tryParse(slot['start_time'].split(':')[0]) ?? 0,
              minute: int.tryParse(slot['start_time'].split(':')[1]) ?? 0,
            )
          : null;
      _endTime = slot['end_time'] != null
          ? TimeOfDay(
              hour: int.tryParse(slot['end_time'].split(':')[0]) ?? 0,
              minute: int.tryParse(slot['end_time'].split(':')[1]) ?? 0,
            )
          : null;
      _isUnlimited = slot['unlimited_participants'] == true;
      _capacityCtrl.text = _isUnlimited
          ? ''
          : (slot['max_participants']?.toString() ??
                slot['available_participants']?.toString() ??
                '');
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingSlotId = null;
      _selectedDate = null;
      _startTime = null;
      _endTime = null;
      _capacityCtrl.clear();
      _isUnlimited = false;
    });
  }

  Future<void> _submitSlot() async {
    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioProvider);
      final Map<String, dynamic> payload = {
        "event": widget.eventId,
        if (_selectedDate != null)
          "date":
              "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}",
        if (_startTime != null)
          "start_time":
              "${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}:00",
        if (_endTime != null)
          "end_time":
              "${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}:00",
        "unlimited_participants": _isUnlimited,
      };
      if (!_isUnlimited && _capacityCtrl.text.isNotEmpty) {
        payload["max_participants"] = int.tryParse(_capacityCtrl.text);
      }

      if (_editingSlotId == null) {
        await dio.post('/event-slots/', data: payload);
      } else {
        await dio.put('/event-slots/$_editingSlotId/', data: payload);
      }

      if (mounted) {
        _cancelEdit();
        ref.invalidate(manageEventsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _editingSlotId == null ? 'Slot added' : 'Slot updated',
              style: GoogleFonts.breeSerif(),
            ),
            backgroundColor: Colors.green,
          ),
        );
        await _fetchSlots();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e', style: GoogleFonts.breeSerif()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSlot(int id) async {
    try {
      await ref.read(dioProvider).delete('/event-slots/$id/');
      if (mounted) {
        ref.invalidate(manageEventsProvider);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Slot deleted', style: GoogleFonts.breeSerif())));
        await _fetchSlots();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete: $e', style: GoogleFonts.breeSerif())));
      }
    }
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
          'Manage Slots',
          style: GoogleFonts.breeSerif(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isFetching
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFECF65)))
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Slots List
                    Expanded(
                      child: _slots.isEmpty
                          ? Center(
                              child: Text(
                                'No slots configured yet.',
                                style: GoogleFonts.breeSerif(color: Colors.white38),
                              ),
                            )
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: _slots.length,
                              itemBuilder: (ctx, i) {
                                final slot = _slots[i];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF16151A),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              slot['date'] ?? 'N/A',
                                              style: GoogleFonts.breeSerif(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${slot['start_time']} - ${slot['end_time']}',
                                              style: GoogleFonts.breeSerif(
                                                color: Colors.white70,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              slot['unlimited_participants'] == true
                                                  ? 'Unlimited Capacity'
                                                  : 'Capacity: ${slot['max_participants'] ?? slot['available_participants']}',
                                              style: GoogleFonts.breeSerif(
                                                color: const Color(0xFFFECF65),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.white54, size: 20),
                                            onPressed: () => _editSlot(slot),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                            onPressed: () => _deleteSlot(slot['id']),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    const Divider(color: Colors.white10, height: 24),

                    // Slot Form
                    Text(
                      _editingSlotId == null ? 'Add Time Slot' : 'Edit Time Slot',
                      style: GoogleFonts.breeSerif(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.dark(
                                        primary: Color(0xFFFECF65),
                                        onPrimary: Colors.black,
                                        surface: Color(0xFF16151A),
                                        onSurface: Colors.white,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (d != null) setState(() => _selectedDate = d);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16151A),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.05)),
                              ),
                              child: Text(
                                _selectedDate != null
                                    ? "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}"
                                    : "Select Date",
                                style: GoogleFonts.breeSerif(
                                  color: _selectedDate != null ? Colors.white : Colors.white54,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final t = await showTimePicker(
                                context: context,
                                initialTime: _startTime ?? TimeOfDay.now(),
                              );
                              if (t != null) setState(() => _startTime = t);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16151A),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.05)),
                              ),
                              child: Text(
                                _startTime != null ? _startTime!.format(context) : "Start Time",
                                style: GoogleFonts.breeSerif(
                                  color: _startTime != null ? Colors.white : Colors.white54,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final t = await showTimePicker(
                                context: context,
                                initialTime: _endTime ?? TimeOfDay.now(),
                              );
                              if (t != null) setState(() => _endTime = t);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16151A),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.05)),
                              ),
                              child: Text(
                                _endTime != null ? _endTime!.format(context) : "End Time",
                                style: GoogleFonts.breeSerif(
                                  color: _endTime != null ? Colors.white : Colors.white54,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _capacityCtrl,
                            keyboardType: TextInputType.number,
                            style: GoogleFonts.breeSerif(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Capacity',
                              labelStyle: GoogleFonts.breeSerif(color: Colors.white54),
                              filled: true,
                              fillColor: const Color(0xFF16151A),
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
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SwitchListTile(
                            title: Text(
                              'Unlimited',
                              style: GoogleFonts.breeSerif(color: Colors.white54, fontSize: 13),
                            ),
                            activeColor: const Color(0xFFFECF65),
                            value: _isUnlimited,
                            onChanged: (v) => setState(() => _isUnlimited = v),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
                        onPressed: _isLoading ? null : _submitSlot,
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                              )
                            : Text(
                                _editingSlotId == null ? 'Add Slot' : 'Save Slot',
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
