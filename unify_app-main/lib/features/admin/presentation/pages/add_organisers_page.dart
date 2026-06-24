import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

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

class AddOrganisersPage extends ConsumerStatefulWidget {
  const AddOrganisersPage({super.key});

  @override
  ConsumerState<AddOrganisersPage> createState() => _AddOrganisersPageState();
}

class _AddOrganisersPageState extends ConsumerState<AddOrganisersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Organisers Tab state
  final List<dynamic> _organisers = [];
  bool _isLoadingOrganisers = false;
  bool _isLoadingMoreOrganisers = false;
  String _organiserSearch = '';
  int _organiserPage = 1;
  bool _hasMoreOrganisers = true;
  final ScrollController _organiserScrollController = ScrollController();
  final TextEditingController _organiserSearchController = TextEditingController();

  // Non-Organisers Tab state
  final List<dynamic> _nonOrganisers = [];
  bool _isLoadingNonOrganisers = false;
  bool _isLoadingMoreNonOrganisers = false;
  String _nonOrganiserSearch = '';
  int _nonOrganiserPage = 1;
  bool _hasMoreNonOrganisers = true;
  final ScrollController _nonOrganiserScrollController = ScrollController();
  final TextEditingController _nonOrganiserSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Fetch initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchOrganisers(refresh: true);
      _fetchNonOrganisers(refresh: true);
    });

    // Listen to scrolls for pagination
    _organiserScrollController.addListener(() {
      if (_organiserScrollController.position.pixels >=
          _organiserScrollController.position.maxScrollExtent - 200) {
        _fetchOrganisers();
      }
    });

    _nonOrganiserScrollController.addListener(() {
      if (_nonOrganiserScrollController.position.pixels >=
          _nonOrganiserScrollController.position.maxScrollExtent - 200) {
        _fetchNonOrganisers();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _organiserScrollController.dispose();
    _organiserSearchController.dispose();
    _nonOrganiserScrollController.dispose();
    _nonOrganiserSearchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // API FETCH METHODS
  // ---------------------------------------------------------------------------

  Future<void> _fetchOrganisers({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _organiserPage = 1;
        _organisers.clear();
        _hasMoreOrganisers = true;
        _isLoadingOrganisers = true;
      });
    } else {
      if (_isLoadingMoreOrganisers || !_hasMoreOrganisers || _isLoadingOrganisers) return;
      setState(() => _isLoadingMoreOrganisers = true);
    }

    try {
      final dio = ref.read(dioProvider);
      final queryParams = {
        'page': _organiserPage,
        'search': _organiserSearch,
      };
      final res = await dio.get('/organisers/', queryParameters: queryParams);

      final List<dynamic> newItems;
      if (res.data is List) {
        newItems = res.data;
        _hasMoreOrganisers = false;
      } else {
        newItems = res.data['results'] ?? [];
        _hasMoreOrganisers = res.data['next'] != null;
      }

      setState(() {
        if (refresh) {
          _organisers.clear();
        }
        _organisers.addAll(newItems);
        _organiserPage++;
        _isLoadingOrganisers = false;
        _isLoadingMoreOrganisers = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingOrganisers = false;
        _isLoadingMoreOrganisers = false;
      });
      _showErrorSnackBar('Failed to load organisers: ${e.toString()}');
    }
  }

  Future<void> _fetchNonOrganisers({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _nonOrganiserPage = 1;
        _nonOrganisers.clear();
        _hasMoreNonOrganisers = true;
        _isLoadingNonOrganisers = true;
      });
    } else {
      if (_isLoadingMoreNonOrganisers || !_hasMoreNonOrganisers || _isLoadingNonOrganisers) return;
      setState(() => _isLoadingMoreNonOrganisers = true);
    }

    try {
      final dio = ref.read(dioProvider);
      final queryParams = {
        'page': _nonOrganiserPage,
        'search': _nonOrganiserSearch,
      };
      final res = await dio.get('/organisers/non-organisers/', queryParameters: queryParams);

      final List<dynamic> newItems;
      if (res.data is List) {
        newItems = res.data;
        _hasMoreNonOrganisers = false;
      } else {
        newItems = res.data['results'] ?? [];
        _hasMoreNonOrganisers = res.data['next'] != null;
      }

      setState(() {
        if (refresh) {
          _nonOrganisers.clear();
        }
        _nonOrganisers.addAll(newItems);
        _nonOrganiserPage++;
        _isLoadingNonOrganisers = false;
        _isLoadingMoreNonOrganisers = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingNonOrganisers = false;
        _isLoadingMoreNonOrganisers = false;
      });
      _showErrorSnackBar('Failed to load non-organisers: ${e.toString()}');
    }
  }

  // ---------------------------------------------------------------------------
  // ROLE PROMOTION & DEMOTION
  // ---------------------------------------------------------------------------

  Future<void> _promoteUser(int userId, String name) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/organisers/promote/', data: {'user_id': userId});
      
      _showSuccessSnackBar('$name has been promoted to Organiser successfully!');
      
      _fetchOrganisers(refresh: true);
      _fetchNonOrganisers(refresh: true);
    } catch (e) {
      String errMsg = 'Failed to promote user';
      if (e is DioError) {
        errMsg = e.response?.data?['detail'] ?? e.message ?? errMsg;
      }
      _showErrorSnackBar(errMsg);
    }
  }

  Future<void> _demoteOrganiser(int organiserId, String name) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/organisers/demote/', data: {'organiser_id': organiserId});
      
      _showSuccessSnackBar('Organiser role removed from $name.');
      
      _fetchOrganisers(refresh: true);
      _fetchNonOrganisers(refresh: true);
    } catch (e) {
      String errMsg = 'Failed to remove role';
      if (e is DioError) {
        errMsg = e.response?.data?['detail'] ?? e.message ?? errMsg;
      }
      _showErrorSnackBar(errMsg);
    }
  }

  // ---------------------------------------------------------------------------
  // DIALOGS & UTILS
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

  void _showPromoteConfirmation(int userId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16151A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Promote to Organiser',
          style: GoogleFonts.breeSerif(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Promote $name to organiser?',
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
              _promoteUser(userId, name);
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

  void _showDemoteConfirmation(int organiserId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16151A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Remove Organiser Role',
          style: GoogleFonts.breeSerif(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Remove organiser role from $name?',
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
              _demoteOrganiser(organiserId, name);
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

  void _showAssignedEventsDialog(String name, List<dynamic> events) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16151A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Assigned Events — $name',
          style: GoogleFonts.breeSerif(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: events.isEmpty
              ? Text('No assigned events.', style: GoogleFonts.breeSerif(color: Colors.white38))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: events.length,
                  itemBuilder: (c, idx) {
                    final ev = events[idx];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.event_available, color: Color(0xFFFECF65), size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              ev['name'] ?? 'Unnamed Event',
                              style: GoogleFonts.breeSerif(color: Colors.white, fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: GoogleFonts.breeSerif(color: const Color(0xFFFECF65)),
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
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFFFECF65), Color(0xFFC26E28)],
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
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      itemCount: 5,
      padding: const EdgeInsets.all(20),
      itemBuilder: (ctx, index) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 140,
        decoration: BoxDecoration(
          color: const Color(0xFF16151A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(backgroundColor: Colors.white.withOpacity(0.05), radius: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 16, width: 120, color: Colors.white.withOpacity(0.05)),
                    const SizedBox(height: 8),
                    Container(height: 12, width: 80, color: Colors.white.withOpacity(0.05)),
                    const SizedBox(height: 8),
                    Container(height: 12, width: 160, color: Colors.white.withOpacity(0.05)),
                  ],
                ),
              ),
            ],
          ),
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
                'Only admins are authorized to access this page.',
                style: GoogleFonts.breeSerif(color: Colors.white54, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

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
          'ADD ORGANISERS',
          style: GoogleFonts.breeSerif(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            height: 46,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF16151A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: const Color(0xFFFECF65),
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: const Color(0xFF0F0E11),
              unselectedLabelColor: Colors.white54,
              labelStyle: GoogleFonts.breeSerif(fontWeight: FontWeight.bold, fontSize: 14),
              unselectedLabelStyle: GoogleFonts.breeSerif(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: const [
                Tab(text: 'ORGANISERS'),
                Tab(text: 'NON ORGANISERS'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrganisersTab(),
          _buildNonOrganisersTab(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB BUILDERS
  // ---------------------------------------------------------------------------

  Widget _buildOrganisersTab() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: TextField(
            controller: _organiserSearchController,
            style: GoogleFonts.breeSerif(color: Colors.white),
            onChanged: (v) {
              setState(() => _organiserSearch = v);
              _fetchOrganisers(refresh: true);
            },
            decoration: InputDecoration(
              hintText: 'Search by name, username, or email...',
              hintStyle: GoogleFonts.breeSerif(color: Colors.white38, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Color(0xFFFECF65)),
              suffixIcon: _organiserSearch.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white54),
                      onPressed: () {
                        _organiserSearchController.clear();
                        setState(() => _organiserSearch = '');
                        _fetchOrganisers(refresh: true);
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFF16151A),
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20), // Rounded 20
                borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20), // Rounded 20
                borderSide: const BorderSide(color: Color(0xFFFECF65)),
              ),
            ),
          ),
        ),

        // List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _fetchOrganisers(refresh: true),
            color: const Color(0xFFFECF65),
            backgroundColor: const Color(0xFF16151A),
            child: _isLoadingOrganisers
                ? _buildSkeletonList()
                : _organisers.isEmpty
                    ? Center(
                        child: Text(
                          'No organisers found.',
                          style: GoogleFonts.breeSerif(color: Colors.white38),
                        ),
                      )
                    : ListView.builder(
                        controller: _organiserScrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 40),
                        itemCount: _organisers.length + (_isLoadingMoreOrganisers ? 1 : 0),
                        itemBuilder: (ctx, index) {
                          if (index == _organisers.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator(color: Color(0xFFFECF65))),
                            );
                          }

                          final org = _organisers[index];
                          final int eventCount = org['assigned_events_count'] ?? 0;
                          final List<dynamic> eventsList = org['assigned_events'] ?? [];
                          final String name = org['name'] ?? org['username'] ?? 'Organiser';
                          final String username = org['username'] ?? '';
                          final String email = org['email'] ?? '';

                          return CardPressWrapper(
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16151A),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.05)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildAvatar(name),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.breeSerif(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            if (username.isNotEmpty)
                                              Text(
                                                '@$username',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.breeSerif(
                                                  color: Colors.white54,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            if (email.isNotEmpty)
                                              Text(
                                                email,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.breeSerif(
                                                  color: Colors.white38,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            const SizedBox(height: 6),
                                            // Dynamic badge that doesn't span full card width
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: Colors.green.withOpacity(0.3)),
                                              ),
                                              child: Text(
                                                '$eventCount ${eventCount == 1 ? 'Event' : 'Events'}',
                                                style: GoogleFonts.breeSerif(
                                                  color: Colors.greenAccent,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Button row with 50-50 width and strict centering/ellipsis styles
                                  Row(
                                    children: [
                                      Expanded(
                                        child: SizedBox(
                                          height: 40,
                                          child: OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(color: Colors.white.withOpacity(0.15)),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              padding: EdgeInsets.zero,
                                            ),
                                            onPressed: () => _showAssignedEventsDialog(name, eventsList),
                                            child: Center(
                                              child: Text(
                                                'View Events',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.breeSerif(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: SizedBox(
                                          height: 40,
                                          child: eventCount > 0
                                              ? OutlinedButton(
                                                  style: OutlinedButton.styleFrom(
                                                    side: BorderSide(color: Colors.white.withOpacity(0.08)),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                    padding: EdgeInsets.zero,
                                                  ),
                                                  onPressed: () {
                                                    _showErrorSnackBar(
                                                      'Cannot remove organiser role. This user is still assigned to $eventCount event(s). Please unassign them from all events first.',
                                                    );
                                                  },
                                                  child: Center(
                                                    child: Text(
                                                      'Remove Role',
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: GoogleFonts.breeSerif(
                                                        color: Colors.white.withOpacity(0.3),
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              : OutlinedButton(
                                                  style: OutlinedButton.styleFrom(
                                                    side: const BorderSide(color: Colors.redAccent),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                    padding: EdgeInsets.zero,
                                                  ),
                                                  onPressed: () => _showDemoteConfirmation(org['id'], name),
                                                  child: Center(
                                                    child: Text(
                                                      'Remove Role',
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: GoogleFonts.breeSerif(
                                                        color: Colors.redAccent,
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ],
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

  Widget _buildNonOrganisersTab() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: TextField(
            controller: _nonOrganiserSearchController,
            style: GoogleFonts.breeSerif(color: Colors.white),
            onChanged: (v) {
              setState(() => _nonOrganiserSearch = v);
              _fetchNonOrganisers(refresh: true);
            },
            decoration: InputDecoration(
              hintText: 'Search by name, username, or email...',
              hintStyle: GoogleFonts.breeSerif(color: Colors.white38, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Color(0xFFFECF65)),
              suffixIcon: _nonOrganiserSearch.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white54),
                      onPressed: () {
                        _nonOrganiserSearchController.clear();
                        setState(() => _nonOrganiserSearch = '');
                        _fetchNonOrganisers(refresh: true);
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFF16151A),
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20), // Rounded 20
                borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20), // Rounded 20
                borderSide: const BorderSide(color: Color(0xFFFECF65)),
              ),
            ),
          ),
        ),

        // List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _fetchNonOrganisers(refresh: true),
            color: const Color(0xFFFECF65),
            backgroundColor: const Color(0xFF16151A),
            child: _isLoadingNonOrganisers
                ? _buildSkeletonList()
                : _nonOrganisers.isEmpty
                    ? Center(
                        child: Text(
                          'No users available to promote.',
                          style: GoogleFonts.breeSerif(color: Colors.white38),
                        ),
                      )
                    : ListView.builder(
                        controller: _nonOrganiserScrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 40),
                        itemCount: _nonOrganisers.length + (_isLoadingMoreNonOrganisers ? 1 : 0),
                        itemBuilder: (ctx, index) {
                          if (index == _nonOrganisers.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator(color: Color(0xFFFECF65))),
                            );
                          }

                          final user = _nonOrganisers[index];
                          final String name = user['name'] ?? user['username'] ?? 'User';
                          final String username = user['username'] ?? '';
                          final String email = user['email'] ?? '';
                          final String role = user['role'] ?? 'participant';

                          return CardPressWrapper(
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16151A),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.05)),
                              ),
                              child: Row(
                                children: [
                                  _buildAvatar(name),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.breeSerif(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        if (username.isNotEmpty)
                                          Text(
                                            '@$username',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.breeSerif(
                                              color: Colors.white54,
                                              fontSize: 13,
                                            ),
                                          ),
                                        if (email.isNotEmpty)
                                          Text(
                                            email,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.breeSerif(
                                              color: Colors.white38,
                                              fontSize: 13,
                                            ),
                                          ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Role: ${role.toUpperCase()}',
                                          style: GoogleFonts.breeSerif(
                                            color: const Color(0xFFFECF65).withOpacity(0.8),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    height: 38,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFC26E28).withOpacity(0.1),
                                        foregroundColor: const Color(0xFFFECF65),
                                        side: BorderSide(color: const Color(0xFFC26E28).withOpacity(0.4)),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                      ),
                                      onPressed: () => _showPromoteConfirmation(user['id'], name),
                                      child: Text(
                                        'Assign Role',
                                        style: GoogleFonts.breeSerif(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
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
