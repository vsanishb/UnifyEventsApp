import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../events/presentation/providers/manage_events_provider.dart';

// Raw Pointer Listener to apply scale animation without intercepting child button taps
class CardPressWrapper extends StatefulWidget {
  final Widget child;
  const CardPressWrapper({super.key, required this.child});

  @override
  State<CardPressWrapper> createState() => _CardPressWrapperState();
}

class _CardPressWrapperState extends State<CardPressWrapper> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _scale = 0.98),
      onPointerUp: (_) => setState(() => _scale = 1.0),
      onPointerCancel: (_) => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class OrganiserAssignmentPage extends ConsumerStatefulWidget {
  final String eventId;
  const OrganiserAssignmentPage({super.key, required this.eventId});

  @override
  ConsumerState<OrganiserAssignmentPage> createState() => _OrganiserAssignmentPageState();
}

class _OrganiserAssignmentPageState extends ConsumerState<OrganiserAssignmentPage> {
  Map<String, dynamic>? _event;
  List<dynamic> _allOrganisers = [];
  List<int> _assignedIds = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String _assignedSearch = '';
  String _availableSearch = '';

  final TextEditingController _assignedSearchController = TextEditingController();
  final TextEditingController _availableSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _assignedSearchController.dispose();
    _availableSearchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // DATA LOADING
  // ---------------------------------------------------------------------------

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioProvider);
      
      // Fetch event detail
      final eventRes = await dio.get('/events/${widget.eventId}/');
      _event = eventRes.data;
      _assignedIds = List<int>.from(_event?['organisers'] ?? []);

      // Fetch all organisers
      final orgsRes = await dio.get('/organisers/');
      if (orgsRes.data is List) {
        _allOrganisers = orgsRes.data;
      } else {
        _allOrganisers = orgsRes.data['results'] ?? [];
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load details: ${e.toString()}');
    }
  }

  // ---------------------------------------------------------------------------
  // ASSIGNMENT OPERATIONS
  // ---------------------------------------------------------------------------

  Future<void> _updateOrganisers(List<int> newIds, String message) async {
    setState(() => _isSaving = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/events/${widget.eventId}/', data: {
        'organisers': newIds,
      });

      setState(() {
        _assignedIds = newIds;
        _isSaving = false;
      });

      ref.invalidate(manageEventsProvider);
      _showSuccessSnackBar(message);
    } catch (e) {
      setState(() => _isSaving = false);
      String errMsg = 'Failed to update organisers';
      if (e is DioError) {
        errMsg = e.response?.data?['detail'] ?? e.message ?? errMsg;
      }
      _showErrorSnackBar(errMsg);
    }
  }

  // ---------------------------------------------------------------------------
  // SNACKBARS & CONFIRMATIONS
  // ---------------------------------------------------------------------------

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.breeSerif(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.breeSerif(color: Colors.white)),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmRemove(dynamic organiser) {
    final String name = organiser['name'] ?? organiser['username'] ?? 'Organiser';
    final String eventName = _event?['name'] ?? 'Event';
    final int id = organiser['id'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16151A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Remove from Event',
          style: GoogleFonts.breeSerif(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Remove $name from $eventName?',
          style: GoogleFonts.breeSerif(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.breeSerif(color: Colors.white38),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              final newIds = List<int>.from(_assignedIds)..remove(id);
              _updateOrganisers(newIds, '$name removed from event assignment.');
            },
            child: Text(
              'Confirm',
              style: GoogleFonts.breeSerif(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmAssign(dynamic organiser) {
    final String name = organiser['name'] ?? organiser['username'] ?? 'Organiser';
    final String eventName = _event?['name'] ?? 'Event';
    final int id = organiser['id'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16151A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Assign to Event',
          style: GoogleFonts.breeSerif(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Assign $name to $eventName?',
          style: GoogleFonts.breeSerif(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.breeSerif(color: Colors.white38),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFECF65),
              foregroundColor: const Color(0xFF0F0E11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              final newIds = List<int>.from(_assignedIds)..add(id);
              _updateOrganisers(newIds, '$name assigned to event successfully.');
            },
            child: Text(
              'Confirm',
              style: GoogleFonts.breeSerif(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String name) {
    final String initials;
    if (name.isEmpty) {
      initials = '?';
    } else {
      final parts = name.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else if (parts[0].isNotEmpty) {
        initials = parts[0][0].toUpperCase();
      } else {
        initials = '?';
      }
    }

    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFFFECF65), Color(0xFFF97316)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.breeSerif(
          color: const Color(0xFF0F0E11),
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MAIN BUILD METHOD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isAdmin = user != null && user.role == 'admin';

    if (!isAdmin) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0E11),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.gpp_bad, color: Colors.redAccent, size: 64),
              const SizedBox(height: 16),
              Text(
                '403 Forbidden',
                style: GoogleFonts.breeSerif(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Only admins are authorized to assign event organisers.',
                style: GoogleFonts.breeSerif(color: Colors.white54, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0E11),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFECF65))),
      );
    }

    // Filter assigned and available organisers
    final assignedOrgs = _allOrganisers.where((org) {
      final id = org['id'] as int;
      if (!_assignedIds.contains(id)) return false;
      if (_assignedSearch.isEmpty) return true;
      final name = (org['name'] ?? '').toString().toLowerCase();
      final username = (org['username'] ?? '').toString().toLowerCase();
      final email = (org['email'] ?? '').toString().toLowerCase();
      return name.contains(_assignedSearch) ||
          username.contains(_assignedSearch) ||
          email.contains(_assignedSearch);
    }).toList();

    final availableOrgs = _allOrganisers.where((org) {
      final id = org['id'] as int;
      if (_assignedIds.contains(id)) return false;
      if (_availableSearch.isEmpty) return true;
      final name = (org['name'] ?? '').toString().toLowerCase();
      final username = (org['username'] ?? '').toString().toLowerCase();
      final email = (org['email'] ?? '').toString().toLowerCase();
      return name.contains(_availableSearch) ||
          username.contains(_availableSearch) ||
          email.contains(_availableSearch);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0E11),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0E11),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ORGANISER ASSIGNMENT',
          style: GoogleFonts.breeSerif(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Event Header Card - Premium Restructured
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16151A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.08),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFECF65).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.event_available,
                          color: Color(0xFFFECF65),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _event?['name'] ?? 'Unnamed Event',
                              style: GoogleFonts.breeSerif(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18, // Larger title
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _event?['parent_committee'] ?? 'Main Committee',
                              style: GoogleFonts.breeSerif(
                                color: Colors.white38, // Smaller subtitle
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Splits
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final useSplitScreen = constraints.maxWidth > 700;

                      if (useSplitScreen) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: _buildAssignedSection(assignedOrgs)),
                            const SizedBox(width: 24),
                            Expanded(child: _buildAvailableSection(availableOrgs)),
                          ],
                        );
                      } else {
                        return DefaultTabController(
                          length: 2,
                          child: Column(
                            children: [
                              // Premium segmented tab control
                              Container(
                                height: 46,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF16151A),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: TabBar(
                                  dividerColor: Colors.transparent,
                                  indicatorSize: TabBarIndicatorSize.tab,
                                  indicator: BoxDecoration(
                                    color: const Color(0xFFFECF65),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  labelColor: const Color(0xFF0F0E11),
                                  unselectedLabelColor: Colors.white54,
                                  labelStyle: GoogleFonts.breeSerif(fontWeight: FontWeight.bold, fontSize: 13),
                                  unselectedLabelStyle: GoogleFonts.breeSerif(fontWeight: FontWeight.bold, fontSize: 13),
                                  tabs: [
                                    Tab(text: 'Assigned (${assignedOrgs.length})'),
                                    Tab(text: 'Available (${availableOrgs.length})'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: TabBarView(
                                  children: [
                                    _buildAssignedSection(assignedOrgs, showHeader: false),
                                    _buildAvailableSection(availableOrgs, showHeader: false),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_isSaving)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFFFECF65)),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION BUILDERS
  // ---------------------------------------------------------------------------

  Widget _buildAssignedSection(List<dynamic> list, {bool showHeader = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader) ...[
          Text(
            'Assigned Organisers (${list.length})',
            style: GoogleFonts.breeSerif(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
        ],
        // Search bar with Rounded 20
        TextField(
          controller: _assignedSearchController,
          style: GoogleFonts.breeSerif(color: Colors.white, fontSize: 14),
          onChanged: (v) => setState(() => _assignedSearch = v.toLowerCase()),
          decoration: InputDecoration(
            hintText: 'Search assigned...',
            hintStyle: GoogleFonts.breeSerif(color: Colors.white38, fontSize: 13),
            prefixIcon: const Icon(Icons.search, color: Color(0xFFFECF65), size: 18),
            filled: true,
            fillColor: const Color(0xFF16151A),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.03)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Color(0xFFFECF65)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // List
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF16151A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.04)),
            ),
            child: list.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.people_outline,
                            color: Colors.white38,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No assigned organisers found',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.breeSerif(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Assign organisers from the Available tab.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.breeSerif(
                              color: Colors.white38,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: list.length,
                    itemBuilder: (ctx, i) {
                      final org = list[i];
                      final String name = org['name'] ?? org['username'] ?? 'Organiser';
                      final String username = org['username'] ?? '';
                      final String email = org['email'] ?? '';

                      return CardPressWrapper(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F0E11),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.03)),
                          ),
                          child: Row(
                            children: [
                              _buildAvatar(name),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: GoogleFonts.breeSerif(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (username.isNotEmpty)
                                      Text(
                                        '@$username',
                                        style: GoogleFonts.breeSerif(color: Colors.white54, fontSize: 11),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    if (email.isNotEmpty)
                                      Text(
                                        email,
                                        style: GoogleFonts.breeSerif(color: Colors.white38, fontSize: 11),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 22),
                                onPressed: () => _confirmRemove(org),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableSection(List<dynamic> list, {bool showHeader = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader) ...[
          Text(
            'Available Organisers (${list.length})',
            style: GoogleFonts.breeSerif(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
        ],
        // Search bar with Rounded 20
        TextField(
          controller: _availableSearchController,
          style: GoogleFonts.breeSerif(color: Colors.white, fontSize: 14),
          onChanged: (v) => setState(() => _availableSearch = v.toLowerCase()),
          decoration: InputDecoration(
            hintText: 'Search available...',
            hintStyle: GoogleFonts.breeSerif(color: Colors.white38, fontSize: 13),
            prefixIcon: const Icon(Icons.search, color: Color(0xFFFECF65), size: 18),
            filled: true,
            fillColor: const Color(0xFF16151A),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.03)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Color(0xFFFECF65)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // List
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF16151A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.04)),
            ),
            child: list.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.people_outline,
                            color: Colors.white38,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No available organisers found',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.breeSerif(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'All system organisers are already assigned.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.breeSerif(
                              color: Colors.white38,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: list.length,
                    itemBuilder: (ctx, i) {
                      final org = list[i];
                      final String name = org['name'] ?? org['username'] ?? 'Organiser';
                      final String username = org['username'] ?? '';
                      final String email = org['email'] ?? '';

                      return CardPressWrapper(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F0E11),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.03)),
                          ),
                          child: Row(
                            children: [
                              _buildAvatar(name),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: GoogleFonts.breeSerif(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (username.isNotEmpty)
                                      Text(
                                        '@$username',
                                        style: GoogleFonts.breeSerif(color: Colors.white54, fontSize: 11),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    if (email.isNotEmpty)
                                      Text(
                                        email,
                                        style: GoogleFonts.breeSerif(color: Colors.white38, fontSize: 11),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: Color(0xFFFECF65), size: 22),
                                onPressed: () => _confirmAssign(org),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
