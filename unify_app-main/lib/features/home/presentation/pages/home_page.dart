import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../events/presentation/providers/events_provider.dart';
import '../../../events/domain/models/event_model.dart';
import '../../../../shared/widgets/r2_image_widget.dart';
import '../../../bookings/presentation/providers/bookings_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final FocusNode _searchFocusNode = FocusNode();
  final PageController _upcomingPageController = PageController(
    viewportFraction: 0.68,
  );

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _upcomingPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final eventsAsync = ref.watch(eventsProvider);
    final bookingsAsync = ref.watch(myBookingsProvider);
    final isSearching = _searchQuery.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(eventsProvider);
            ref.invalidate(myBookingsProvider);
          },
          color: const Color(0xFFFF1C7C),
          backgroundColor: Colors.black,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isSearching) ...[
                        Row(
                          children: [
                            Text(
                              "WELCOME ",
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              (user?.username ?? "ANI").toUpperCase(),
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFFFF1C7C),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        _buildSearchBar(),
                        const SizedBox(height: 32),
                        _buildDomainItem(
                          context,
                          'PHASE SHIFT',
                          'TECH SYMPOSIUM',
                          const Color(0xFF00E5FF),
                          'assets/images/phaseshift.jpg',
                          '/events-list?type=phaseshift',
                        ),
                        _buildFadeSeparator(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 56,
                            vertical: 10,
                          ),
                        ),
                        _buildDomainItem(
                          context,
                          'UTSAV',
                          'CULTURAL FEST',
                          const Color(0xFFFF1C7C),
                          'assets/images/utsav.jpg',
                          '/events-list?type=utsav',
                        ),
                        _buildFadeSeparator(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 56,
                            vertical: 10,
                          ),
                        ),
                        _buildDomainItem(
                          context,
                          'CLUB EVENTS',
                          'STUDENT GUILDS',
                          const Color(0xFF39FF14),
                          null,
                          '/events-list?type=regular',
                          icon: Icons.school,
                        ),
                      ] else ...[
                        _buildSearchBar(),
                      ],
                    ],
                  ),
                ),
              ),

              if (isSearching)
                _buildSearchResults(eventsAsync)
              else ...[
                // UPCOMING EVENTS / SUGGESTED EVENTS
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: bookingsAsync.when(
                      data: (bookings) {
                        return eventsAsync.when(
                          data: (allEvents) {
                            final upcomingEvents = _extractUpcomingEvents(
                              bookings,
                              allEvents,
                            );
                            final hasBookings = upcomingEvents.isNotEmpty;
                            final suggestedSection =
                                _buildSuggestedEventsSection(
                                  eventsAsync,
                                  showHeader: hasBookings,
                                );

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hasBookings
                                      ? 'YOUR UPCOMING EVENTS'
                                      : 'SUGGESTED EVENTS',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  hasBookings
                                      ? 'All of your booked tickets are shown below.'
                                      : 'Pick from PhaseShift, Utsav, and Club events.',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white38,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (hasBookings) ...[
                                  _buildUpcomingEventsCarousel(upcomingEvents),
                                  const SizedBox(height: 32),
                                  suggestedSection,
                                ] else ...[
                                  suggestedSection,
                                ],
                              ],
                            );
                          },
                          loading: () => const Padding(
                            padding: EdgeInsets.only(top: 24),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (e, _) => Text(
                            'ERROR: $e',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.redAccent,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => Text(
                        'ERROR: $e',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.redAccent,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),

                // RECENT LOGS
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "RECENT LOGS",
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white38,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        bookingsAsync.when(
                          data: (logs) => logs.isEmpty
                              ? Text(
                                  "NO LOGS FOUND",
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white10,
                                    fontSize: 12,
                                  ),
                                )
                              : Column(
                                  children: logs
                                      .take(1)
                                      .map((l) => _buildLogCard(l))
                                      .toList(),
                                ),
                          loading: () => const SizedBox(
                            height: 100,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (e, _) => Text(
                            "ERROR: $e",
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.redAccent,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF14141B),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.32),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: const Color(0xFFFF1C7C),
        decoration: InputDecoration(
          hintText: 'Search for events, seminars, hackathons...',
          hintStyle: GoogleFonts.plusJakartaSans(
            color: Colors.white38,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildFadeSeparator({EdgeInsetsGeometry padding = EdgeInsets.zero}) {
    return Padding(
      padding: padding,
      child: Container(
        height: 3,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              Colors.white.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDomainItem(
    BuildContext context,
    String title,
    String subtitle,
    Color color,
    String? assetPath,
    String route, {
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(route),
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF13131D),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: assetPath != null
                      ? Image.asset(
                          assetPath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            icon ?? Icons.event,
                            color: Colors.white,
                            size: 24,
                          ),
                        )
                      : Icon(
                          icon ?? Icons.event,
                          color: Colors.white,
                          size: 24,
                        ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white12,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<_UpcomingEventCardData> _extractUpcomingEvents(
    List<dynamic> bookings,
    List<FullEvent> allEvents,
  ) {
    final cards = <_UpcomingEventCardData>[];

    for (final booking in bookings) {
      final bookingMap = _toMap(booking);
      final bookedEvents = bookingMap['booked_events'] as List<dynamic>? ?? [];
      for (final bookedEvent in bookedEvents) {
        final bookedEventMap = _toMap(bookedEvent);
        final participants =
            bookedEventMap['participants'] as List<dynamic>? ?? [];
        cards.add(
          _UpcomingEventCardData(
            eventName: bookedEventMap['event_name']?.toString() ?? 'Event',
            slotInfo: bookedEventMap['slot_info']?.toString() ?? '',
            bannerImage: _resolveUpcomingBannerImage(
              bookedEventMap['event_name']?.toString() ?? 'Event',
              allEvents,
            ),
            ticketsCount: participants.isNotEmpty
                ? participants.length
                : int.tryParse(
                        bookedEventMap['participants_count']?.toString() ?? '',
                      ) ??
                      1,
            bookingId:
                bookedEventMap['id']?.toString() ??
                bookingMap['id']?.toString() ??
                '',
          ),
        );
      }
    }

    return cards;
  }

  Widget _buildUpcomingEventsCarousel(List<_UpcomingEventCardData> items) {
    return SizedBox(
      height: 260,
      child: PageView.builder(
        controller: _upcomingPageController,
        padEnds: false,
        itemCount: items.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildUpcomingEventCard(items[index]),
          );
        },
      ),
    );
  }

  Widget _buildUpcomingEventCard(_UpcomingEventCardData item) {
    return GestureDetector(
      onTap: item.bookingId.isEmpty
          ? null
          : () => context.push('/ticket/${item.bookingId}'),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF13131D),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (item.bannerImage != null)
              R2ImageWidget(
                imageKey: item.bannerImage,
                height: double.infinity,
                width: double.infinity,
                borderRadius: 0,
              )
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A1A24), Color(0xFF0C0C12)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.confirmation_number_outlined,
                    color: Colors.white24,
                    size: 52,
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.65),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    item.eventName.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: Text(
                          '${item.ticketsCount} TICKETS',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (item.slotInfo.isNotEmpty)
                        Expanded(
                          child: Text(
                            item.slotInfo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '#${item.bookingId}',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
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

  Widget _buildSuggestedEventsSection(
    AsyncValue<List<FullEvent>> eventsAsync, {
    required bool showHeader,
  }) {
    return eventsAsync.when(
      data: (allEvents) {
        final phaseShift = _takeLimitedByCategory(allEvents, 'phaseshift', 2);
        final utsav = _takeLimitedByCategory(allEvents, 'utsav', 2);
        final club = _takeLimitedByCategory(allEvents, 'regular', 2);

        if (phaseShift.isEmpty && utsav.isEmpty && club.isEmpty) {
          return const SizedBox();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader) ...[
              Text(
                'SUGGESTED EVENTS',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'A few picks from each event group.',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (phaseShift.isNotEmpty) ...[
              _buildSuggestionGroupHeader('PHASE SHIFT'),
              const SizedBox(height: 12),
              ...phaseShift.map(_buildSuggestionCard),
              const SizedBox(height: 18),
            ],
            if (utsav.isNotEmpty) ...[
              _buildSuggestionGroupHeader('UTSAV'),
              const SizedBox(height: 12),
              ...utsav.map(_buildSuggestionCard),
              const SizedBox(height: 18),
            ],
            if (club.isNotEmpty) ...[
              _buildSuggestionGroupHeader('CLUB EVENTS'),
              const SizedBox(height: 12),
              ...club.map(_buildSuggestionCard),
            ],
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildSuggestionGroupHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        color: Colors.white38,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildSuggestionCard(FullEvent fullEvent) {
    return GestureDetector(
      onTap: () => context.push('/event-details/${fullEvent.event.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF13131D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withOpacity(0.04),
              ),
              clipBehavior: Clip.antiAlias,
              child: R2ImageWidget(
                imageKey: fullEvent.event.bannerImage,
                height: 44,
                width: 44,
                borderRadius: 0,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullEvent.event.title.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fullEvent.event.price != null && fullEvent.event.price! > 0
                        ? '₹${fullEvent.event.price}'
                        : 'FREE',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white12,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  List<FullEvent> _takeLimitedByCategory(
    List<FullEvent> allEvents,
    String category,
    int limit,
  ) {
    final normalized = category.toLowerCase().replaceAll(' ', '');

    bool matches(FullEvent event) {
      final parentName = event.parent?.name.toLowerCase().replaceAll(' ', '');
      if (normalized == 'phaseshift') {
        return event.event.parentEventId == 1 || parentName == 'phaseshift';
      }
      if (normalized == 'utsav') {
        return event.event.parentEventId == 2 || parentName == 'utsav';
      }
      return event.event.parentEventId != 1 && event.event.parentEventId != 2;
    }

    return allEvents.where(matches).take(limit).toList();
  }

  Map<String, dynamic> _toMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  String? _resolveUpcomingBannerImage(
    String eventName,
    List<FullEvent> allEvents,
  ) {
    final normalizedName = eventName.toLowerCase().replaceAll(' ', '');
    for (final event in allEvents) {
      final title = event.event.title.toLowerCase().replaceAll(' ', '');
      if (title == normalizedName ||
          title.contains(normalizedName) ||
          normalizedName.contains(title)) {
        return event.event.bannerImage;
      }
    }
    return null;
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF3D081E), const Color(0xFF13131D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "ID_${log['id']}",
                style: GoogleFonts.jetBrainsMono(
                  color: const Color(0xFFFF1C7C).withOpacity(0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "4/14/2026",
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white24,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "TRANSFER CONFIRMED",
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "₹${log['total_amount']}.00",
            style: GoogleFonts.jetBrainsMono(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeCard(FullEvent fullEvent) {
    return GestureDetector(
      onTap: () => context.push('/event-details/${fullEvent.event.id}'),
      child: Container(
        width: 300,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF13131D),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              R2ImageWidget(
                imageKey: fullEvent.event.bannerImage,
                height: double.infinity,
                width: double.infinity,
                borderRadius: 0,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black, Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.confirmation_num_outlined,
                          color: Color(0xFFFF1C7C),
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "EVENT ACCESS TOKEN",
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "VALUE",
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white30,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fullEvent.event.title.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(AsyncValue<List<FullEvent>> eventsAsync) {
    return eventsAsync.when(
      data: (events) {
        final filtered = events
            .where((e) => e.event.title.toLowerCase().contains(_searchQuery))
            .toList();
        if (filtered.isEmpty)
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                  "NO NODES FOUND",
                  style: GoogleFonts.plusJakartaSans(color: Colors.white24),
                ),
              ),
            ),
          );
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildSearchItem(filtered[i]),
              ),
              childCount: filtered.length,
            ),
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) =>
          SliverToBoxAdapter(child: Center(child: Text("ERROR: $e"))),
    );
  }

  Widget _buildSearchItem(FullEvent fullEvent) {
    return GestureDetector(
      onTap: () => context.push('/event-details/${fullEvent.event.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF13131D),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: R2ImageWidget(
                imageKey: fullEvent.event.bannerImage,
                width: 60,
                height: 60,
                borderRadius: 0,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullEvent.event.title.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    fullEvent.event.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white38,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "₹${fullEvent.event.price ?? 0}",
              style: GoogleFonts.jetBrainsMono(
                color: const Color(0xFFFF1C7C),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Small model for rendering booked ticket summaries on the home page.
}

class _UpcomingEventCardData {
  final String eventName;
  final String slotInfo;
  final int ticketsCount;
  final String bookingId;
  final String? bannerImage;

  _UpcomingEventCardData({
    required this.eventName,
    required this.slotInfo,
    required this.ticketsCount,
    required this.bookingId,
    required this.bannerImage,
  });
}
