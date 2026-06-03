import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/app_cached_image.dart';
import 'manage_event_modals.dart';
import 'manage_event_sub_modals.dart';
import '../providers/event_details_provider.dart';

class ManageEventCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> event;
  final bool isAdmin;

  const ManageEventCard({
    super.key,
    required this.event,
    required this.isAdmin,
  });

  @override
  ConsumerState<ManageEventCard> createState() => _ManageEventCardState();
}

class _ManageEventCardState extends ConsumerState<ManageEventCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;

  void _onHover(bool isHovered) => setState(() => _isHovered = isHovered);

  @override
  Widget build(BuildContext context) {
    final constraintAsync = ref.watch(constraintProvider(widget.event['id'].toString()));
    final eventName = widget.event['name'] ?? 'Unnamed Event';
    final committee =
        widget.event['parent_committee']?.toString() ?? 'Main Committee';
    final price = widget.event['price']?.toString() ?? 'FREE';
    final isExclusive = widget.event['exclusivity'] == 'EXCLUSIVE';
    final imageKey = widget.event['banner_image'];

    // Status parsing
    int parseSafeInt(dynamic val) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    final detailsId = parseSafeInt(widget.event['details_id']);
    final constraintId = parseSafeInt(widget.event['constraint_id']);
    final slotsCount = parseSafeInt(widget.event['slots_count']);

    print("EVENT CARD RENDER: ${widget.event}");

    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..translate(0.0, _isHovered ? -5.0 : 0.0),
        decoration: BoxDecoration(
          color: const Color(0xFF16151A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isHovered
                ? const Color(0xFFFECF65).withOpacity(0.3)
                : Colors.white.withOpacity(0.08),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // IMAGE COVER
            if (imageKey != null)
              SizedBox(
                height: 120,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: AppCachedImage(imageKey: imageKey, borderRadius: 0),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER INFO
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFECF65).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFECF65).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          committee,
                          style: const TextStyle(
                            color: Color(0xFFFECF65),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            price == 'FREE' || price == '0' ? 'FREE' : '₹$price',
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isExclusive ? Icons.lock : Icons.public,
                            size: 16,
                            color: isExclusive ? Colors.orange : Colors.white70,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // BODY
                  Text(
                    eventName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                   // STATUS INDICATORS
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildStatusChip(detailsId > 0, 'Details'),
                      _buildStatusChip(constraintId > 0, 'Constraints'),
                      _buildStatusChip(slotsCount > 0, 'Slots'),
                    ],
                  ),

                  constraintAsync.when(
                    data: (constraint) {
                      if (constraint == null) return const SizedBox();
                      String label = 'Single Participant';
                      if (constraint.bookingType == 'multiple') {
                        if (constraint.fixed) {
                          label = 'Multiple (Fixed Team Size of ${constraint.upperLimit})';
                        } else {
                          label = 'Multiple (Flexible Team Size: Min ${constraint.lowerLimit} - Max ${constraint.upperLimit})';
                        }
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 14,
                              color: Colors.white38,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Constraint: $label',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  ),

                  const SizedBox(height: 20),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 12),

                  // ACTION BUTTONS GRID
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              Icons.edit_outlined,
                              'Edit Event',
                              () => ManageEventModals.showEventModal(
                                context,
                                ref,
                                event: widget.event,
                              ),
                              baseColor: const Color(0xFFFECF65),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildActionButton(
                              Icons.info_outline,
                              'Details',
                              () => ManageEventSubModals.showDetailsModal(
                                context,
                                ref,
                                widget.event['id'],
                              ),
                              baseColor: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              Icons.list_alt_outlined,
                              'Constraints',
                              () => ManageEventSubModals.showConstraintsModal(
                                context,
                                ref,
                                widget.event['id'],
                              ),
                              baseColor: Colors.white60,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildActionButton(
                              Icons.access_time,
                              'Slots',
                              () => ManageEventSubModals.showSlotsModal(
                                context,
                                ref,
                                widget.event['id'],
                              ),
                              baseColor: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              Icons.groups_outlined,
                              'Attendance',
                              () {
                                /* Map to Attendance UI */
                              },
                              baseColor: const Color(0xFFFECF65),
                            ),
                          ),
                          if (widget.isAdmin) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildActionButton(
                                Icons.group_add_outlined,
                                'Organisers',
                                () => ManageEventModals.showOrganisersModal(
                                  context,
                                  ref,
                                  widget.event,
                                ),
                                baseColor: const Color(0xFFF97316),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (widget.isAdmin) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                Icons.delete_outline,
                                'Delete',
                                () => ManageEventModals.showDeleteEventModal(
                                  context,
                                  ref,
                                  widget.event['id'],
                                  eventName,
                                ),
                                baseColor: const Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool isActive, String label) {
    final Color chipColor = isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final IconData icon = isActive ? Icons.check_circle_outline : Icons.cancel_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: chipColor.withOpacity(0.6),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: chipColor,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: chipColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    VoidCallback onTap, {
    required Color baseColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: baseColor.withOpacity(0.04),
          border: Border.all(
            color: baseColor.withOpacity(0.4),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: baseColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: baseColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
