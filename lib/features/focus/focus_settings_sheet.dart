import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyspace/app/theme/studyspace_colors.dart';
import 'package:studyspace/features/focus/focus_controller.dart';

Future<void> showFocusSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const FocusSettingsSheet(),
  );
}

class FocusSettingsSheet extends ConsumerStatefulWidget {
  const FocusSettingsSheet({super.key});

  @override
  ConsumerState<FocusSettingsSheet> createState() => _FocusSettingsSheetState();
}

class _FocusSettingsSheetState extends ConsumerState<FocusSettingsSheet> {
  late int _focusMinutes;
  late int _shortBreakMinutes;
  late int _longBreakMinutes;
  late int _roundsPerCycle;
  late bool _autoStartBreak;
  late bool _chimeEnabled;

  @override
  void initState() {
    super.initState();
    final s = ref.read(focusControllerProvider);
    _focusMinutes = s.focusMinutes;
    _shortBreakMinutes = s.shortBreakMinutes;
    _longBreakMinutes = s.longBreakMinutes;
    _roundsPerCycle = s.roundsPerCycle;
    _autoStartBreak = s.autoStartBreak;
    _chimeEnabled = s.chimeEnabled;
  }

  Widget _stepper(String label, int value, String unit, int min, int max, int step,
      ValueChanged<int> onChanged) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: t.bodyLarge)),
          IconButton(
            onPressed: value > min ? () => onChanged(value - step) : null,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          SizedBox(
            width: 64,
            child: Text(
              '$value $unit',
              textAlign: TextAlign.center,
              style: t.titleSmall,
            ),
          ),
          IconButton(
            onPressed: value < max ? () => onChanged(value + step) : null,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = StudySpaceColors.of(context);
    final t = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Timer settings', style: t.titleLarge),
          const SizedBox(height: 12),
          _stepper('Focus session', _focusMinutes, 'min', 5, 90, 5,
              (v) => setState(() => _focusMinutes = v)),
          _stepper('Short break', _shortBreakMinutes, 'min', 1, 20, 1,
              (v) => setState(() => _shortBreakMinutes = v)),
          _stepper('Long break', _longBreakMinutes, 'min', 5, 45, 5,
              (v) => setState(() => _longBreakMinutes = v)),
          _stepper('Rounds per cycle', _roundsPerCycle, '', 2, 8, 1,
              (v) => setState(() => _roundsPerCycle = v)),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Auto-start breaks'),
            value: _autoStartBreak,
            activeThumbColor: c.mint,
            onChanged: (v) => setState(() => _autoStartBreak = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('End-of-session chime'),
            value: _chimeEnabled,
            activeThumbColor: c.mint,
            onChanged: (v) => setState(() => _chimeEnabled = v),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                await ref.read(focusControllerProvider.notifier).updateSettings(
                      focusMinutes: _focusMinutes,
                      shortBreakMinutes: _shortBreakMinutes,
                      longBreakMinutes: _longBreakMinutes,
                      roundsPerCycle: _roundsPerCycle,
                      autoStartBreak: _autoStartBreak,
                      chimeEnabled: _chimeEnabled,
                    );
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Save timer settings'),
            ),
          ),
        ],
      ),
    );
  }
}
