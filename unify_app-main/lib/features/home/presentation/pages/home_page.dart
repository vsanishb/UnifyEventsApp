import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../events/presentation/providers/events_provider.dart';
import '../../../events/domain/models/event_model.dart';
import '../../../../shared/widgets/app_cached_image.dart';
import '../../../../shared/widgets/event_card.dart';
import '../../../../core/services/r2_image_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../bookings/presentation/providers/bookings_provider.dart';
import '../../../bookings/domain/models/slot_info.dart';
import 'package:unify_events/features/events/presentation/providers/manage_events_provider.dart';
import '../../../events/presentation/providers/event_details_provider.dart';
import '../../../../core/utils/datetime_utils.dart';

import '../widgets/home_painters.dart';
import '../widgets/image_precache_handler.dart';
import '../widgets/search_result_card.dart';
import '../widgets/advanced_filters_sheet.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _isSearching = false;
  String _priceFilter = "All"; // "All", "Free", "Paid"
  final List<String> _selectedFests = [];
  final List<int> _selectedCategories = [];
  final List<String> _selectedConstraints = [];
  DateTime? _filterDate;
  TimeOfDay? _filterStartTime;
  TimeOfDay? _filterEndTime;
  int? _filterFixedTeamSize;
  int? _filterMinTeamSize;
  int? _filterMaxTeamSize;


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatEventDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return "Date TBA";
    try {
      final parsed = DateTime.parse(rawDate);
      final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
      return "${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}";
    } catch (_) {
      if (rawDate.contains(' ')) {
        return rawDate.split(' ').first;
      }
      return rawDate;
    }
  }

  String _formatEventTime(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return "Time TBA";
    try {
      final parsed = DateTime.parse(rawDate);
      final hour = parsed.hour > 12 ? parsed.hour - 12 : (parsed.hour == 0 ? 12 : parsed.hour);
      final period = parsed.hour >= 12 ? "PM" : "AM";
      final minuteStr = parsed.minute.toString().padLeft(2, '0');
      final hourStr = hour.toString().padLeft(2, '0');
      return "$hourStr:$minuteStr $period";
    } catch (_) {
      if (rawDate.contains(' ')) {
        return rawDate.split(' ').last;
      }
      return "08:00 AM";
    }
  }

  List<EventModel> _getFilteredEvents(List<EventModel> allEvents) {
    return allEvents.where((e) {
      if (_searchQuery.isNotEmpty) {
        final tMatch = e.title.toLowerCase().contains(_searchQuery.toLowerCase());
        final dMatch = e.description.toLowerCase().contains(_searchQuery.toLowerCase());
        if (!tMatch && !dMatch) return false;
      }
      if (_priceFilter == "Free") {
        if (e.price != null && e.price! > 0) return false;
      } else if (_priceFilter == "Paid") {
        if (e.price == null || e.price! <= 0) return false;
      }
      if (_selectedFests.isNotEmpty) {
        bool matches = false;
        for (var f in _selectedFests) {
          if (f == "phaseshift" && e.parentEventId == 1) matches = true;
          if (f == "utsav" && e.parentEventId == 2) matches = true;
          if (f == "regular" && e.parentEventId != 1 && e.parentEventId != 2) matches = true;
        }
        if (!matches) return false;
      }
      if (_selectedCategories.isNotEmpty) {
        if (e.categoryId == null || !_selectedCategories.contains(e.categoryId)) return false;
      }
      return true;
    }).toList();
  }



  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsProvider);
    final bookingsAsync = ref.watch(myBookingsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final parentEventsAsync = ref.watch(parentEventsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0E11),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(eventsProvider);
            ref.invalidate(myBookingsProvider);
            ref.invalidate(categoriesProvider);
            ref.invalidate(parentEventsProvider);
          },
          color: const Color(0xFFFECF65),
          backgroundColor: const Color(0xFF16151A),
          child: categoriesAsync.when(
            data: (categories) {
              return eventsAsync.when(
                data: (allEvents) {
                  final filtered = _getFilteredEvents(allEvents);
                  final first10ImageKeys = allEvents
                      .take(10)
                      .map((e) => e.bannerImage)
                      .whereType<String>()
                      .where((k) => k.isNotEmpty)
                      .toList();

                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: ImagePrecacheHandler(imageKeys: first10ImageKeys),
                      ),
                      // ── Search & Header Bar ─────────────────────────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (!_isSearching) ...[
                                Row(
                                  children: [
                                    Text(
                                      "Unify",
                                      style: GoogleFonts.breeSerif(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Events",
                                      style: GoogleFonts.breeSerif(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFFECF65),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],
                              Row(
                                children: [
                                  if (_isSearching)
                                    IconButton(
                                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                                      onPressed: () {
                                        setState(() {
                                          _isSearching = false;
                                          _searchQuery = "";
                                          _searchController.clear();
                                        });
                                      },
                                    ),
                                  Expanded(
                                    child: Container(
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF16151A),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.04),
                                        ),
                                      ),
                                      child: TextField(
                                        controller: _searchController,
                                        onTap: () {
                                          setState(() => _isSearching = true);
                                        },
                                        onChanged: (val) {
                                          setState(() => _searchQuery = val);
                                        },
                                        style: GoogleFonts.breeSerif(color: Colors.white),
                                        decoration: InputDecoration(
                                          prefixIcon: const Icon(Icons.search, color: Colors.white30),
                                          hintText: "Search events, clubs, venues...",
                                          hintStyle: GoogleFonts.breeSerif(color: Colors.white24, fontSize: 14),
                                          border: InputBorder.none,
                                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_isSearching) ...[
                                    const SizedBox(width: 12),
                                    GestureDetector(
                                      onTap: () async {
                                        final result = await showModalBottomSheet<Map<String, dynamic>>(
                                          context: context,
                                          backgroundColor: Colors.transparent,
                                          isScrollControlled: true,
                                          builder: (ctx) => AdvancedFiltersSheet(
                                            selectedFests: _selectedFests,
                                            selectedCategories: _selectedCategories,
                                            selectedConstraints: _selectedConstraints,
                                            categories: categories,
                                            filterDate: _filterDate,
                                            filterStartTime: _filterStartTime,
                                            filterEndTime: _filterEndTime,
                                            fixedTeamSize: _filterFixedTeamSize,
                                            minTeamSize: _filterMinTeamSize,
                                            maxTeamSize: _filterMaxTeamSize,
                                          ),
                                        );
                                        if (result != null) {
                                          setState(() {
                                            _selectedFests.clear();
                                            _selectedFests.addAll(result['selectedFests'] as List<String>);
                                            _selectedCategories.clear();
                                            _selectedCategories.addAll(result['selectedCategories'] as List<int>);
                                            _selectedConstraints.clear();
                                            _selectedConstraints.addAll(result['selectedConstraints'] as List<String>);
                                            _filterDate = result['filterDate'] as DateTime?;
                                            _filterStartTime = result['filterStartTime'] as TimeOfDay?;
                                            _filterEndTime = result['filterEndTime'] as TimeOfDay?;
                                            _filterFixedTeamSize = result['fixedTeamSize'] as int?;
                                            _filterMinTeamSize = result['minTeamSize'] as int?;
                                            _filterMaxTeamSize = result['maxTeamSize'] as int?;
                                          });
                                        }
                                      },
                                      child: Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFECF65),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: const Icon(
                                          Icons.tune_rounded,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── Search Mode Layout (Screenshot 3) ───────────────────────────
                      if (_isSearching) ...[
                        // Filter Pills: All, Free, Paid
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildPricePill("All"),
                                  const SizedBox(width: 8),
                                  _buildPricePill("Free"),
                                  const SizedBox(width: 8),
                                  _buildPricePill("Paid"),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 16)),

                        // Vertical Search Results
                        if (filtered.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Text(
                                "No events found",
                                style: GoogleFonts.breeSerif(color: Colors.white30),
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (ctx, idx) {
                                  final event = filtered[idx];
                                  return Consumer(
                                    builder: (context, ref, child) {
                                      final constraintAsync = ref.watch(constraintProvider(event.id.toString()));
                                      final detailsAsync = ref.watch(eventDetailsDataProvider(event.id.toString()));
                                      final slotsAsync = ref.watch(slotsProvider(event.id.toString()));

                                      final details = detailsAsync.valueOrNull;
                                      final slots = slotsAsync.valueOrNull;

                                      final isDateOrTimeMatch = EventDateTimeHelper.passesDateTime(
                                        serializerDate: event.date,
                                        details: details,
                                        slots: slots,
                                        filterDate: _filterDate,
                                        filterStartTime: _filterStartTime,
                                        filterEndTime: _filterEndTime,
                                      );

                                      if (!isDateOrTimeMatch) {
                                        return const SizedBox.shrink();
                                      }

                                      return constraintAsync.when(
                                        data: (constraint) {
                                          if (_selectedConstraints.isNotEmpty) {
                                            bool matches = false;
                                            final type = constraint?.bookingType ?? 'single';
                                            final isFixed = constraint?.fixed ?? false;
                                            for (var filter in _selectedConstraints) {
                                              if (filter == 'single' && type == 'single') {
                                                matches = true;
                                              }
                                              if (filter == 'fixed' && type == 'multiple' && isFixed) {
                                                if (_filterFixedTeamSize != null) {
                                                  if (constraint != null && constraint.upperLimit == _filterFixedTeamSize) {
                                                    matches = true;
                                                  }
                                                } else {
                                                  matches = true;
                                                }
                                              }
                                              if (filter == 'flexible' && type == 'multiple' && !isFixed) {
                                                if (_filterMinTeamSize != null && _filterMaxTeamSize != null) {
                                                  if (constraint != null &&
                                                      constraint.lowerLimit <= _filterMinTeamSize! &&
                                                      constraint.upperLimit >= _filterMaxTeamSize!) {
                                                    matches = true;
                                                  }
                                                } else {
                                                  matches = true;
                                                }
                                              }
                                            }
                                            if (!matches) {
                                              return const SizedBox.shrink();
                                            }
                                          }
                                          final venue = details?['venue']?.toString() ?? 'Venue TBA';
                                          return HomeSearchResultCard(
                                            event: event,
                                            venue: venue,
                                          );
                                        },
                                        loading: () => const SizedBox(
                                          height: 100,
                                          child: Center(
                                            child: CircularProgressIndicator(color: Color(0xFFFECF65)),
                                          ),
                                        ),
                                        error: (err, stack) {
                                          if (_selectedConstraints.isNotEmpty) {
                                            bool matches = _selectedConstraints.contains('single');
                                            if (!matches) return const SizedBox.shrink();
                                          }
                                          final venue = details?['venue']?.toString() ?? 'Venue TBA';
                                          return HomeSearchResultCard(
                                            event: event,
                                            venue: venue,
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                                childCount: filtered.length,
                              ),
                            ),
                          ),

                        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
                      ]

                      // ── Discovery Dashboard Layout (Screenshot 2) ───────────────────
                      else ...[
                        // 1. Featured Events Section
                        SliverToBoxAdapter(
                          child: _buildSectionHeader("Featured Events", null),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 265,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: allEvents.length > 5 ? 5 : allEvents.length,
                              itemBuilder: (ctx, idx) {
                                final event = allEvents[idx];
                                return EventCard(
                                  event: event,
                                  isFeatured: true,
                                );
                              },
                            ),
                          ),
                        ),

                        // 2. Parent Events Section
                        SliverToBoxAdapter(
                          child: _buildSectionHeader("Parent Events", null),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 125,
                            child: parentEventsAsync.when(
                              data: (parentEvents) {
                                if (parentEvents.isEmpty) return const SizedBox();
                                return ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  itemCount: parentEvents.length,
                                  itemBuilder: (ctx, idx) {
                                    final pe = parentEvents[idx];
                                    final id = pe['id'];
                                    final name = pe['name'] ?? '';
                                    final description = pe['description'] ?? pe['subtitle'] ?? 'Festival';

                                    List<Color> colors;
                                    CustomPainter painter;
                                    if (id == 1 || name.toLowerCase().contains('phase')) {
                                      colors = [const Color(0xFF0D1C33), const Color(0xFF060B14)];
                                      painter = NetworkMeshPainter();
                                    } else if (id == 2 || name.toLowerCase().contains('utsav')) {
                                      colors = [const Color(0xFF2B0C2B), const Color(0xFF0D0614)];
                                      painter = WavesPainter();
                                    } else {
                                      colors = [const Color(0xFF1E3A8A), const Color(0xFF0F172A)];
                                      painter = GeometricParticlesPainter();
                                    }

                                    return Container(
                                      width: 170,
                                      margin: const EdgeInsets.symmetric(horizontal: 8),
                                      child: _buildParentCard(
                                        context,
                                        name,
                                        description,
                                        colors,
                                        painter,
                                        id == 1
                                            ? '/events-list?type=phaseshift'
                                            : id == 2
                                                ? '/events-list?type=utsav'
                                                : '/events-list?type=regular',
                                      ),
                                    );
                                  },
                                );
                              },
                              loading: () => const Center(
                                child: CircularProgressIndicator(color: Color(0xFFFECF65)),
                              ),
                              error: (_, __) => const SizedBox(),
                            ),
                          ),
                        ),

                        // 3. Category Horizontal Rows
                        ...categories.expand<Widget>((cat) {
                          final catId = cat['id'] as int;
                          final catName = cat['name'] as String;
                          final catEvents = allEvents.where((e) => e.categoryId == catId).toList();

                          if (catEvents.isEmpty) return [];

                          return [
                            SliverToBoxAdapter(
                              child: _buildSectionHeader("$catName Events", () {
                                setState(() {
                                  _isSearching = true;
                                  _selectedCategories.clear();
                                  _selectedCategories.add(catId);
                                });
                              }),
                            ),
                            SliverToBoxAdapter(
                              child: SizedBox(
                                height: 265,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: catEvents.length,
                                  itemBuilder: (ctx, idx) {
                                    final event = catEvents[idx];
                                    return EventCard(
                                      event: event,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ];
                        }).toList(),

                        // 4. My Bookings Section
                        ...bookingsAsync.when(
                          data: (bookings) {
                            // flatMap booking orders to individual booked events
                            final List<Map<String, dynamic>> bookedEvents = [];
                            for (var booking in bookings) {
                              final items = booking['booked_events'] as List<dynamic>? ?? [];
                              for (var item in items) {
                                bookedEvents.add({
                                  ...item,
                                  'booking_id': booking['id'],
                                  'booking_reference': '#EVT-${booking['id']}',
                                  'total_amount': booking['total_amount'],
                                  'is_offline': booking['is_offline'],
                                });
                              }
                            }

                            // Filter into upcoming based on date (date >= today)
                            final now = DateTime.now();
                            final today = DateTime(now.year, now.month, now.day);

                            final upcoming = bookedEvents.where((e) {
                              final slotInfo = SlotInfo.tryParse(e['slot_info']);
                              if (slotInfo?.date == null) return true; // Default to upcoming if no date
                              final eventDate = DateTime.tryParse(slotInfo!.date!);
                              if (eventDate == null) return true;
                              return !eventDate.isBefore(today);
                            }).toList();

                            // Sort by nearest event date
                            upcoming.sort((a, b) {
                              final slotA = SlotInfo.tryParse(a['slot_info']);
                              final slotB = SlotInfo.tryParse(b['slot_info']);
                              if (slotA?.date == null && slotB?.date == null) return 0;
                              if (slotA?.date == null) return 1;
                              if (slotB?.date == null) return -1;
                              final dateA = DateTime.tryParse(slotA!.date!);
                              final dateB = DateTime.tryParse(slotB!.date!);
                              if (dateA == null && dateB == null) return 0;
                              if (dateA == null) return 1;
                              if (dateB == null) return -1;
                              return dateA.compareTo(dateB);
                            });

                            // Display maximum 3 cards
                            final displayEvents = upcoming.take(3).toList();

                            if (displayEvents.isEmpty) {
                              return [
                                SliverToBoxAdapter(
                                  child: _buildSectionHeader("My Bookings", () {
                                    context.go('/bookings?tab=0');
                                  }),
                                ),
                                SliverToBoxAdapter(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF16151A),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.04),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.calendar_today_outlined,
                                          color: Colors.white24,
                                          size: 40,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          "No upcoming events yet",
                                          style: GoogleFonts.breeSerif(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          "Explore events and reserve your first pass.",
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.breeSerif(
                                            color: Colors.white38,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ];
                            }

                            final displayBookings = displayEvents.map((e) {
                              return {
                                'id': e['booking_id'],
                                'booked_events': [e],
                                'line_total': e['total_amount'] ?? 0.0,
                              };
                            }).toList();

                            return [
                              SliverToBoxAdapter(
                                child: _buildSectionHeader("My Bookings", () {
                                  context.go('/bookings?tab=0');
                                }),
                              ),
                              SliverPadding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (ctx, idx) {
                                      final b = displayBookings[idx];
                                      return _buildBookingCard(context, b, allEvents);
                                    },
                                    childCount: displayBookings.length,
                                  ),
                                ),
                              ),
                            ];
                          },
                          loading: () => [],
                          error: (_, __) => [],
                        ),

                        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
                      ],
                    ],
                  );
                },
                loading: () => const CustomScrollView(
                  slivers: [
                    SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator(color: Color(0xFFFECF65))),
                    ),
                  ],
                ),
                error: (e, __) => CustomScrollView(
                  slivers: [
                    SliverFillRemaining(
                      child: Center(
                        child: Text(
                          "Error fetching events: $e",
                          style: GoogleFonts.breeSerif(color: Colors.redAccent),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: Color(0xFFFECF65))),
                ),
              ],
            ),
            error: (e, __) => CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      "Error fetching categories: $e",
                      style: GoogleFonts.breeSerif(color: Colors.redAccent),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helper Widgets ──────────────────────────────────────────────────────────

  Widget _buildPricePill(String label) {
    final isSel = _priceFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() => _priceFilter = label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFFFECF65) : const Color(0xFF16151A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSel ? const Color(0xFFFECF65) : Colors.white.withOpacity(0.04),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.breeSerif(
            color: isSel ? Colors.black : Colors.white70,
            fontSize: 13,
            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback? onSeeAll) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.breeSerif(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                "See all",
                style: GoogleFonts.breeSerif(
                  color: const Color(0xFFFECF65),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }



  Widget _buildParentCard(
    BuildContext context,
    String name,
    String description,
    List<Color> colors,
    CustomPainter painter,
    String route,
  ) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: painter,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.breeSerif(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.breeSerif(
                      color: Colors.white60,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, Map<String, dynamic> item, List<EventModel> allEvents) {
    final bookedEvents = item['booked_events'] as List<dynamic>? ?? [];
    if (bookedEvents.isEmpty) return const SizedBox.shrink();

    final bookedEvent = bookedEvents.first;
    final eventName = bookedEvent['event_name'] ?? 'Event';

    final eventMatch = allEvents.where((e) {
      return e.title.toLowerCase() == eventName.toString().toLowerCase();
    }).firstOrNull;

    final imageKey = bookedEvent['event_image'] ?? bookedEvent['image_key'] ?? eventMatch?.bannerImage;
    final price = eventMatch?.price ?? item['line_total'] ?? 0.0;

    return Consumer(
      builder: (context, ref, child) {
        String venue = 'Venue TBA';
        String? dateStr;
        if (eventMatch != null) {
          final detailsAsync = ref.watch(eventDetailsDataProvider(eventMatch.id.toString()));
          venue = detailsAsync.valueOrNull?['venue']?.toString() ?? 'Venue TBA';
          dateStr = detailsAsync.valueOrNull?['start_datetime']?.toString();
        }

        return GestureDetector(
          onTap: () {
            final id = bookedEvent['id'] ?? item['id'];
            if (id != null) context.push('/ticket/$id');
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF16151A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.04),
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 76,
                    height: 76,
                    child: AppCachedImage(
                      imageKey: imageKey,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eventName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.breeSerif(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 12, color: Color(0xFFFECF65)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              venue,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.breeSerif(color: Colors.white38, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 11, color: Colors.white30),
                          const SizedBox(width: 4),
                          Text(
                            _formatEventDate(dateStr),
                            style: GoogleFonts.breeSerif(color: Colors.white38, fontSize: 10),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.access_time_rounded, size: 11, color: Colors.white30),
                          const SizedBox(width: 4),
                          Text(
                            _formatEventTime(dateStr),
                            style: GoogleFonts.breeSerif(color: Colors.white38, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      price > 0 ? "₹${price.toStringAsFixed(0)}" : "Free",
                      style: GoogleFonts.breeSerif(
                        color: const Color(0xFFFECF65),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '#EVT-${item['id'] ?? 'XXX'}',
                      style: GoogleFonts.breeSerif(
                        color: Colors.white24,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}