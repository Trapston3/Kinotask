import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/standalone_alarm.dart';
import '../providers/standalone_alarm_provider.dart';
import '../theme/app_theme.dart';

class AlarmCreationSheet extends StatefulWidget {
  const AlarmCreationSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const AlarmCreationSheet(),
    );
  }

  @override
  State<AlarmCreationSheet> createState() => _AlarmCreationSheetState();
}

class _AlarmCreationSheetState extends State<AlarmCreationSheet> {
  TimeOfDay _selectedTime = TimeOfDay.now();
  final TextEditingController _labelController = TextEditingController();
  final Set<int> _repeatDays = {};

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'New Alarm',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),

          // ── Time Picker Inline ────────────────────────────────────
          SizedBox(
            height: 200,
            child: CupertinoTheme(
              data: CupertinoThemeData(
                textTheme: CupertinoTextThemeData(
                  dateTimePickerTextStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day,
                  _selectedTime.hour,
                  _selectedTime.minute,
                ),
                onDateTimeChanged: (DateTime newTime) {
                  setState(() => _selectedTime = TimeOfDay.fromDateTime(newTime));
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Label ─────────────────────────────────────────────────
          TextField(
            controller: _labelController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Label (optional)',
              hintStyle: const TextStyle(color: AppTheme.subtleGrey),
              filled: true,
              fillColor: AppTheme.islandSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.islandRadius),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Repeat days ───────────────────────────────────────────
          const Text(
            'Repeat',
            style: TextStyle(
              color: AppTheme.subtleGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final day = i + 1; // 1=Mon..7=Sun
              final selected = _repeatDays.contains(day);
              return GestureDetector(
                onTap: () => setState(() {
                  selected ? _repeatDays.remove(day) : _repeatDays.add(day);
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? AppTheme.accentBlue : AppTheme.islandSurface,
                  ),
                  child: Center(
                    child: Text(
                      _dayLabels[i],
                      style: TextStyle(
                        color: selected ? Colors.white : AppTheme.subtleGrey,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 28),

          // ── Save button ───────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              child: const Text('Save Alarm'),
            ),
          ),
        ],
      ),
    );
  }



  void _save() {
    final alarm = StandaloneAlarm(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      label: _labelController.text.trim(),
      hour: _selectedTime.hour,
      minute: _selectedTime.minute,
      repeatDays: _repeatDays.toList()..sort(),
    );
    context.read<StandaloneAlarmProvider>().addAlarm(alarm);
    Navigator.of(context).pop();
  }
}
