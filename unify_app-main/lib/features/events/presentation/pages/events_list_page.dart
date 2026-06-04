import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../events/presentation/providers/events_provider.dart';
import '../../../events/domain/models/event_model.dart';
import '../../../../shared/widgets/compact_event_row.dart';
import '../../presentation/providers/manage_events_provider.dart';
import '../providers/event_details_provider.dart';
import '../../../home/presentation/widgets/advanced_filters_sheet.dart';
import '../../../../core/utils/datetime_utils.dart';


class EventsListPage extends ConsumerStatefulWidget {
  final String type;
  final int? initialCategoryId;

  const EventsListPage({super.key, required this.type, this.initialCategoryId});

  @override
  ConsumerState<EventsListPage> createState() => _EventsListPageState();
}

class _EventsListPageState extends ConsumerState<EventsListPage> {
  @override
  void initState() {
    super.initState();
    if (widget.initialCategoryId != null) {
      _selectedCategories.add(widget.initialCategoryId!);
    }
  }
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _priceFilter = "All"; // "All", "Free", "Paid"
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

  String _getTitle(List<dynamic> categories) {
    if (widget.type == 'phaseshift') return 'PhaseShift Events';
    if (widget.type == 'utsav') return 'Utsav Events';
    if (_selectedCategories.length == 1) {
      try {
        final catId = _selectedCategories.first;
        final cat = categories.firstWhere((c) => c['id'] == catId);
        return "${cat['name']} Events";
      } catch (_) {}
    }
    return 'Regular Events';
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

  void _showAdvancedFilters(BuildContext context, dynamic categories) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => AdvancedFiltersSheet(
        selectedFests: const [],
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
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Search & Header bar (Back, Search, Filter) ─────────────────
                Padding(
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
                              hintText: "Search ${_getTitle(categories)}...",
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

                // ── Filter Chips (All, Free, Paid) ───────────────────────────
                Padding(
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
                const SizedBox(height: 16),

                // ── Event vertical list with Pull-to-Refresh ──────────────────
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(filteredEventsProvider(widget.type));
                      ref.invalidate(categoriesProvider);
                    },
                    color: const Color(0xFFFECF65),
                    backgroundColor: const Color(0xFF16151A),
                    child: filteredEventsAsync.when(
                      data: (rawEvents) {
                        final filtered = _getFilteredEvents(rawEvents);

                        if (filtered.isEmpty) {
                          return ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.5,
                                child: Center(
                                  child: Text(
                                    "No events found for ${_getTitle(categories)}",
                                    style: GoogleFonts.breeSerif(color: Colors.white30),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }

                        return ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final event = filtered[index];
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
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12.0),
                                      child: CompactEventRow(event: event),
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
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12.0),
                                      child: CompactEventRow(event: event),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(color: Color(0xFFFECF65)),
                      ),
                      error: (err, stack) => ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
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
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFECF65))),
          error: (e, __) => Center(child: Text("Error: $e", style: GoogleFonts.breeSerif(color: Colors.redAccent))),
        ),
      ),
    );
  }
}
