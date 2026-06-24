import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
<<<<<<< HEAD
=======
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
>>>>>>> edccbf4 (Added Analytics, Organiser Assignment, Attendance Management)
import '../../../../features/events/presentation/widgets/manage_event_card.dart';
import '../../../../features/events/presentation/providers/manage_events_provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/events/presentation/widgets/manage_event_modals.dart';
import '../../../../features/events/presentation/providers/event_analytics_provider.dart';

class ManageEventsPage extends ConsumerWidget {
  const ManageEventsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final isAdmin = user != null && user.role == 'admin';
    final eventsAsync = ref.watch(manageEventsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(manageEventsProvider),
        color: const Color(0xFF7C3AED),
        backgroundColor: const Color(0xFF1B1B26),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
<<<<<<< HEAD
              pinned: true,
              expandedHeight: 120,
              flexibleSpace: const FlexibleSpaceBar(
                titlePadding: EdgeInsets.symmetric(
=======
              pinned: false,
              expandedHeight: 80,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.symmetric(
>>>>>>> edccbf4 (Added Analytics, Organiser Assignment, Attendance Management)
                  horizontal: 24,
                  vertical: 16,
                ),
                title: Text(
<<<<<<< HEAD
                  'Manage Events',
                  style: TextStyle(
=======
                  'MANAGE EVENTS',
                  style: GoogleFonts.breeSerif(
>>>>>>> edccbf4 (Added Analytics, Organiser Assignment, Attendance Management)
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            if (isAdmin)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final useVertical = constraints.maxWidth < 450;
                      const double height = 48.0;

                      final Widget addEventBtn = ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
<<<<<<< HEAD
                          backgroundColor: const Color(0xFF7C3AED),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
=======
                          backgroundColor: const Color(0xFFFECF65), // Golden accent
                          foregroundColor: const Color(0xFF0F0E11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
>>>>>>> edccbf4 (Added Analytics, Organiser Assignment, Attendance Management)
                          ),
                        ),
<<<<<<< HEAD
                        onPressed: () =>
                            ManageEventModals.showEventModal(context, ref),
                        icon: const Icon(
                          Icons.add,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Add Event',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
=======
                        onPressed: () => ManageEventModals.showEventModal(context, ref),
                        icon: const Icon(Icons.add, size: 20),
                        label: Text(
                          'Add Event',
                          style: GoogleFonts.breeSerif(fontWeight: FontWeight.bold),
>>>>>>> edccbf4 (Added Analytics, Organiser Assignment, Attendance Management)
                        ),
                      );

<<<<<<< HEAD
            // Subtitle exactly mapping web requirement
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text(
                  'Here you can manage the structural architecture mapping directly to the endpoints.',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
=======
                      final Widget addOrganisersBtn = ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC26E28), // Dark orange/bronze theme
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => GoRouter.of(context).push('/add-organisers'),
                        icon: const Icon(Icons.person_add_alt_1, size: 20),
                        label: Text(
                          'Add Organisers',
                          style: GoogleFonts.breeSerif(fontWeight: FontWeight.bold),
                        ),
                      );

                      if (useVertical) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(height: height, child: addEventBtn),
                            const SizedBox(height: 12),
                            SizedBox(height: height, child: addOrganisersBtn),
                          ],
                        );
                      } else {
                        return Row(
                          children: [
                            Expanded(child: SizedBox(height: height, child: addEventBtn)),
                            const SizedBox(width: 16),
                            Expanded(child: SizedBox(height: height, child: addOrganisersBtn)),
                          ],
                        );
                      }
                    },
                  ),
>>>>>>> edccbf4 (Added Analytics, Organiser Assignment, Attendance Management)
                ),
              ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),

            eventsAsync.when(
              data: (events) {
                if (events.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: Text(
                          "No events assigned to you.",
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                  ).copyWith(bottom: 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final event = events[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: ManageEventCard(event: event, isAdmin: isAdmin),
                      );
                    }, childCount: events.length),
                  ),
                );
              },
              loading: () => SliverToBoxAdapter(
                child: SizedBox(
                   height: 300,
                  child: Center(
                    child: CircularProgressIndicator(color: const Color(0xFF7C3AED)),
                  ),
                ),
              ),
              error: (err, _) => SliverToBoxAdapter(
                child: Container(
                  height: 300,
                  alignment: Alignment.center,
                  child: Text(
                    "Failed to load nodes: $err",
                    style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EventAttendancePage extends ConsumerStatefulWidget {
  final String eventId;

  const EventAttendancePage({super.key, required this.eventId});

  @override
  ConsumerState<EventAttendancePage> createState() => _EventAttendancePageState();
}

class _EventAttendancePageState extends ConsumerState<EventAttendancePage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  final Color goldColor = const Color(0xFFFECF65);
  final Color darkBg = const Color(0xFF0F0E11);
  final Color cardBg = const Color(0xFF16151A);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final filters = ref.read(eventAttendanceFiltersProvider(widget.eventId));
      _searchController.text = filters.search;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(eventAttendanceNotifierProvider(widget.eventId).notifier).fetchNextPage();
    }
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final filters = ref.watch(eventAttendanceFiltersProvider(widget.eventId));
            String tempStatus = filters.status;
            String tempType = filters.type;
            String tempOrdering = filters.ordering;

            return StatefulBuilder(
              builder: (context, setModalState) {
                return SafeArea(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: 24,
                        right: 24,
                        top: 24,
                        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'FILTER ATTENDANCE',
                            style: GoogleFonts.breeSerif(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text('Attendance Status', style: GoogleFonts.breeSerif(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              _buildFilterChip(setModalState, 'All', 'all', tempStatus, (val) => tempStatus = val),
                              _buildFilterChip(setModalState, 'Fully Attended', 'fully', tempStatus, (val) => tempStatus = val),
                              _buildFilterChip(setModalState, 'Partially', 'partially', tempStatus, (val) => tempStatus = val),
                              _buildFilterChip(setModalState, 'Not Attended', 'not', tempStatus, (val) => tempStatus = val),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text('Booking Type', style: GoogleFonts.breeSerif(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              _buildFilterChip(setModalState, 'All', 'all', tempType, (val) => tempType = val),
                              _buildFilterChip(setModalState, 'Single Booking', 'single', tempType, (val) => tempType = val),
                              _buildFilterChip(setModalState, 'Team Booking', 'team', tempType, (val) => tempType = val),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text('Sorting', style: GoogleFonts.breeSerif(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              _buildFilterChip(setModalState, 'Newest First', '-newest', tempOrdering, (val) => tempOrdering = val),
                              _buildFilterChip(setModalState, 'Oldest First', 'oldest', tempOrdering, (val) => tempOrdering = val),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.white30),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  onPressed: () {
                                    ref.read(eventAttendanceFiltersProvider(widget.eventId).notifier).update(
                                      (s) => EventAttendanceFilters(
                                        search: filters.search,
                                      ),
                                    );
                                    ref.read(eventAttendanceNotifierProvider(widget.eventId).notifier).fetchFirstPage();
                                    Navigator.pop(context);
                                  },
                                  child: Text('RESET', style: GoogleFonts.breeSerif(color: Colors.white70)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: goldColor,
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  onPressed: () {
                                    ref.read(eventAttendanceFiltersProvider(widget.eventId).notifier).update(
                                      (s) => s.copyWith(
                                        status: tempStatus,
                                        type: tempType,
                                        ordering: tempOrdering,
                                      ),
                                    );
                                    ref.read(eventAttendanceNotifierProvider(widget.eventId).notifier).fetchFirstPage();
                                    Navigator.pop(context);
                                  },
                                  child: Text('APPLY', style: GoogleFonts.breeSerif(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip(
    void Function(void Function()) setModalState,
    String label,
    String value,
    String currentSelected,
    void Function(String) onSelect,
  ) {
    final isSelected = currentSelected == value;
    return ChoiceChip(
      label: Text(label, style: GoogleFonts.breeSerif(color: isSelected ? Colors.black : Colors.white70, fontSize: 12)),
      selected: isSelected,
      selectedColor: goldColor,
      backgroundColor: Colors.white.withOpacity(0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isSelected ? goldColor : Colors.white10),
      ),
      showCheckmark: false,
      onSelected: (selected) {
        if (selected) {
          setModalState(() {
            onSelect(value);
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final attendanceState = ref.watch(eventAttendanceNotifierProvider(widget.eventId));
    final filters = ref.watch(eventAttendanceFiltersProvider(widget.eventId));

    // Listen to changes in filters to automatically refresh
    ref.listen(eventAttendanceFiltersProvider(widget.eventId), (prev, next) {
      ref.read(eventAttendanceNotifierProvider(widget.eventId).notifier).fetchFirstPage();
    });

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: goldColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ATTENDANCE RECORDS',
          style: GoogleFonts.breeSerif(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // SEARCH & FILTER BAR
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.breeSerif(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search attendee name, email, usn, phone...',
                        hintStyle: GoogleFonts.breeSerif(color: Colors.white30, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: Colors.white30),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.white30),
                                onPressed: () {
                                  _searchController.clear();
                                  ref.read(eventAttendanceFiltersProvider(widget.eventId).notifier).update(
                                    (s) => s.copyWith(search: ''),
                                  );
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onSubmitted: (val) {
                        ref.read(eventAttendanceFiltersProvider(widget.eventId).notifier).update(
                          (s) => s.copyWith(search: val),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () => _showFilterBottomSheet(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: (filters.status != 'all' || filters.type != 'all')
                            ? goldColor.withOpacity(0.5)
                            : Colors.white.withOpacity(0.05),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.filter_list_rounded,
                      color: (filters.status != 'all' || filters.type != 'all') ? goldColor : Colors.white70,
                    ),
                  ),
                )
              ],
            ),
          ),

          // FILTER SUMMARY CHIPS (if filters active)
          if (filters.status != 'all' || filters.type != 'all' || filters.search.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0).copyWith(bottom: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (filters.search.isNotEmpty)
                    _buildActiveFilterChip('Search: "${filters.search}"', () {
                      _searchController.clear();
                      ref.read(eventAttendanceFiltersProvider(widget.eventId).notifier).update((s) => s.copyWith(search: ''));
                    }),
                  if (filters.status != 'all')
                    _buildActiveFilterChip('Status: ${filters.status.toUpperCase()}', () {
                      ref.read(eventAttendanceFiltersProvider(widget.eventId).notifier).update((s) => s.copyWith(status: 'all'));
                    }),
                  if (filters.type != 'all')
                    _buildActiveFilterChip('Type: ${filters.type.toUpperCase()}', () {
                      ref.read(eventAttendanceFiltersProvider(widget.eventId).notifier).update((s) => s.copyWith(type: 'all'));
                    }),
                ],
              ),
            ),

          // RECORDS LIST
          Expanded(
            child: RefreshIndicator(
              color: goldColor,
              backgroundColor: cardBg,
              onRefresh: () async {
                ref.read(eventAttendanceNotifierProvider(widget.eventId).notifier).fetchFirstPage();
              },
              child: attendanceState.when(
                data: (records) {
                  if (records.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                        Center(
                          child: Column(
                            children: [
                              const Icon(Icons.assignment_ind_outlined, size: 48, color: Colors.white30),
                              const SizedBox(height: 16),
                              Text(
                                "No attendance records yet",
                                style: GoogleFonts.breeSerif(color: Colors.white54, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  final notifier = ref.read(eventAttendanceNotifierProvider(widget.eventId).notifier);

                  return ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 40),
                    itemCount: records.length + (notifier.hasNext ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == records.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: goldColor, strokeWidth: 2),
                            ),
                          ),
                        );
                      }

                      final record = records[index];
                      return _buildBookingGroupCard(context, record);
                    },
                  );
                },
                loading: () => ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 5,
                  itemBuilder: (context, index) => _buildSkeletonCard(),
                ),
                error: (err, stack) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to Load Attendance',
                            style: GoogleFonts.breeSerif(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            err.toString().replaceAll('Exception:', '').trim(),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.breeSerif(color: Colors.white38, fontSize: 13),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: goldColor,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: Text('Retry', style: GoogleFonts.breeSerif(fontWeight: FontWeight.bold)),
                            onPressed: () {
                              ref.read(eventAttendanceNotifierProvider(widget.eventId).notifier).fetchFirstPage();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActiveFilterChip(String label, VoidCallback onDelete) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: goldColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: goldColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: GoogleFonts.breeSerif(color: goldColor, fontSize: 11)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDelete,
            child: Icon(Icons.cancel_rounded, size: 14, color: goldColor),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingGroupCard(BuildContext context, Map<String, dynamic> record) {
    final refStr = record['booking_reference'] ?? '#EVT-XXX';
    final slot = record['slot'] ?? 'Unknown Slot';
    final checked = record['checked_in_count'] ?? 0;
    final total = record['total_participants'] ?? 0;
    final pending = record['pending_count'] ?? 0;
    final overall = record['overall_status'] ?? 'Not Attended';
    final bookedEventId = record['booked_event_id'];
    final participants = List<Map<String, dynamic>>.from(record['participants'] ?? []);

    Color statusColor = Colors.white24;
    if (overall == 'Fully Attended') {
      statusColor = const Color(0xFF10B981);
    } else if (overall == 'Partially Attended') {
      statusColor = const Color(0xFFF97316);
    } else if (overall == 'Not Attended') {
      statusColor = const Color(0xFFEF4444);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                refStr,
                style: GoogleFonts.breeSerif(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  overall.toUpperCase(),
                  style: GoogleFonts.breeSerif(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time_outlined, size: 14, color: goldColor),
              const SizedBox(width: 8),
              Text(
                slot,
                style: GoogleFonts.breeSerif(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.people_outline, size: 14, color: goldColor),
              const SizedBox(width: 8),
              Text(
                'Team Size: $total  |  $checked/$total checked in ($pending pending)',
                style: GoogleFonts.breeSerif(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          
          if (participants.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 12),
            Text(
              'Participants',
              style: GoogleFonts.breeSerif(
                color: goldColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            ...participants.map((p) {
              final pName = p['name'] ?? 'Attendee';
              final isChecked = p['checked_in'] == true;
              final Color chipColor = isChecked ? const Color(0xFF10B981) : const Color(0xFFEF4444);
              final String chipText = isChecked ? 'CHECKED IN' : 'NOT ATTENDED';
              final avatarLetter = pName.isNotEmpty ? pName[0].toUpperCase() : 'A';

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: chipColor.withOpacity(0.1),
                      child: Text(
                        avatarLetter,
                        style: GoogleFonts.breeSerif(
                          color: chipColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pName,
                        style: GoogleFonts.breeSerif(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: chipColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: chipColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: chipColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            chipText,
                            style: GoogleFonts.breeSerif(
                              color: chipColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],

          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.04),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () {
              if (bookedEventId != null) {
                GoRouter.of(context).push('/booking-details/$bookedEventId');
              }
            },
            child: Text(
              'View Details',
              style: GoogleFonts.breeSerif(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 150,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(width: 80, height: 16, color: Colors.white10),
                Container(width: 60, height: 16, color: Colors.white10),
              ],
            ),
            const SizedBox(height: 20),
            Container(width: 200, height: 12, color: Colors.white10),
            const SizedBox(height: 8),
            Container(width: 140, height: 12, color: Colors.white10),
          ],
        ),
      ),
    );
  }
}

class BookingDetailPage extends ConsumerStatefulWidget {
  final int bookedEventId;

  const BookingDetailPage({super.key, required this.bookedEventId});

  @override
  ConsumerState<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends ConsumerState<BookingDetailPage> {
  final Color goldColor = const Color(0xFFFECF65);
  final Color darkBg = const Color(0xFF0F0E11);
  final Color cardBg = const Color(0xFF16151A);
  bool _isActionRunning = false;

  Future<void> _handleCheckIn(Map<String, dynamic> participant, String bookingRef, String slotStr) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Check in ${participant['name']}?',
            style: GoogleFonts.breeSerif(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Participant: ${participant['name']}', style: GoogleFonts.breeSerif(color: Colors.white70)),
              const SizedBox(height: 6),
              Text('Booking: $bookingRef', style: GoogleFonts.breeSerif(color: Colors.white70)),
              const SizedBox(height: 6),
              Text('Slot: $slotStr', style: GoogleFonts.breeSerif(color: Colors.white70)),
              const SizedBox(height: 12),
              Text('Confirm?', style: GoogleFonts.breeSerif(color: Colors.white70, fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: GoogleFonts.breeSerif(color: Colors.white38)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Confirm', style: GoogleFonts.breeSerif(color: goldColor, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() => _isActionRunning = true);
      try {
        await ref.read(checkInParticipantProvider)(participant['id']);
        ref.invalidate(bookedEventDetailProvider(widget.bookedEventId.toString()));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${participant['name']} checked in successfully.', style: GoogleFonts.breeSerif()),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString().replaceAll('Exception:', '').trim()}', style: GoogleFonts.breeSerif()),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isActionRunning = false);
      }
    }
  }

  Future<void> _handleReverse(Map<String, dynamic> participant) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Reverse attendance for ${participant['name']}?',
            style: GoogleFonts.breeSerif(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'This action will mark the participant as not checked-in.',
            style: GoogleFonts.breeSerif(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: GoogleFonts.breeSerif(color: Colors.white38)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Reverse', style: GoogleFonts.breeSerif(color: const Color(0xFFEF4444), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() => _isActionRunning = true);
      try {
        await ref.read(reverseCheckInParticipantProvider)(participant['id']);
        ref.invalidate(bookedEventDetailProvider(widget.bookedEventId.toString()));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Attendance reversed successfully.', style: GoogleFonts.breeSerif()),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString().replaceAll('Exception:', '').trim()}', style: GoogleFonts.breeSerif()),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isActionRunning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(bookedEventDetailProvider(widget.bookedEventId.toString()));

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: goldColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'BOOKING DETAILS',
          style: GoogleFonts.breeSerif(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: detailsAsync.when(
        data: (data) {
          final bookingId = data['booking'] ?? 0;
          final bookingRef = '#EVT-$bookingId';
          final eventName = data['event_name'] ?? 'Event';
          final slotInfo = data['slot_info'] ?? {};
          final slotDate = slotInfo['date'] ?? '';
          final slotStart = slotInfo['start_time'] ?? '';
          final slotEnd = slotInfo['end_time'] ?? '';
          final slotStr = '$slotDate | $slotStart - $slotEnd';
          
          final participants = List<Map<String, dynamic>>.from(data['participants'] ?? []);
          final teamSize = data['participants_count'] ?? participants.length;
          final isTeam = teamSize > 1;

          int checkedInCount = 0;
          for (var p in participants) {
            if (p['checked_in'] == true) checkedInCount++;
          }

          String statusLabel = 'Not Attended';
          Color statusColor = const Color(0xFFEF4444);
          if (checkedInCount == teamSize && teamSize > 0) {
            statusLabel = 'Fully Attended';
            statusColor = const Color(0xFF10B981);
          } else if (checkedInCount > 0) {
            statusLabel = 'Partially Attended';
            statusColor = const Color(0xFFF97316);
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // BOOKING HEADER CARD
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: goldColor.withOpacity(0.15), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            bookingRef,
                            style: GoogleFonts.breeSerif(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: statusColor.withOpacity(0.4)),
                            ),
                            child: Text(
                              statusLabel.toUpperCase(),
                              style: GoogleFonts.breeSerif(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        eventName,
                        style: GoogleFonts.breeSerif(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 12),
                      _buildDetailRow('Slot Selection:', slotStr),
                      const SizedBox(height: 8),
                      _buildDetailRow('Booking Type:', isTeam ? 'Team booking' : 'Single booking'),
                      const SizedBox(height: 8),
                      _buildDetailRow('Total Team Size:', teamSize.toString()),
                      const SizedBox(height: 8),
                      _buildDetailRow('Checked-in Count:', '$checkedInCount / $teamSize'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                Text(
                  'PARTICIPANTS LIST',
                  style: GoogleFonts.breeSerif(color: goldColor, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                
                const SizedBox(height: 12),
                
                // PARTICIPANTS LIST
                if (participants.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    child: Text('No participants recorded.', style: GoogleFonts.breeSerif(color: Colors.white38)),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: participants.length,
                    itemBuilder: (context, idx) {
                      final p = participants[idx];
                      return _buildParticipantCard(p, bookingRef, slotStr);
                    },
                  ),
              ],
            ),
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: goldColor)),
        error: (err, _) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text('Error loading details', style: GoogleFonts.breeSerif(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 8),
              Text(err.toString(), style: GoogleFonts.breeSerif(color: Colors.white38), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: goldColor, foregroundColor: Colors.black),
                onPressed: () => ref.refresh(bookedEventDetailProvider(widget.bookedEventId.toString())),
                child: Text('Retry', style: GoogleFonts.breeSerif(fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.breeSerif(color: Colors.white38, fontSize: 13)),
        Text(val, style: GoogleFonts.breeSerif(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget? _buildConditionalDetailRow(String label, String? val) {
    if (val == null || val.trim().isEmpty || val.trim().toLowerCase() == 'n/a') {
      return null;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: _buildDetailRow(label, val),
    );
  }

  Widget _buildParticipantCard(Map<String, dynamic> p, String bookingRef, String slotStr) {
    final name = p['name'] ?? 'Attendee';
    final email = p['email'];
    final phone = p['phone_number'];
    final checkedIn = p['checked_in'] == true;
    final qr = p['qr_status'];
    final checkinTime = p['checked_in_at'];
    final checkedInBy = p['checked_in_by'];

    final emailStr = (email == null || email.toString().trim().isEmpty) ? 'N/A' : email.toString();
    final phoneStr = (phone == null || phone.toString().trim().isEmpty) ? 'N/A' : phone.toString();
    final qrRow = _buildConditionalDetailRow('QR Code Status:', qr);
    
    // Checked-in info
    Widget? checkinTimeRow;
    Widget? checkinByRow;
    if (checkedIn) {
      String timeStr = 'N/A';
      if (checkinTime != null) {
        timeStr = checkinTime.toString();
        if (timeStr.contains('T')) {
          timeStr = timeStr.split('T').first;
        }
      }
      checkinTimeRow = _buildConditionalDetailRow('Checked-in At:', timeStr);
      checkinByRow = _buildConditionalDetailRow('Checked-in By:', checkedInBy);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: checkedIn ? const Color(0xFF10B981).withOpacity(0.3) : Colors.white.withOpacity(0.05),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: GoogleFonts.breeSerif(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (checkedIn ? const Color(0xFF10B981) : Colors.white30).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: (checkedIn ? const Color(0xFF10B981) : Colors.white30).withOpacity(0.3)),
                ),
                child: Text(
                  checkedIn ? 'CHECKED-IN' : 'PENDING',
                  style: GoogleFonts.breeSerif(
                    color: checkedIn ? const Color(0xFF10B981) : Colors.white54,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Email:', emailStr),
          const SizedBox(height: 6),
          _buildDetailRow('Phone:', phoneStr),
          const SizedBox(height: 6),
          if (qrRow != null) qrRow,
          if (checkedIn && checkinTimeRow != null) checkinTimeRow,
          if (checkedIn && checkinByRow != null) checkinByRow,
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.white.withOpacity(0.02),
                    disabledForegroundColor: Colors.white24,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: (checkedIn || _isActionRunning) ? null : () => _handleCheckIn(p, bookingRef, slotStr),
                  child: Text('Check In', style: GoogleFonts.breeSerif(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.white.withOpacity(0.02),
                    disabledForegroundColor: Colors.white24,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: (!checkedIn || _isActionRunning) ? null : () => _handleReverse(p),
                  child: Text('Reverse Check In', style: GoogleFonts.breeSerif(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
