import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';

import '../providers/event_analytics_provider.dart';

class EventAnalyticsPage extends ConsumerStatefulWidget {
  final String eventId;

  const EventAnalyticsPage({super.key, required this.eventId});

  @override
  ConsumerState<EventAnalyticsPage> createState() => _EventAnalyticsPageState();
}

class _EventAnalyticsPageState extends ConsumerState<EventAnalyticsPage> {
  final Color goldColor = const Color(0xFFFECF65);
  final Color darkBg = const Color(0xFF0F0E11);
  final Color cardBg = const Color(0xFF16151A);

  @override
  Widget build(BuildContext context) {
    final analyticsAsync = ref.watch(eventAnalyticsProvider(widget.eventId));

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
          'EVENT ANALYTICS',
          style: GoogleFonts.breeSerif(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: analyticsAsync.when(
        data: (data) => RefreshIndicator(
          color: goldColor,
          backgroundColor: cardBg,
          onRefresh: () async {
            ref.invalidate(eventAnalyticsProvider(widget.eventId));
          },
          child: _buildDashboard(context, data),
        ),
        loading: () => _buildLoadingState(),
        error: (err, stack) => _buildErrorState(err.toString()),
      ),
    );
  }

  // --- LOADING STATE ---
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: goldColor),
          const SizedBox(height: 16),
          Text(
            'Analyzing event records...',
            style: GoogleFonts.breeSerif(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // --- ERROR STATE ---
  Widget _buildErrorState(String message) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              'Error Loading Analytics',
              style: GoogleFonts.breeSerif(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message.replaceAll('Exception:', '').trim(),
              textAlign: TextAlign.center,
              style: GoogleFonts.breeSerif(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: goldColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: Text(
                'Retry Connection',
                style: GoogleFonts.breeSerif(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              onPressed: () {
                ref.invalidate(eventAnalyticsProvider(widget.eventId));
              },
            )
          ],
        ),
      ),
    );
  }

  // --- DASHBOARD BUILDER ---
  Widget _buildDashboard(BuildContext context, Map<String, dynamic> data) {
    final header = data['event_header'] ?? {};
    final overview = data['overview'] ?? {};
    final timeline = data['registration_timeline'] ?? {};
    final tickets = data['ticket_analytics'] ?? {};
    final slots = List<Map<String, dynamic>>.from(data['slot_analytics'] ?? []);
    final revenue = data['revenue_analytics'] ?? {};
    final attendance = data['attendance_analytics'] ?? {};
    final insights = data['participant_insights'] ?? {};
    final organisers = data['organiser_analytics'] ?? {};
    final status = data['event_status'] ?? {};
    final topStats = data['top_statistics'] ?? {};

    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final screenWidth = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // EVENT HEADER CARD
            _buildHeaderSection(header, status),
            const SizedBox(height: 24),

            // OVERVIEW 2-COLUMN GRID
            _buildOverviewGrid(overview, isLandscape),
            const SizedBox(height: 24),

            // REGISTRATIONS SECTION
            _buildRegistrationsSection(timeline, tickets),
            const SizedBox(height: 24),

            // REVENUE SECTION
            _buildRevenueSection(revenue),
            const SizedBox(height: 24),

            // ATTENDANCE SECTION
            _buildAttendanceSection(attendance, organisers),
            const SizedBox(height: 24),

            // SLOTS CAPACITY SECTION
            _buildSlotsSection(slots),
            const SizedBox(height: 24),

            // PARTICIPANTS INSIGHTS SECTION
            _buildInsightsSection(insights),
            const SizedBox(height: 24),

            // TOP STATISTICS SECTION
            _buildTopStatisticsSection(topStats),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- SECTION BUILDERS ---

  Widget _buildHeaderSection(Map<String, dynamic> header, Map<String, dynamic> status) {
    final name = header['name'] ?? 'Unnamed Event';
    final parent = header['parent_event_name'];
    final category = header['category_name'] ?? 'General';
    final venue = header['venue'] ?? 'TBD';
    final date = header['date'] ?? 'TBD';
    final capStr = header['capacity'] ?? 'TBD';
    final statusStr = header['status'] ?? 'Upcoming';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: goldColor.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: goldColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: goldColor.withOpacity(0.3)),
                ),
                child: Text(
                  category,
                  style: GoogleFonts.breeSerif(color: goldColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusStr == 'Completed'
                      ? Colors.white24
                      : statusStr == 'Ongoing'
                          ? Colors.greenAccent.withOpacity(0.1)
                          : Colors.orangeAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: statusStr == 'Completed'
                        ? Colors.white30
                        : statusStr == 'Ongoing'
                            ? Colors.greenAccent
                            : Colors.orangeAccent,
                  ),
                ),
                child: Text(
                  statusStr.toUpperCase(),
                  style: GoogleFonts.breeSerif(
                    color: statusStr == 'Completed'
                        ? Colors.white70
                        : statusStr == 'Ongoing'
                            ? Colors.greenAccent
                            : Colors.orangeAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: GoogleFonts.breeSerif(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
          ),
          if (parent != null && parent.toString().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Part of: $parent',
              style: GoogleFonts.breeSerif(color: Colors.white38, fontSize: 14),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(color: Colors.white10),
          const SizedBox(height: 12),
          _buildIconLabel(Icons.location_on_outlined, venue),
          const SizedBox(height: 8),
          _buildIconLabel(Icons.calendar_month_outlined, date),
          const SizedBox(height: 8),
          _buildIconLabel(
            Icons.people_alt_outlined,
            'Capacity: $capStr Passes '
                '(${status['capacity_full'] == true ? "FULL" : "Spaces Available"})',
          ),
          if (status['days_remaining'] is int && status['days_remaining'] > 0) ...[
            const SizedBox(height: 8),
            _buildIconLabel(Icons.hourglass_bottom_rounded, '${status['days_remaining']} days remaining until start'),
          ]
        ],
      ),
    );
  }

  Widget _buildIconLabel(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: goldColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.breeSerif(color: Colors.white70, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewGrid(Map<String, dynamic> overview, bool isLandscape) {
    final double revenue = (overview['revenue'] ?? 0.0).toDouble();
    final int bookings = overview['confirmed_bookings'] ?? 0;
    final int registrations = overview['total_registrations'] ?? 0;
    final int attendanceCount = overview['attendance_count'] ?? 0;
    final double attendancePct = (overview['attendance_percentage'] ?? 0.0).toDouble();
    final String remainingCap = overview['remaining_capacity']?.toString() ?? 'TBD';
    final double avgBooking = (overview['average_booking_size'] ?? 0.0).toDouble();

    final List<Widget> cards = [
      _buildOverviewCard(
        'Total Revenue',
        revenue == 0.0 ? 'FREE' : '₹${revenue.toStringAsFixed(2)}',
        Icons.currency_rupee_rounded,
      ),
      _buildOverviewCard('Confirmed Bookings', bookings.toString(), Icons.confirmation_number_outlined),
      _buildOverviewCard('Registrations', registrations.toString(), Icons.person_add_alt_1_outlined),
      _buildOverviewCard(
        'Attendance',
        '$attendanceCount (${attendancePct.toStringAsFixed(1)}%)',
        Icons.where_to_vote_outlined,
      ),
      _buildOverviewCard('Remaining Space', remainingCap, Icons.event_seat_outlined),
      _buildOverviewCard('Avg booking size', avgBooking.toStringAsFixed(1), Icons.supervised_user_circle_outlined),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        if (isLandscape || constraints.maxWidth > 600) {
          crossAxisCount = 3;
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
          ),
          itemBuilder: (context, index) => cards[index],
        );
      },
    );
  }

  Widget _buildOverviewCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: goldColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: goldColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.breeSerif(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.breeSerif(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- REGISTRATIONS SECTION ---
  Widget _buildRegistrationsSection(Map<String, dynamic> timeline, Map<String, dynamic> tickets) {
    final int today = timeline['today'] ?? 0;
    final int last7 = timeline['last_7_days'] is List ? (timeline['last_7_days'] as List).fold<int>(0, (acc, item) => acc + ((item['count'] ?? 0) as int)) : 0;
    final int last30 = timeline['last_30_days'] is List ? (timeline['last_30_days'] as List).fold<int>(0, (acc, item) => acc + ((item['count'] ?? 0) as int)) : 0;

    final singleBookings = tickets['single_participant_bookings'] ?? 0;
    final teamBookings = tickets['team_bookings'] ?? 0;

    final last30DaysList = List<Map<String, dynamic>>.from(timeline['last_30_days'] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('REGISTRATION TIMELINE'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTimelineStat('Today', today.toString()),
                  _buildTimelineStat('Last 7 Days', last7.toString()),
                  _buildTimelineStat('Last 30 Days', last30.toString()),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Daily Registrations (Last 30 Days)',
                style: GoogleFonts.breeSerif(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // Line Chart
              SizedBox(
                height: 180,
                child: _buildRegistrationLineChart(last30DaysList),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Ticket type analytics donut
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: _buildResponsivePieChart(
            context: context,
            title: 'Booking Preferences',
            chart: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 30,
                sections: [
                  PieChartSectionData(
                    color: goldColor,
                    value: singleBookings.toDouble(),
                    title: '',
                    radius: 40,
                  ),
                  PieChartSectionData(
                    color: const Color(0xFFF97316),
                    value: teamBookings.toDouble(),
                    title: '',
                    radius: 40,
                  ),
                ],
              ),
            ),
            legends: [
              _buildLegendItem('Single Bookings : $singleBookings', goldColor),
              _buildLegendItem('Team Bookings : $teamBookings', const Color(0xFFF97316)),
              _buildLegendItem('Avg Team Size : ${(tickets['average_team_size'] ?? 0.0).toStringAsFixed(1)}', Colors.white30),
              _buildLegendItem('Largest Team Size : ${tickets['largest_team_size'] ?? 0}', Colors.white30),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineStat(String title, String val) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.breeSerif(color: Colors.white30, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          val,
          style: GoogleFonts.breeSerif(color: goldColor, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildRegistrationLineChart(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return Center(
        child: Text('No registration records available', style: GoogleFonts.breeSerif(color: Colors.white30)),
      );
    }

    final spots = list.asMap().entries.map((entry) {
      final idx = entry.key.toDouble();
      final val = (entry.value['count'] ?? 0).toDouble();
      return FlSpot(idx, val);
    }).toList();

    double maxVal = list.fold<double>(5.0, (currMax, item) {
      final v = (item['count'] ?? 0).toDouble();
      return v > currMax ? v : currMax;
    });

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: spots.length - 1.toDouble(),
        minY: 0,
        maxY: maxVal + 1,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: goldColor,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: goldColor.withOpacity(0.1),
            ),
          )
        ],
      ),
    );
  }

  // --- REVENUE SECTION ---
  Widget _buildRevenueSection(Map<String, dynamic> revenue) {
    final double total = (revenue['total_revenue'] ?? 0.0).toDouble();
    final int paid = revenue['paid_bookings'] ?? 0;
    final int free = revenue['free_bookings'] ?? 0;
    final double maxVal = (revenue['highest_booking_value'] ?? 0.0).toDouble();
    final double avgVal = (revenue['average_booking_value'] ?? 0.0).toDouble();

    final List<Map<String, dynamic>> dailyRevenueList = List<Map<String, dynamic>>.from(revenue['revenue_by_day'] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('REVENUE ANALYTICS'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildMetricRow('Total Revenue:', total == 0.0 ? 'FREE / INR 0.00' : 'INR ${total.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              _buildMetricRow('Paid Tickets Booked:', paid.toString()),
              const SizedBox(height: 8),
              _buildMetricRow('Free Tickets Booked:', free.toString()),
              const SizedBox(height: 8),
              _buildMetricRow('Highest Booking Value:', 'INR ${maxVal.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              _buildMetricRow('Average Booking Value:', 'INR ${avgVal.toStringAsFixed(2)}'),
              const SizedBox(height: 24),
              Text(
                'Daily Revenue Trend (Last 30 Days)',
                textAlign: TextAlign.center,
                style: GoogleFonts.breeSerif(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // Bar chart showing daily revenue
              SizedBox(
                height: 180,
                child: _buildRevenueBarChart(dailyRevenueList),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueBarChart(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return Center(
        child: Text('No booking revenue transactions', style: GoogleFonts.breeSerif(color: Colors.white30)),
      );
    }

    double maxVal = list.fold<double>(500.0, (currMax, item) {
      final v = (item['revenue'] ?? 0.0).toDouble();
      return v > currMax ? v : currMax;
    });

    final groups = list.asMap().entries.map((entry) {
      final idx = entry.key;
      final val = (entry.value['revenue'] ?? 0.0).toDouble();
      return BarChartGroupData(
        x: idx,
        barRods: [
          BarChartRodData(
            toY: val,
            color: goldColor,
            width: 5,
            borderRadius: BorderRadius.circular(2),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxVal,
              color: Colors.white10,
            ),
          )
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        barGroups: groups,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(
          show: true,
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
      ),
    );
  }

  // --- ATTENDANCE SECTION ---
  Widget _buildAttendanceSection(Map<String, dynamic> attendance, Map<String, dynamic> organisers) {
    final int checkedIn = attendance['checked_in_participants'] ?? 0;
    final int notCheckedIn = attendance['not_checked_in_participants'] ?? 0;
    final double attendancePct = (attendance['attendance_percentage'] ?? 0.0).toDouble();
    final int invalidScans = attendance['invalid_qr_scans'] ?? 0;
    final int rejectedScans = attendance['rejected_scans'] ?? 0;
    final int? peakHour = attendance['peak_check_in_hour'];

    final List<Map<String, dynamic>> activity = List<Map<String, dynamic>>.from(organisers['organiser_activity'] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('ATTENDANCE & ORGANISERS'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              _buildResponsivePieChart(
                context: context,
                title: 'Checked-In Status',
                chart: PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 28,
                    sections: [
                      PieChartSectionData(
                        color: const Color(0xFF10B981),
                        value: checkedIn.toDouble(),
                        title: '',
                        radius: 35,
                      ),
                      PieChartSectionData(
                        color: Colors.white24,
                        value: notCheckedIn.toDouble(),
                        title: '',
                        radius: 35,
                      ),
                    ],
                  ),
                ),
                legends: [
                  _buildLegendItem('Checked In : $checkedIn (${attendancePct.toStringAsFixed(1)}%)', const Color(0xFF10B981)),
                  _buildLegendItem('Remaining : $notCheckedIn', Colors.white24),
                  if (peakHour != null)
                    _buildLegendItem('Peak Check-In Hour : ${peakHour.toString().padLeft(2, '0')}:00', goldColor),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white10),
              const SizedBox(height: 8),
              _buildMetricRow('Invalid QR Scans Logs:', invalidScans.toString(), valueColor: Colors.redAccent),
              const SizedBox(height: 8),
              _buildMetricRow('Access Rejected Scans:', rejectedScans.toString(), valueColor: Colors.orangeAccent),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Organiser analytics list
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Organiser Scans Activity',
                style: GoogleFonts.breeSerif(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (activity.isEmpty)
                Text(
                  'No scans recorded by organisers yet.',
                  style: GoogleFonts.breeSerif(color: Colors.white30, fontSize: 13),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activity.length,
                  separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 16),
                  itemBuilder: (context, index) {
                    final org = activity[index];
                    final name = org['name'] ?? 'Unknown Organiser';
                    final scans = org['scans'] ?? 0;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.badge_outlined, size: 16, color: Colors.white54),
                            const SizedBox(width: 8),
                            Text(
                              name,
                              style: GoogleFonts.breeSerif(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                        Text(
                          '$scans Scans',
                          style: GoogleFonts.breeSerif(color: goldColor, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  // --- SLOTS CAPACITY SECTION ---
  Widget _buildSlotsSection(List<Map<String, dynamic>> slotsList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('SLOT ANALYTICS'),
        const SizedBox(height: 12),
        if (slotsList.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Text(
              'No slots defined for this event.',
              textAlign: TextAlign.center,
              style: GoogleFonts.breeSerif(color: Colors.white30),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: slotsList.length,
            itemBuilder: (context, index) {
              final slot = slotsList[index];
              final date = slot['date'] ?? '';
              final start = slot['start_time'] ?? '';
              final end = slot['end_time'] ?? '';
              final isUnlimited = slot['unlimited_badge'] == true;
              final booked = slot['booked_count'] ?? 0;
              final cap = slot['capacity'];
              final rem = slot['remaining_count'];
              final double occupancy = (slot['occupancy_percentage'] ?? 0.0).toDouble();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$date | $start - $end',
                          style: GoogleFonts.breeSerif(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        if (isUnlimited)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                            ),
                            child: Text(
                              'UNLIMITED',
                              style: GoogleFonts.breeSerif(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          )
                        else
                          Text(
                            'Occupancy: ${occupancy.toStringAsFixed(1)}%',
                            style: GoogleFonts.breeSerif(color: occupancy > 90 ? Colors.redAccent : goldColor, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (!isUnlimited) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Booked: $booked', style: GoogleFonts.breeSerif(color: Colors.white54, fontSize: 13)),
                          Text('Available: $rem / $cap', style: GoogleFonts.breeSerif(color: Colors.white54, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Progress Bar Capacity Meter
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: cap != null && cap > 0 ? booked / cap : 0.0,
                          minHeight: 8,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation<Color>(occupancy > 90 ? Colors.redAccent : goldColor),
                        ),
                      ),
                    ] else ...[
                      Text('Booked participants count: $booked', style: GoogleFonts.breeSerif(color: Colors.white70, fontSize: 13)),
                    ]
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // --- PARTICIPANTS INSIGHTS SECTION ---
  Widget _buildInsightsSection(Map<String, dynamic> insights) {
    final int total = insights['total_participants'] ?? 0;
    final int unique = insights['unique_participants'] ?? 0;
    final int repeat = insights['repeat_participants'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('PARTICIPANT INSIGHTS'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              _buildMetricRow('Total passes checked out:', total.toString()),
              const SizedBox(height: 8),
              _buildMetricRow('Unique registrations:', unique.toString()),
              const SizedBox(height: 8),
              _buildMetricRow('Repeat customer bookings:', repeat.toString()),
            ],
          ),
        ),
      ],
    );
  }

  // --- TOP STATISTICS SECTION ---
  Widget _buildTopStatisticsSection(Map<String, dynamic> topStats) {
    final peakBookingHr = topStats['peak_booking_hour'];
    final peakBookingDay = topStats['peak_booking_day'];
    final highestAttendance = topStats['highest_attendance_slot'];
    final lowestAttendance = topStats['lowest_attendance_slot'];
    final highestRevenue = topStats['highest_revenue_slot'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('TOP STATISTICS'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              _buildMetricRow('Peak Booking Hour:', peakBookingHr != null ? '${peakBookingHr.toString().padLeft(2, '0')}:00' : 'N/A'),
              const SizedBox(height: 8),
              _buildMetricRow('Peak Booking Day:', peakBookingDay ?? 'N/A'),
              const SizedBox(height: 8),
              _buildMetricRow('Highest Attendance Slot:', highestAttendance ?? 'N/A'),
              const SizedBox(height: 8),
              _buildMetricRow('Lowest Attendance Slot:', lowestAttendance ?? 'N/A'),
              const SizedBox(height: 8),
              _buildMetricRow('Highest Revenue Slot:', highestRevenue ?? 'N/A'),
            ],
          ),
        ),
      ],
    );
  }

  // --- UTILITY WIDGETS ---

  Widget _buildSectionHeader(String title) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: goldColor, width: 4)),
      ),
      child: Text(
        title,
        style: GoogleFonts.breeSerif(
          color: goldColor,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.breeSerif(color: Colors.white54, fontSize: 14),
          ),
        ),
        Text(
          value,
          textAlign: TextAlign.right,
          style: GoogleFonts.breeSerif(
            color: valueColor ?? Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.breeSerif(color: Colors.white70, fontSize: 13),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildResponsivePieChart({
    required BuildContext context,
    required Widget chart,
    required List<Widget> legends,
    required String title,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 480;

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.breeSerif(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 120,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: chart,
                ),
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: legends,
              ),
            ],
          );
        } else {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 120,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: chart,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.breeSerif(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...legends,
                  ],
                ),
              ),
            ],
          );
        }
      },
    );
  }
}
