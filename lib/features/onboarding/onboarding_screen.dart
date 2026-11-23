import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:studyspace/app/theme/studyspace_colors.dart';
import 'package:studyspace/app/widgets/pastel_card.dart';
import 'package:studyspace/core/db/app_database.dart';
import 'package:studyspace/core/db/database_providers.dart';
import 'package:studyspace/core/db/sample_seeder.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  bool _includeSampleData = true;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() => _saving = true);
    final db = ref.read(appDatabaseProvider);
    final rawName = _nameController.text.trim();
    final name = rawName.isEmpty ? 'Student' : rawName;
    final now = DateTime.now();

    if (_includeSampleData) {
      await seedSampleSemester(db, displayName: name, referenceNow: now);
    } else {
      await db.upsertProfile(
        UserProfilesCompanion.insert(
          id: 'default-profile',
          displayName: Value(name),
          onboardingDone: const Value(true),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    if (mounted) {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = StudySpaceColors.of(context);
    final t = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: c.primarySoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Icon(
                  PhosphorIconsFill.graduationCap,
                  color: c.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              Text('Welcome to StudySpace', style: t.displaySmall),
              const SizedBox(height: 10),
              Text(
                'Your calm space for classes, deadlines, exam countdowns, deep focus, and lecture notes — all offline on your device.',
                style: t.bodyLarge?.copyWith(color: c.inkSecondary, height: 1.5),
              ),
              const SizedBox(height: 32),
              Text('What should we call you?', style: t.titleSmall),
              const SizedBox(height: 10),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  hintText: 'Enter your name (e.g., Maya)',
                ),
              ),
              const SizedBox(height: 20),
              PastelCard(
                backgroundColor: c.surface,
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: c.mintSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        PhosphorIconsRegular.sparkle,
                        color: c.mint,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Start with sample semester data', style: t.titleSmall),
                          const SizedBox(height: 2),
                          Text(
                            'Explore classes, tasks, exams, and notes right away. Clear anytime in Settings.',
                            style: t.bodyMedium?.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _includeSampleData,
                      activeThumbColor: c.mint,
                      onChanged: (v) => setState(() => _includeSampleData = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: c.onPrimary,
                          ),
                        )
                      : const Text('Get started'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
