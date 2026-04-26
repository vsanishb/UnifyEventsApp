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
                        _buildDomainItem(
                          context,
                          'UTSAV',
                          'CULTURAL FEST',
                          const Color(0xFFFF1C7C),
                          'assets/images/utsav.jpg',
                          '/events-list?type=utsav',
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
                // RECENT LOGS
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
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

                // AVAILABLE NODES
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                        child: Text(
                          "AVAILABLE NODES",
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white38,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      eventsAsync.when(
                        data: (allEvents) {
                          if (allEvents.isEmpty) return const SizedBox();
                          return SizedBox(
                            height: 180,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: allEvents.length,
                              itemBuilder: (ctx, i) =>
                                  _buildNodeCard(allEvents[i]),
                            ),
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => const SizedBox(),
                      ),
                    ],
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
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF13131D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF1C7C).withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFFFF1C7C), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
              decoration: InputDecoration(
                hintText: "SEARCH EVENTS...",
                hintStyle: GoogleFonts.plusJakartaSans(
                  color: Colors.white24,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 20),
              ),
            ),
          ),
        ],
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
      padding: const EdgeInsets.only(bottom: 32),
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
}
