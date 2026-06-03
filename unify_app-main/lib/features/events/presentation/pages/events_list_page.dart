import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../events/presentation/providers/events_provider.dart';
import '../../../events/domain/models/event_model.dart';
import '../../../../shared/widgets/app_cached_image.dart';
import '../../presentation/providers/manage_events_provider.dart';
import '../providers/event_details_provider.dart';

class EventsListPage extends ConsumerStatefulWidget {
  final String type;

  const EventsListPage({super.key, required this.type});

  @override
  ConsumerState<EventsListPage> createState() => _EventsListPageState();
}

class _EventsListPageState extends ConsumerState<EventsListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _priceFilter = "All"; // "All", "Free", "Paid"
  final List<int> _selectedCategories = [];
  final List<String> _selectedConstraints = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _title {
    if (widget.type == 'phaseshift') return 'PhaseShift Events';
    if (widget.type == 'utsav') return 'Utsav Events';
    return 'Regular Events';
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

  List<EventModel> _getFilteredEvents(List<EventModel> events) {
    return events.where((e) {
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
      if (_selectedCategories.isNotEmpty) {
        if (e.categoryId == null || !_selectedCategories.contains(e.categoryId)) return false;
      }
      return true;
    }).toList();
  }

  void _showAdvancedFilters(BuildContext context, dynamic categories) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF16151A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx2).viewInsets.bottom + 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Advanced Filters",
                        style: GoogleFonts.breeSerif(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setModalState(() {
                            _selectedCategories.clear();
                            _selectedConstraints.clear();
                          });
                          setState(() {});
                        },
                        child: Text(
                          "Clear All",
                          style: GoogleFonts.breeSerif(
                            color: const Color(0xFFFECF65),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "EVENT CATEGORY",
                    style: GoogleFonts.breeSerif(
                      color: Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (categories is List)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categories.map<Widget>((cat) {
                        final catId = cat['id'] as int;
                        final catName = cat['name'] as String;
                        final isSel = _selectedCategories.contains(catId);
                        return _buildFilterPill(catName, isSel, () {
                          setModalState(() {
                            if (isSel) {
                              _selectedCategories.remove(catId);
                            } else {
                              _selectedCategories.add(catId);
                            }
                          });
                          setState(() {});
                        });
                      }).toList(),
                    )
                  else
                    const SizedBox(height: 40, child: Center(child: CircularProgressIndicator())),
                  const SizedBox(height: 24),
                  Text(
                    "PARTICIPATION CONSTRAINT",
                    style: GoogleFonts.breeSerif(
                      color: Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterPill("Single", _selectedConstraints.contains("single"), () {
                        setModalState(() {
                          if (_selectedConstraints.contains("single")) {
                            _selectedConstraints.remove("single");
                          } else {
                            _selectedConstraints.add("single");
                          }
                        });
                        setState(() {});
                      }),
                      _buildFilterPill("Multiple (Fixed Team Size)", _selectedConstraints.contains("fixed"), () {
                        setModalState(() {
                          if (_selectedConstraints.contains("fixed")) {
                            _selectedConstraints.remove("fixed");
                          } else {
                            _selectedConstraints.add("fixed");
                          }
                        });
                        setState(() {});
                      }),
                      _buildFilterPill("Multiple (Flexible Team Size)", _selectedConstraints.contains("flexible"), () {
                        setModalState(() {
                          if (_selectedConstraints.contains("flexible")) {
                            _selectedConstraints.remove("flexible");
                          } else {
                            _selectedConstraints.add("flexible");
                          }
                        });
                        setState(() {});
                      }),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterPill(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFECF65) : const Color(0xFF1E1D22),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFECF65) : Colors.white.withOpacity(0.04),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.breeSerif(
            color: isSelected ? Colors.black : Colors.white70,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    final filteredEventsAsync = ref.watch(filteredEventsProvider(widget.type));
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0E11),
      body: SafeArea(
        child: categoriesAsync.when(
          data: (categories) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(filteredEventsProvider(widget.type));
                ref.invalidate(categoriesProvider);
              },
              color: const Color(0xFFFECF65),
              backgroundColor: const Color(0xFF16151A),
              child: filteredEventsAsync.when(
                data: (rawEvents) {
                  final filtered = _getFilteredEvents(rawEvents);

                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // ── Search & Header bar (Screenshot 3) ───────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 16, 20, 16),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                                onPressed: () => context.pop(),
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
                                    onChanged: (val) {
                                      setState(() => _searchQuery = val);
                                    },
                                    style: GoogleFonts.breeSerif(color: Colors.white),
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(Icons.search, color: Colors.white30),
                                      hintText: "Search $_title...",
                                      hintStyle: GoogleFonts.breeSerif(color: Colors.white24, fontSize: 14),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () => _showAdvancedFilters(context, categories),
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
                          ),
                        ),
                      ),

                      // Filter Pills
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

                      // Event vertical list
                      if (filtered.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Text(
                              "No events found for $_title",
                              style: GoogleFonts.breeSerif(color: Colors.white30),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final event = filtered[index];
                                return Consumer(
                                  builder: (context, ref, child) {
                                    final constraintAsync = ref.watch(constraintProvider(event.id.toString()));
                                    final detailsAsync = ref.watch(eventDetailsDataProvider(event.id.toString()));

                                    return constraintAsync.when(
                                      data: (constraint) {
                                        if (_selectedConstraints.isNotEmpty) {
                                          bool matches = false;
                                          final type = constraint?.bookingType ?? 'single';
                                          final isFixed = constraint?.fixed ?? false;
                                          for (var filter in _selectedConstraints) {
                                            if (filter == 'single' && type == 'single') matches = true;
                                            if (filter == 'fixed' && type == 'multiple' && isFixed) matches = true;
                                            if (filter == 'flexible' && type == 'multiple' && !isFixed) matches = true;
                                          }
                                          if (!matches) {
                                            return const SizedBox.shrink();
                                          }
                                        }
                                        final venue = detailsAsync.valueOrNull?['venue']?.toString() ?? 'Venue TBA';
                                        return _buildEventCard(context, event, venue);
                                      },
                                      loading: () => const SizedBox(
                                        height: 100,
                                        child: Center(
                                          child: CircularProgressIndicator(color: Color(0xFFFECF65)),
                                        ),
                                      ),
                                      error: (_, __) {
                                        if (_selectedConstraints.isNotEmpty) {
                                          bool matches = _selectedConstraints.contains('single');
                                          if (!matches) return const SizedBox.shrink();
                                        }
                                        final venue = detailsAsync.valueOrNull?['venue']?.toString() ?? 'Venue TBA';
                                        return _buildEventCard(context, event, venue);
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
                    ],
                  );
                },
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: Color(0xFFFECF65))),
                ),
                error: (err, stack) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.redAccent,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            err.toString(),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.breeSerif(color: Colors.white70),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => ref.invalidate(filteredEventsProvider(widget.type)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFECF65),
                              foregroundColor: Colors.black,
                            ),
                            child: Text("Retry", style: GoogleFonts.breeSerif(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFECF65))),
          error: (e, __) => Center(child: Text("Error: $e", style: GoogleFonts.breeSerif(color: Colors.redAccent))),
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, EventModel event, String venue) {
    return GestureDetector(
      onTap: () => context.push('/event-details/${event.id}'),
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
                  imageKey: event.bannerImage,
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
                    event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.breeSerif(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    venue,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.breeSerif(
                      color: Colors.white30,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 11, color: Colors.white30),
                      const SizedBox(width: 4),
                      Text(
                        _formatEventDate(event.date),
                        style: GoogleFonts.breeSerif(color: Colors.white38, fontSize: 10),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.access_time_rounded, size: 11, color: Colors.white30),
                      const SizedBox(width: 4),
                      Text(
                        _formatEventTime(event.date),
                        style: GoogleFonts.breeSerif(color: Colors.white38, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              event.price != null && event.price! > 0 ? "₹${event.price}" : "Free",
              style: GoogleFonts.breeSerif(
                color: const Color(0xFFFECF65),
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
