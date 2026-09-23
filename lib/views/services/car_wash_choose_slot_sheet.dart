import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CarWashChooseSlotSheet extends StatefulWidget {
  const CarWashChooseSlotSheet({super.key});

  static Future<Map<String, dynamic>?> show(BuildContext context) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => const CarWashChooseSlotSheet(),
    );
  }

  @override
  State<CarWashChooseSlotSheet> createState() => _CarWashChooseSlotSheetState();
}

class _CarWashChooseSlotSheetState extends State<CarWashChooseSlotSheet> {
  late final List<DateTime> _dates;
  int _selectedDateIndex = 0;
  int? _selectedSlotIndex;
  String? _warningMessage;

  static const _slots = [
    '8:00-10:00 AM',
    '10:00-12:00 PM',
    '2:00-4:00 PM',
    '4:00-6:00 PM',
  ];

  static const _months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    _dates = List.generate(14, (i) => start.add(Duration(days: i)));
  }

  String _dayLabel(DateTime date, int index) {
    if (index == 0) return 'Today';
    if (index == 1) return 'Tomorrow';
    return _weekdays[date.weekday - 1];
  }

  String _monthLabel(DateTime date) => _months[date.month - 1];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Color(0xFFFF5E00),
                size: 22,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(36),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFFFE6D8),
                          Color(0xFFFFF6F0),
                          Color(0xFFFFFFFF),
                        ],
                        stops: [0.0, 0.55, 1.0],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE8DC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.calendar_month_rounded,
                            color: Color(0xFFFF5E00),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Choose Your Slot',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF1A1A1A),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 6, 20, 18 + bottomInset),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDateHeader(),
                      const SizedBox(height: 14),
                      _buildDateList(),
                      const SizedBox(height: 22),
                      Text(
                        'Time Slot',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF1A1A1A),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTimeSlots(),
                      if (_warningMessage != null) ...[
                        const SizedBox(height: 14),
                        _buildWarning(),
                      ],
                      const SizedBox(height: 22),
                      _buildContinueButton(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader() {
    return Row(
      children: [
        Text(
          'Select Date',
          style: GoogleFonts.outfit(
            color: const Color(0xFF1A1A1A),
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _dates[_selectedDateIndex],
              firstDate: _dates.first,
              lastDate: _dates.first.add(const Duration(days: 60)),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFFFF5E00),
                      onPrimary: Colors.white,
                      onSurface: Color(0xFF1A1A1A),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked == null) return;
            final normalized = DateTime(picked.year, picked.month, picked.day);
            final index = _dates.indexWhere(
              (d) =>
                  d.year == normalized.year &&
                  d.month == normalized.month &&
                  d.day == normalized.day,
            );
            setState(() {
              if (index >= 0) {
                _selectedDateIndex = index;
              } else {
                _dates.add(normalized);
                _dates.sort();
                _selectedDateIndex = _dates.indexOf(normalized);
              }
              _selectedSlotIndex = null;
              _warningMessage = null;
            });
          },
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                color: Color(0xFFFF5E00),
                size: 14,
              ),
              const SizedBox(width: 5),
              Text(
                'Calendar View',
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFF5E00),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateList() {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _dates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final date = _dates[index];
          final selected = index == _selectedDateIndex;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedDateIndex = index;
              _selectedSlotIndex = null;
              _warningMessage = null;
            }),
            child: Container(
              width: 64,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? const Color(0xFFFF5E00)
                      : const Color(0xFFE8E4E0),
                  width: selected ? 1.6 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _monthLabel(date),
                    style: GoogleFonts.outfit(
                      color: selected
                          ? const Color(0xFFFF5E00)
                          : const Color(0xFFA39A93),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${date.day}',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF1A1A1A),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _dayLabel(date, index),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: selected
                          ? const Color(0xFFFF5E00)
                          : const Color(0xFFA39A93),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeSlots() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _timeChip(0)),
            const SizedBox(width: 10),
            Expanded(child: _timeChip(1)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _timeChip(2)),
            const SizedBox(width: 10),
            Expanded(child: _timeChip(3)),
          ],
        ),
      ],
    );
  }

  Widget _timeChip(int index) {
    final selected = _selectedSlotIndex == index;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedSlotIndex = index;
        _warningMessage = null;
      }),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected
                ? const Color(0xFFFF5E00)
                : const Color(0xFFE8E4E0),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.access_time_rounded,
              color: Color(0xFFFF5E00),
              size: 16,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                _slots[index],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF1A1A1A),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarning() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFE53935),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _warningMessage!,
              style: GoogleFonts.outfit(
                color: const Color(0xFFE53935),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return GestureDetector(
      onTap: () {
        if (_selectedSlotIndex == null) {
          setState(() {
            _warningMessage = 'Please select a date and time slot to continue';
          });
          return;
        }
        Navigator.of(context).pop({
          'date': _dates[_selectedDateIndex],
          'slot': _slots[_selectedSlotIndex!],
        });
      },
      child: Container(
        width: double.infinity,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF5E00), Color(0xFFFFAE00)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF5E00).withValues(alpha: 0.28),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          'Continue',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
