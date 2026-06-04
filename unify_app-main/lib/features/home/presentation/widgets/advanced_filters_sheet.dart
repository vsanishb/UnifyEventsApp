import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AdvancedFiltersSheet extends StatefulWidget {
  final List<String> selectedFests;
  final List<int> selectedCategories;
  final List<String> selectedConstraints;
  final dynamic categories;
  final DateTime? filterDate;
  final TimeOfDay? filterStartTime;
  final TimeOfDay? filterEndTime;
  final int? fixedTeamSize;
  final int? minTeamSize;
  final int? maxTeamSize;

  const AdvancedFiltersSheet({
    super.key,
    required this.selectedFests,
    required this.selectedCategories,
    required this.selectedConstraints,
    required this.categories,
    required this.filterDate,
    required this.filterStartTime,
    required this.filterEndTime,
    required this.fixedTeamSize,
    required this.minTeamSize,
    required this.maxTeamSize,
  });

  @override
  State<AdvancedFiltersSheet> createState() => _AdvancedFiltersSheetState();
}

class _AdvancedFiltersSheetState extends State<AdvancedFiltersSheet> {
  late List<String> _localFests;
  late List<int> _localCategories;
  late List<String> _localConstraints;
  DateTime? _localDate;
  TimeOfDay? _localStartTime;
  TimeOfDay? _localEndTime;

  late TextEditingController _fixedTeamSizeController;
  late TextEditingController _minTeamSizeController;
  late TextEditingController _maxTeamSizeController;

  String? _fixedTeamSizeError;
  String? _flexibleTeamSizeError;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _localFests = List.from(widget.selectedFests);
    _localCategories = List.from(widget.selectedCategories);
    _localConstraints = List.from(widget.selectedConstraints);
    _localDate = widget.filterDate;
    _localStartTime = widget.filterStartTime;
    _localEndTime = widget.filterEndTime;

    _fixedTeamSizeController = TextEditingController(
      text: widget.fixedTeamSize?.toString() ?? "",
    );
    _minTeamSizeController = TextEditingController(
      text: widget.minTeamSize?.toString() ?? "",
    );
    _maxTeamSizeController = TextEditingController(
      text: widget.maxTeamSize?.toString() ?? "",
    );

    _validateFilters();
  }

  @override
  void dispose() {
    _fixedTeamSizeController.dispose();
    _minTeamSizeController.dispose();
    _maxTeamSizeController.dispose();
    super.dispose();
  }

  void _validateFilters() {
    setState(() {
      _fixedTeamSizeError = null;
      _flexibleTeamSizeError = null;
      _hasError = false;

      if (_localConstraints.contains("fixed")) {
        final text = _fixedTeamSizeController.text.trim();
        if (text.isEmpty) {
          _fixedTeamSizeError = "Team size is required";
          _hasError = true;
        } else {
          final val = int.tryParse(text);
          if (val == null) {
            _fixedTeamSizeError = "Enter a valid number";
            _hasError = true;
          } else if (val <= 0) {
            _fixedTeamSizeError = "Must be greater than 0";
            _hasError = true;
          }
        }
      }

      if (_localConstraints.contains("flexible")) {
        final minText = _minTeamSizeController.text.trim();
        final maxText = _maxTeamSizeController.text.trim();

        if (minText.isEmpty || maxText.isEmpty) {
          _flexibleTeamSizeError = "Both minimum and maximum are required";
          _hasError = true;
        } else {
          final minVal = int.tryParse(minText);
          final maxVal = int.tryParse(maxText);

          if (minVal == null || maxVal == null) {
            _flexibleTeamSizeError = "Enter valid numbers";
            _hasError = true;
          } else if (minVal <= 0 || maxVal <= 0) {
            _flexibleTeamSizeError = "Sizes must be greater than 0";
            _hasError = true;
          } else if (minVal > maxVal) {
            _flexibleTeamSizeError = "Minimum cannot exceed maximum";
            _hasError = true;
          }
        }
      }
    });
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final hour = tod.hour > 12 ? tod.hour - 12 : (tod.hour == 0 ? 12 : tod.hour);
    final period = tod.hour >= 12 ? "PM" : "AM";
    final minuteStr = tod.minute.toString().padLeft(2, '0');
    final hourStr = hour.toString().padLeft(2, '0');
    return "$hourStr:$minuteStr $period";
  }

  Future<void> _pickStartTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _localStartTime ?? const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFECF65),
              onPrimary: Colors.black,
              surface: Color(0xFF16151A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _localStartTime = picked);
    }
  }

  Future<void> _pickEndTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _localEndTime ?? const TimeOfDay(hour: 18, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFECF65),
              onPrimary: Colors.black,
              surface: Color(0xFF16151A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _localEndTime = picked);
    }
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF16151A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Advanced Filters",
              style: GoogleFonts.breeSerif(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
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
                _buildFilterPill("Phase Shift", _localFests.contains("phaseshift"), () {
                  setState(() {
                    if (_localFests.contains("phaseshift")) {
                      _localFests.remove("phaseshift");
                    } else {
                      _localFests.add("phaseshift");
                    }
                  });
                }),
                _buildFilterPill("Utsav Fest", _localFests.contains("utsav"), () {
                  setState(() {
                    if (_localFests.contains("utsav")) {
                      _localFests.remove("utsav");
                    } else {
                      _localFests.add("utsav");
                    }
                  });
                }),
                _buildFilterPill("Regular Events", _localFests.contains("regular"), () {
                  setState(() {
                    if (_localFests.contains("regular")) {
                      _localFests.remove("regular");
                    } else {
                      _localFests.add("regular");
                    }
                  });
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
                  final isSel = _localCategories.contains(catId);
                  return _buildFilterPill(catName, isSel, () {
                    setState(() {
                      if (isSel) {
                        _localCategories.remove(catId);
                      } else {
                        _localCategories.add(catId);
                      }
                    });
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
                _buildFilterPill("Single Participant", _localConstraints.contains("single"), () {
                  setState(() {
                    if (_localConstraints.contains("single")) {
                      _localConstraints.remove("single");
                    } else {
                      _localConstraints.add("single");
                    }
                    _validateFilters();
                  });
                }),
                _buildFilterPill("Multiple (Fixed Team Size)", _localConstraints.contains("fixed"), () {
                  setState(() {
                    if (_localConstraints.contains("fixed")) {
                      _localConstraints.remove("fixed");
                    } else {
                      _localConstraints.add("fixed");
                    }
                    _validateFilters();
                  });
                }),
                _buildFilterPill("Multiple (Flexible Team Size)", _localConstraints.contains("flexible"), () {
                  setState(() {
                    if (_localConstraints.contains("flexible")) {
                      _localConstraints.remove("flexible");
                    } else {
                      _localConstraints.add("flexible");
                    }
                    _validateFilters();
                  });
                }),
              ],
            ),

            // Fixed Team Size Input
            if (_localConstraints.contains("fixed")) ...[
              const SizedBox(height: 16),
              Text(
                "TEAM SIZE",
                style: GoogleFonts.breeSerif(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _fixedTeamSizeController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: GoogleFonts.breeSerif(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1E1D22),
                  hintText: "Enter team size (e.g. 2)",
                  hintStyle: GoogleFonts.breeSerif(color: Colors.white24, fontSize: 13),
                  errorText: _fixedTeamSizeError,
                  errorStyle: GoogleFonts.breeSerif(color: Colors.redAccent),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.04)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.04)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFFECF65)),
                  ),
                ),
                onChanged: (val) => _validateFilters(),
              ),
            ],

            // Flexible Team Size Range Inputs
            if (_localConstraints.contains("flexible")) ...[
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "MINIMUM TEAM SIZE",
                          style: GoogleFonts.breeSerif(
                            color: Colors.white38,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _minTeamSizeController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: GoogleFonts.breeSerif(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF1E1D22),
                            hintText: "Min (e.g. 1)",
                            hintStyle: GoogleFonts.breeSerif(color: Colors.white24, fontSize: 13),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.04)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.04)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFFFECF65)),
                            ),
                          ),
                          onChanged: (val) => _validateFilters(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "MAXIMUM TEAM SIZE",
                          style: GoogleFonts.breeSerif(
                            color: Colors.white38,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _maxTeamSizeController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: GoogleFonts.breeSerif(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF1E1D22),
                            hintText: "Max (e.g. 5)",
                            hintStyle: GoogleFonts.breeSerif(color: Colors.white24, fontSize: 13),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.04)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.04)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFFFECF65)),
                            ),
                          ),
                          onChanged: (val) => _validateFilters(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_flexibleTeamSizeError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _flexibleTeamSizeError!,
                  style: GoogleFonts.breeSerif(color: Colors.redAccent, fontSize: 12),
                ),
              ],
            ],
            const SizedBox(height: 24),

            // 4. Date & Time Range Pickers
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
                  initialDate: _localDate ?? DateTime.now(),
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
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() => _localDate = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1D22),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _localDate != null ? const Color(0xFFFECF65) : Colors.white.withOpacity(0.04),
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
                          _localDate != null
                              ? "${_localDate!.day}/${_localDate!.month}/${_localDate!.year}"
                              : "Select Date",
                          style: GoogleFonts.breeSerif(
                            color: _localDate != null ? Colors.white : Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    if (_localDate != null)
                      GestureDetector(
                        onTap: () {
                          setState(() => _localDate = null);
                        },
                        child: const Icon(Icons.close, size: 16, color: Colors.white54),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Start & End Time Picker Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "START TIME",
                        style: GoogleFonts.breeSerif(
                          color: Colors.white38,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _pickStartTime(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1D22),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _localStartTime != null ? const Color(0xFFFECF65) : Colors.white.withOpacity(0.04),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _localStartTime != null ? _formatTimeOfDay(_localStartTime!) : "--:--",
                                style: GoogleFonts.breeSerif(
                                  color: _localStartTime != null ? Colors.white : Colors.white54,
                                  fontSize: 13,
                                ),
                              ),
                              if (_localStartTime != null)
                                GestureDetector(
                                  onTap: () {
                                    setState(() => _localStartTime = null);
                                  },
                                  child: const Icon(Icons.close, size: 14, color: Colors.white54),
                                )
                              else
                                const Icon(Icons.access_time_rounded, size: 14, color: Colors.white30),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "END TIME",
                        style: GoogleFonts.breeSerif(
                          color: Colors.white38,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _pickEndTime(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1D22),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _localEndTime != null ? const Color(0xFFFECF65) : Colors.white.withOpacity(0.04),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _localEndTime != null ? _formatTimeOfDay(_localEndTime!) : "--:--",
                                style: GoogleFonts.breeSerif(
                                  color: _localEndTime != null ? Colors.white : Colors.white54,
                                  fontSize: 13,
                                ),
                              ),
                              if (_localEndTime != null)
                                GestureDetector(
                                  onTap: () {
                                    setState(() => _localEndTime = null);
                                  },
                                  child: const Icon(Icons.close, size: 14, color: Colors.white54),
                                )
                              else
                                const Icon(Icons.access_time_rounded, size: 14, color: Colors.white30),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Bottom Buttons Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _localFests.clear();
                        _localCategories.clear();
                        _localConstraints.clear();
                        _localDate = null;
                        _localStartTime = null;
                        _localEndTime = null;
                        _fixedTeamSizeController.clear();
                        _minTeamSizeController.clear();
                        _maxTeamSizeController.clear();
                        _validateFilters();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFECF65),
                      side: const BorderSide(color: Color(0xFFFECF65)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      "Clear All",
                      style: GoogleFonts.breeSerif(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _hasError
                        ? null
                        : () {
                            Navigator.pop(context, {
                              'selectedFests': _localFests,
                              'selectedCategories': _localCategories,
                              'selectedConstraints': _localConstraints,
                              'filterDate': _localDate,
                              'filterStartTime': _localStartTime,
                              'filterEndTime': _localEndTime,
                              'fixedTeamSize': _localConstraints.contains("fixed")
                                  ? int.tryParse(_fixedTeamSizeController.text)
                                  : null,
                              'minTeamSize': _localConstraints.contains("flexible")
                                  ? int.tryParse(_minTeamSizeController.text)
                                  : null,
                              'maxTeamSize': _localConstraints.contains("flexible")
                                  ? int.tryParse(_maxTeamSizeController.text)
                                  : null,
                            });
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFECF65),
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: const Color(0xFFFECF65).withOpacity(0.3),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      "Apply Filters",
                      style: GoogleFonts.breeSerif(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
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
  }
}
