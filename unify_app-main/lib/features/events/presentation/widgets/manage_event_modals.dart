import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/manage_events_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:unify_events/shared/widgets/app_cached_image.dart';

class ManageEventModals {
  static Future<void> showDeleteEventModal(
    BuildContext context,
    WidgetRef ref,
    int eventId,
    String eventName,
  ) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => _DeleteEventFullScreen(
          eventId: eventId,
          eventName: eventName,
        ),
      ),
    );
  }

  static Future<void> showOrganisersModal(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> event,
  ) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => _OrganisersSplitFullScreen(event: event),
      ),
    );
  }

  static void showEventModal(
    BuildContext context,
    WidgetRef ref, {
    Map<String, dynamic>? event,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => _EventFormModal(event: event),
      ),
    );
  }
}

// --------------------------------------------------------------------------
// DELETE EVENT FULL SCREEN CONFIRMATION
// --------------------------------------------------------------------------
class _DeleteEventFullScreen extends ConsumerStatefulWidget {
  final int eventId;
  final String eventName;

  const _DeleteEventFullScreen({
    required this.eventId,
    required this.eventName,
  });

  @override
  ConsumerState<_DeleteEventFullScreen> createState() => _DeleteEventFullScreenState();
}

class _DeleteEventFullScreenState extends ConsumerState<_DeleteEventFullScreen> {
  bool _isLoading = false;

  Future<void> _deleteEvent() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(dioProvider).delete('/events/${widget.eventId}/');
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event Deleted successfully', style: GoogleFonts.breeSerif()),
            backgroundColor: Colors.redAccent,
          ),
        );
        ref.invalidate(manageEventsProvider);
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
      ),
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
                  color: Colors.redAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_forever_outlined,
                  color: Colors.redAccent,
                  size: 48,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Delete ${widget.eventName}?',
                textAlign: TextAlign.center,
                style: GoogleFonts.breeSerif(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'This action cannot be undone. Are you sure you want to permanently delete this event and all associated bookings?',
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
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isLoading ? null : _deleteEvent,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Delete Event',
                          style: GoogleFonts.breeSerif(
                            color: Colors.white,
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
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Cancel',
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
  }
}

// --------------------------------------------------------------------------
// ORGANISERS SPLIT FULL SCREEN
// --------------------------------------------------------------------------
class _OrganisersSplitFullScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> event;
  const _OrganisersSplitFullScreen({required this.event});
  @override
  ConsumerState<_OrganisersSplitFullScreen> createState() =>
      _OrganisersSplitFullScreenState();
}

class _OrganisersSplitFullScreenState extends ConsumerState<_OrganisersSplitFullScreen> {
  List<int> _assignedIds = [];
  bool _isLoading = false;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _assignedIds = List<int>.from(widget.event['organisers'] ?? []);
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      await ref
          .read(dioProvider)
          .patch(
            '/events/${widget.event['id']}/',
            data: {"organisers": _assignedIds},
          );
      if (mounted) {
        Navigator.pop(context);
        ref.invalidate(manageEventsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Organisers saved successfully!', style: GoogleFonts.breeSerif()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      String errMsg = e.toString();
      if (e is DioError)
        errMsg = e.response?.data?.toString() ?? e.message ?? "Unknown error";
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $errMsg', style: GoogleFonts.breeSerif()),
            backgroundColor: Colors.redAccent,
          ),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final organisersAsync = ref.watch(organisersProvider);

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
          'Manage Organisers',
          style: GoogleFonts.breeSerif(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Color(0xFFFECF65), strokeWidth: 2),
                  )
                : Text(
                    'Save',
                    style: GoogleFonts.breeSerif(
                      color: const Color(0xFFFECF65),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Field
              TextField(
                style: GoogleFonts.breeSerif(color: Colors.white),
                onChanged: (v) => setState(() => _search = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search available organizers...',
                  hintStyle: GoogleFonts.breeSerif(color: Colors.white38),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFFFECF65)),
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

              // Assigned Organisers List
              Text(
                'Assigned Organisers',
                style: GoogleFonts.breeSerif(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: organisersAsync.when(
                  data: (allOrganisers) {
                    final assignedList = allOrganisers
                        .where((o) => _assignedIds.contains(o['id']))
                        .toList();

                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF16151A),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: assignedList.isEmpty
                          ? Center(
                              child: Text(
                                'No organisers assigned yet.',
                                style: GoogleFonts.breeSerif(color: Colors.white38),
                              ),
                            )
                          : ListView.builder(
                              itemCount: assignedList.length,
                              itemBuilder: (ctx, i) => ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFFFECF65).withOpacity(0.1),
                                  child: const Icon(Icons.person, color: Color(0xFFFECF65)),
                                ),
                                title: Text(
                                  assignedList[i]['user_display'] ?? 'ID: ${assignedList[i]['id']}',
                                  style: GoogleFonts.breeSerif(color: Colors.white),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                                  onPressed: () => setState(
                                    () => _assignedIds.remove(assignedList[i]['id']),
                                  ),
                                ),
                              ),
                            ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFECF65))),
                  error: (_, __) => Center(
                    child: Text('Failed to load organisers', style: GoogleFonts.breeSerif(color: Colors.redAccent)),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Available Organisers List
              Text(
                'Available Organisers',
                style: GoogleFonts.breeSerif(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: organisersAsync.when(
                  data: (allOrganisers) {
                    final available = allOrganisers
                        .where(
                          (o) =>
                              !_assignedIds.contains(o['id']) &&
                              (o['user_display']?.toString().toLowerCase().contains(_search) ?? false),
                        )
                        .toList();

                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF16151A),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: available.isEmpty
                          ? Center(
                              child: Text(
                                'No other organisers available.',
                                style: GoogleFonts.breeSerif(color: Colors.white38),
                              ),
                            )
                          : ListView.builder(
                              itemCount: available.length,
                              itemBuilder: (ctx, i) => ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.white.withOpacity(0.05),
                                  child: const Icon(Icons.person, color: Colors.white54),
                                ),
                                title: Text(
                                  available[i]['user_display'] ?? 'ID: ${available[i]['id']}',
                                  style: GoogleFonts.breeSerif(color: Colors.white),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.add_circle, color: Color(0xFFFECF65)),
                                  onPressed: () => setState(
                                    () => _assignedIds.add(available[i]['id']),
                                  ),
                                ),
                              ),
                            ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFECF65))),
                  error: (_, __) => const SizedBox(),
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
// EVENT FORM FULL SCREEN SCREEN
// --------------------------------------------------------------------------
class _EventFormModal extends ConsumerStatefulWidget {
  final Map<String, dynamic>? event;
  const _EventFormModal({this.event});
  @override
  ConsumerState<_EventFormModal> createState() => _EventFormModalState();
}

class _EventFormModalState extends ConsumerState<_EventFormModal> {
  late TextEditingController _nameCtrl;
  late TextEditingController _committeeCtrl;
  late TextEditingController _priceCtrl;
  int? _selectedParentEventId;
  int? _selectedCategoryId;
  bool _isExclusive = false;
  File? _imageFile;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.event?['name']?.toString() ?? '');
    _committeeCtrl = TextEditingController(text: widget.event?['parent_committee']?.toString() ?? '');
    _priceCtrl = TextEditingController(text: widget.event?['price']?.toString() ?? '');

    _selectedParentEventId = widget.event?['parent_event'] is int
        ? widget.event!['parent_event']
        : int.tryParse(widget.event?['parent_event']?.toString() ?? '');
    _selectedCategoryId = widget.event?['category'] is int
        ? widget.event!['category']
        : int.tryParse(widget.event?['category']?.toString() ?? '');
    _isExclusive = widget.event?['exclusivity'] == true || widget.event?['exclusivity'] == 'EXCLUSIVE';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _committeeCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      FormData fd = FormData();
      Map<String, dynamic> payload = {};

      if (widget.event == null) {
        if (_nameCtrl.text.isNotEmpty) payload["name"] = _nameCtrl.text;
        if (_committeeCtrl.text.isNotEmpty) payload["parent_committee"] = _committeeCtrl.text;
        if (_selectedParentEventId != null) payload["parent_event"] = _selectedParentEventId;
        if (_selectedCategoryId != null) payload["category"] = _selectedCategoryId;
        if (_priceCtrl.text.isNotEmpty) payload["price"] = int.tryParse(_priceCtrl.text) ?? 0;
        payload["exclusivity"] = _isExclusive ? "true" : "false";
      } else {
        if (_nameCtrl.text != widget.event!['name']) payload["name"] = _nameCtrl.text;
        if (_committeeCtrl.text != widget.event!['parent_committee']?.toString())
          payload["parent_committee"] = _committeeCtrl.text;
        if (_selectedParentEventId != widget.event!['parent_event']) payload["parent_event"] = _selectedParentEventId;
        if (_selectedCategoryId != widget.event!['category']) payload["category"] = _selectedCategoryId;
        if (int.tryParse(_priceCtrl.text) != widget.event!['price']) payload["price"] = int.tryParse(_priceCtrl.text) ?? 0;
        final exc = _isExclusive ? "true" : "false";
        if (exc != widget.event!['exclusivity']?.toString().toLowerCase()) payload["exclusivity"] = exc;
      }

      for (var entry in payload.entries) {
        if (entry.value != null && entry.value.toString().isNotEmpty) {
          fd.fields.add(MapEntry(entry.key, entry.value.toString()));
        }
      }

      if (_imageFile != null) {
        fd.files.add(
          MapEntry("image", await MultipartFile.fromFile(_imageFile!.path)),
        );
      }

      final dio = ref.read(dioProvider);
      if (widget.event == null) {
        await dio.post('/events/', data: fd);
      } else {
        await dio.patch('/events/${widget.event!['id']}/', data: fd);
      }

      if (mounted) {
        Navigator.pop(context);
        ref.invalidate(manageEventsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event saved successfully!', style: GoogleFonts.breeSerif()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      String errMsg = e.toString();
      if (e is DioError) errMsg = e.response?.data?.toString() ?? e.message ?? "Unknown error";
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $errMsg', style: GoogleFonts.breeSerif()),
            backgroundColor: Colors.redAccent,
          ),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final parentEventsAsync = ref.watch(parentEventsProvider);

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
          widget.event == null ? 'Create Event' : 'Edit Event',
          style: GoogleFonts.breeSerif(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildField('Event Name', _nameCtrl),
              const SizedBox(height: 20),
              _buildField('Parent Committee ID (optional)', _committeeCtrl),
              const SizedBox(height: 20),

              categoriesAsync.when(
                data: (cats) => DropdownButtonFormField<int>(
                  value: _selectedCategoryId,
                  dropdownColor: const Color(0xFF16151A),
                  style: GoogleFonts.breeSerif(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Category',
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
                  items: cats
                      .map(
                        (c) => DropdownMenuItem<int>(
                          value: c['id'],
                          child: Text(c['name'] ?? 'ID: ${c['id']}', style: GoogleFonts.breeSerif()),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCategoryId = v),
                ),
                loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFECF65))),
                error: (_, __) => Text(
                  'Failed to load categories',
                  style: GoogleFonts.breeSerif(color: Colors.redAccent),
                ),
              ),
              const SizedBox(height: 20),

              parentEventsAsync.when(
                data: (parents) => DropdownButtonFormField<int>(
                  value: _selectedParentEventId,
                  dropdownColor: const Color(0xFF16151A),
                  style: GoogleFonts.breeSerif(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Parent Event (optional)',
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
                    DropdownMenuItem<int>(
                      value: null,
                      child: Text("None", style: GoogleFonts.breeSerif()),
                    ),
                    ...parents.map(
                      (p) => DropdownMenuItem<int>(
                        value: p['id'],
                        child: Text(p['name'] ?? 'ID: ${p['id']}', style: GoogleFonts.breeSerif()),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _selectedParentEventId = v),
                ),
                loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFECF65))),
                error: (_, __) => Text(
                  'Failed to load parent events',
                  style: GoogleFonts.breeSerif(color: Colors.redAccent),
                ),
              ),
              const SizedBox(height: 20),

              _buildField('Price (₹)', _priceCtrl, isNum: true),
              const SizedBox(height: 20),

              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF16151A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: SwitchListTile(
                  title: Text(
                    'Exclusive Event',
                    style: GoogleFonts.breeSerif(color: Colors.white, fontSize: 15),
                  ),
                  activeColor: const Color(0xFFFECF65),
                  value: _isExclusive,
                  onChanged: (v) => setState(() => _isExclusive = v),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Event Banner Image',
                style: GoogleFonts.breeSerif(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFF16151A),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _imageFile != null
                      ? Image.file(_imageFile!, fit: BoxFit.cover)
                      : (widget.event?['image_key'] != null && widget.event!['image_key'].toString().isNotEmpty)
                          ? AppCachedImage(
                              imageKey: widget.event!['image_key'],
                              fit: BoxFit.cover,
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_photo_alternate_outlined, color: Color(0xFFFECF65), size: 40),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Upload Image (Tap here)',
                                    style: GoogleFonts.breeSerif(color: Colors.white38, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                ),
              ),
              const SizedBox(height: 40),

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
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                        )
                      : Text(
                          'Save Event',
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

  Widget _buildField(
    String label,
    TextEditingController ctrl, {
    bool isNum = false,
  }) {
    return TextField(
      controller: ctrl,
      style: GoogleFonts.breeSerif(color: Colors.white),
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
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
    );
  }
}
