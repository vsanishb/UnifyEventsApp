import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdvancedFiltersSheet extends StatefulWidget {
  final List<String> selectedFests;
  final List<int> selectedCategories;
  final List<String> selectedConstraints;
  final dynamic categories;
  final VoidCallback onChanged;
  final DateTime? filterDate;
  final String filterTimeSlot;
  final Function(DateTime?) onDateChanged;
  final Function(String) onTimeSlotChanged;

  const AdvancedFiltersSheet({
    super.key,
    required this.selectedFests,
    required this.selectedCategories,
    required this.selectedConstraints,
    required this.categories,
    required this.onChanged,
    required this.filterDate,
    required this.filterTimeSlot,
    required this.onDateChanged,
    required this.onTimeSlotChanged,
  });

  @override
  State<AdvancedFiltersSheet> createState() => _AdvancedFiltersSheetState();
}

class _AdvancedFiltersSheetState extends State<AdvancedFiltersSheet> {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF16151A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 40),
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
                  setState(() {
                    widget.selectedFests.clear();
                    widget.selectedCategories.clear();
                    widget.selectedConstraints.clear();
                  });
                  widget.onDateChanged(null);
                  widget.onTimeSlotChanged("Anytime");
                  widget.onChanged();
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
          
          // 1. Fest/Event Type
          Text(
            "FEST / EVENT TYPE",
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
              _buildFilterPill("Phase Shift", widget.selectedFests.contains("phaseshift"), () {
                setState(() {
                  if (widget.selectedFests.contains("phaseshift")) {
                    widget.selectedFests.remove("phaseshift");
                  } else {
                    widget.selectedFests.add("phaseshift");
                  }
                });
                widget.onChanged();
              }),
              _buildFilterPill("Utsav Fest", widget.selectedFests.contains("utsav"), () {
                setState(() {
                  if (widget.selectedFests.contains("utsav")) {
                    widget.selectedFests.remove("utsav");
                  } else {
                    widget.selectedFests.add("utsav");
                  }
                });
                widget.onChanged();
              }),
              _buildFilterPill("Regular Events", widget.selectedFests.contains("regular"), () {
                setState(() {
                  if (widget.selectedFests.contains("regular")) {
                    widget.selectedFests.remove("regular");
                  } else {
                    widget.selectedFests.add("regular");
                  }
                });
                widget.onChanged();
              }),
            ],
          ),
          const SizedBox(height: 24),

          // 2. Event Category
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
          if (widget.categories is List)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (widget.categories as List).map<Widget>((cat) {
                final catId = cat['id'] as int;
                final catName = cat['name'] as String;
                final isSel = widget.selectedCategories.contains(catId);
                return _buildFilterPill(catName, isSel, () {
                  setState(() {
                    if (isSel) {
                      widget.selectedCategories.remove(catId);
                    } else {
                      widget.selectedCategories.add(catId);
                    }
                  });
                  widget.onChanged();
                });
              }).toList(),
            )
          else
            const SizedBox(height: 40, child: Center(child: CircularProgressIndicator())),
          const SizedBox(height: 24),

          // 3. Participation Constraint
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
              _buildFilterPill("Single", widget.selectedConstraints.contains("single"), () {
                setState(() {
                  if (widget.selectedConstraints.contains("single")) {
                    widget.selectedConstraints.remove("single");
                  } else {
                    widget.selectedConstraints.add("single");
                  }
                });
                widget.onChanged();
              }),
              _buildFilterPill("Multiple (Fixed Team Size)", widget.selectedConstraints.contains("fixed"), () {
                setState(() {
                  if (widget.selectedConstraints.contains("fixed")) {
                    widget.selectedConstraints.remove("fixed");
                  } else {
                    widget.selectedConstraints.add("fixed");
                  }
                });
                widget.onChanged();
              }),
              _buildFilterPill("Multiple (Flexible Team Size)", widget.selectedConstraints.contains("flexible"), () {
                setState(() {
                  if (widget.selectedConstraints.contains("flexible")) {
                    widget.selectedConstraints.remove("flexible");
                  } else {
                    widget.selectedConstraints.add("flexible");
                  }
                });
                widget.onChanged();
              }),
            ],
          ),
          const SizedBox(height: 24),

          // 4. Date & Time Filter
          Text(
            "DATE & TIME FILTER",
            style: GoogleFonts.breeSerif(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: widget.filterDate ?? DateTime.now(),
                firstDate: DateTime(2025),
                lastDate: DateTime(2030),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: Color(0xFFFECF65),
                        onPrimary: Colors.black,
                        surface: Color(0xFF16151A),
                        onSurface: Colors.white,
                      ),
                      dialogBackgroundColor: const Color(0xFF0F0E11),
                    ),
                    child: child!,
                  );
                },
              );
              widget.onDateChanged(picked);
              widget.onChanged();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1D22),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.filterDate != null ? const Color(0xFFFECF65) : Colors.white.withOpacity(0.04),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFFFECF65)),
                      const SizedBox(width: 8),
                      Text(
                        widget.filterDate != null
                            ? "${widget.filterDate!.day}/${widget.filterDate!.month}/${widget.filterDate!.year}"
                            : "Select Date",
                        style: GoogleFonts.breeSerif(
                          color: widget.filterDate != null ? Colors.white : Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  if (widget.filterDate != null)
                    GestureDetector(
                      onTap: () {
                        widget.onDateChanged(null);
                        widget.onChanged();
                      },
                      child: const Icon(Icons.close, size: 16, color: Colors.white54),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterPill("Anytime", widget.filterTimeSlot == "Anytime", () {
                  widget.onTimeSlotChanged("Anytime");
                  widget.onChanged();
                }),
                const SizedBox(width: 8),
                _buildFilterPill("Morning", widget.filterTimeSlot == "Morning", () {
                  widget.onTimeSlotChanged("Morning");
                  widget.onChanged();
                }),
                const SizedBox(width: 8),
                _buildFilterPill("Afternoon", widget.filterTimeSlot == "Afternoon", () {
                  widget.onTimeSlotChanged("Afternoon");
                  widget.onChanged();
                }),
                const SizedBox(width: 8),
                _buildFilterPill("Evening", widget.filterTimeSlot == "Evening", () {
                  widget.onTimeSlotChanged("Evening");
                  widget.onChanged();
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
