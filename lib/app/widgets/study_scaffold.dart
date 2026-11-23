import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:studyspace/app/theme/studyspace_colors.dart';

class StudyScaffold extends StatelessWidget {
  const StudyScaffold({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  static const _tabs = <(String, IconData, IconData)>[
    ('Home', PhosphorIconsRegular.house, PhosphorIconsFill.house),
    ('Timetable', PhosphorIconsRegular.calendarBlank, PhosphorIconsFill.calendarBlank),
    ('Assignments', PhosphorIconsRegular.clipboardText, PhosphorIconsFill.clipboardText),
    ('Focus', PhosphorIconsRegular.target, PhosphorIconsFill.target),
    ('Notes', PhosphorIconsRegular.note, PhosphorIconsFill.note),
  ];

  @override
  Widget build(BuildContext context) {
    final c = StudySpaceColors.of(context);
    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.border, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 68,
            child: Row(
              children: List.generate(_tabs.length, (index) {
                final (label, icon, activeIcon) = _tabs[index];
                final isSelected = index == currentIndex;
                return Expanded(
                  child: InkWell(
                    key: Key('nav_tab_$label'),
                    onTap: () {
                      navigationShell.goBranch(
                        index,
                        initialLocation: index == currentIndex,
                      );
                    },
                    child: Semantics(
                      selected: isSelected,
                      button: true,
                      label: label,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? c.primarySoft : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              isSelected ? activeIcon : icon,
                              size: 22,
                              color: isSelected ? c.primary : c.inkSecondary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 11,
                              fontWeight:
                                  isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? c.primary : c.inkSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
