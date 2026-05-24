import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/content_scaffold.dart';
import '../../../shared/places/place_selection.dart';
import '../../../shared/widgets/place_map_preview_card.dart';
import '../../../shared/widgets/place_picker_field.dart';
import '../../auth/application/auth_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Costanti
// ─────────────────────────────────────────────────────────────────────────────

const _kTotalSteps = 4;

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _cityController = TextEditingController();

  int _currentStep = 0;
  String _selectedAccountType = 'modellista';
  Set<String> _selectedInterests = {};
  PlaceSelection? _selectedLocation;
  bool _saving = false;

  static const _accountTypes = <_AccountTypeOption>[
    _AccountTypeOption(
      key: 'modellista',
      emoji: '🏎',
      title: 'Modellista',
      description:
          'Pratico modellismo RC su pista. Voglio scoprire piste, tracciare le mie presenze e trovare negozi.',
    ),
    _AccountTypeOption(
      key: 'gestore_pista',
      emoji: '🏁',
      title: 'Gestore pista',
      description:
          'Gestisco una pista RC. Voglio aggiornare lo stato, pubblicare eventi e comunicare con i piloti.',
    ),
    _AccountTypeOption(
      key: 'gestore_negozio',
      emoji: '🏪',
      title: 'Gestore negozio',
      description:
          'Gestisco un negozio di modellismo RC. Voglio pubblicare la mia scheda e farmi trovare dagli appassionati.',
    ),
  ];

  static const _interestOptions = <_InterestOption>[
    _InterestOption(key: 'buggy',    emoji: '🏎', label: 'Buggy'),
    _InterestOption(key: 'touring',  emoji: '🚗', label: 'Touring'),
    _InterestOption(key: 'drift',    emoji: '💨', label: 'Drift'),
    _InterestOption(key: 'scaler',   emoji: '🪨', label: 'Scaler / Crawler'),
    _InterestOption(key: 'bashing',  emoji: '💥', label: 'Bashing'),
    _InterestOption(key: 'mini_z',   emoji: '🔵', label: 'Mini-Z'),
    _InterestOption(key: 'indoor',   emoji: '🏠', label: 'Indoor'),
    _InterestOption(key: 'outdoor',  emoji: '☀️', label: 'Outdoor / Offroad'),
    _InterestOption(key: 'droni',    emoji: '🚁', label: 'Droni FPV'),
    _InterestOption(key: 'treni',    emoji: '🚂', label: 'Treni'),
    _InterestOption(key: 'elettrico',emoji: '⚡', label: 'Elettrico'),
    _InterestOption(key: 'nitro',    emoji: '🔥', label: 'Nitro / Termico'),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _animateTo(int step) {
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
    );
  }

  void _goNext() {
    if (_currentStep < _kTotalSteps - 1) {
      setState(() => _currentStep++);
      _animateTo(_currentStep);
    }
  }

  void _goBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _animateTo(_currentStep);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);

    return ContentScaffold(
      title: l10n.onboardingTitle,
      description: '',
      child: Column(
        children: [
          _StepProgressBar(currentStep: _currentStep, totalSteps: _kTotalSteps),
          const SizedBox(height: 24),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // Step 1 — Chi sei?
                _StepPage(
                  child: _StepAccountType(
                    selectedKey: _selectedAccountType,
                    options: _accountTypes,
                    onSelect: (key) => setState(() => _selectedAccountType = key),
                  ),
                ),
                // Step 2 — Categoria / interessi
                _StepPage(
                  child: _StepInterests(
                    options: _interestOptions,
                    selected: _selectedInterests,
                    accountType: _selectedAccountType,
                    onToggle: (key) {
                      setState(() {
                        if (_selectedInterests.contains(key)) {
                          _selectedInterests = Set.from(_selectedInterests)..remove(key);
                        } else {
                          _selectedInterests = Set.from(_selectedInterests)..add(key);
                        }
                      });
                    },
                  ),
                ),
                // Step 3 — Città
                _StepPage(
                  child: _StepCity(
                    controller: _cityController,
                    initialSelection: _selectedLocation,
                    onLocationSelected: (sel) => _selectedLocation = sel,
                  ),
                ),
                // Step 4 — Obiettivo / Riepilogo
                _StepPage(
                  child: _StepSummary(
                    accountType: _accountTypes.firstWhere(
                      (o) => o.key == _selectedAccountType,
                    ),
                    interests: _selectedInterests,
                    interestOptions: _interestOptions,
                    city: _selectedLocation?.label ?? _cityController.text.trim(),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
            child: _OnboardingNav(
              currentStep: _currentStep,
              totalSteps: _kTotalSteps,
              saving: _saving,
              canProceed: user != null,
              onBack: _currentStep > 0 ? _goBack : null,
              onNext: _currentStep < _kTotalSteps - 1
                  ? _goNext
                  : () => _complete(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _complete(BuildContext context) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      context.go('/login');
      return;
    }

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    try {
      final client = ref.read(authClientProvider);
      final city = _selectedLocation?.label ?? _cityController.text.trim();
      final location = _selectedLocation;
      try {
        await client?.rpc(
          'complete_onboarding',
          params: {
            'p_preferred_city': city,
            'p_user_interests': _selectedInterests.toList(),
            'p_home_city': location?.city ?? location?.title ?? city,
            'p_home_country': location?.country,
            'p_home_latitude': location?.latitude,
            'p_home_longitude': location?.longitude,
          },
        );
      } catch (error) {
        debugPrint('[Onboarding] complete_onboarding location args unavailable: $error');
        await client?.rpc(
          'complete_onboarding',
          params: {
            'p_preferred_city': city,
            'p_user_interests': _selectedInterests.toList(),
          },
        );
      }

      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Benvenuto in PitLap! Il tuo profilo è pronto.'),
          duration: Duration(seconds: 3),
        ),
      );

      router.go('/');
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Errore durante il salvataggio: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 1 — Tipo account
// ─────────────────────────────────────────────────────────────────────────────

class _StepAccountType extends StatelessWidget {
  const _StepAccountType({
    required this.selectedKey,
    required this.options,
    required this.onSelect,
  });

  final String selectedKey;
  final List<_AccountTypeOption> options;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chi sei?',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.graphite,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Scegli il profilo che ti descrive meglio. Puoi aggiornarlo in qualsiasi momento dal tuo profilo.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.steel,
          ),
        ),
        const SizedBox(height: 24),
        ...options.map(
          (option) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _AccountTypeCard(
              option: option,
              selected: selectedKey == option.key,
              onTap: () => onSelect(option.key),
            ),
          ),
        ),
      ],
    );
  }
}

class _AccountTypeCard extends StatelessWidget {
  const _AccountTypeCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _AccountTypeOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.signalOrange.withAlpha(12)
              : const Color(0xFFF8F7F3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.signalOrange : AppColors.concrete,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.signalOrange.withAlpha(30)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.concrete),
              ),
              alignment: Alignment.center,
              child: Text(
                option.emoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          option.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? AppColors.signalOrange
                                : AppColors.graphite,
                          ),
                        ),
                      ),
                      if (selected)
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.signalOrange,
                          size: 20,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    option.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.steel,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 2 — Interessi / Categoria modellismo (KYC)
// ─────────────────────────────────────────────────────────────────────────────

class _StepInterests extends StatelessWidget {
  const _StepInterests({
    required this.options,
    required this.selected,
    required this.accountType,
    required this.onToggle,
  });

  final List<_InterestOption> options;
  final Set<String> selected;
  final String accountType;
  final ValueChanged<String> onToggle;

  String get _headline => switch (accountType) {
    'gestore_pista'   => 'Che tipo di pista gestisci?',
    'gestore_negozio' => 'Cosa vende il tuo negozio?',
    _                 => 'Cosa ti appassiona?',
  };

  String get _subtitle => switch (accountType) {
    'gestore_pista'   => 'Seleziona le categorie della tua pista. Aiutiamo i piloti giusti a trovarti.',
    'gestore_negozio' => 'Seleziona le specialità del tuo negozio. Mostriamo la tua scheda agli appassionati rilevanti.',
    _                 => 'Seleziona una o più categorie. Usiamo questi dati per mostrarti contenuti rilevanti nel tuo feed.',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _headline,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.graphite,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _subtitle,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.steel,
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options.map((opt) {
            final isSelected = selected.contains(opt.key);
            return _InterestChip(
              option: opt,
              selected: isSelected,
              onTap: () => onToggle(opt.key),
            );
          }).toList(),
        ),
        if (selected.isEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.warningAmber.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warningAmber.withAlpha(60)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppColors.warningAmber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Puoi saltare questo step — potrai sempre aggiornare gli interessi dal profilo.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.graphite,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          const SizedBox(height: 16),
          Text(
            '${selected.length} ${selected.length == 1 ? 'interesse selezionato' : 'interessi selezionati'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.signalOrange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _InterestChip extends StatelessWidget {
  const _InterestChip({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _InterestOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.signalOrange.withAlpha(18)
              : const Color(0xFFF8F7F3),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.signalOrange : AppColors.concrete,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(option.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              option.label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? AppColors.signalOrange : AppColors.graphite,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              Icon(Icons.check, size: 14, color: AppColors.signalOrange),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 3 — Città
// ─────────────────────────────────────────────────────────────────────────────

class _StepCity extends ConsumerStatefulWidget {
  const _StepCity({
    required this.controller,
    required this.onLocationSelected,
    this.initialSelection,
  });

  final TextEditingController controller;
  final PlaceSelection? initialSelection;
  final ValueChanged<PlaceSelection?> onLocationSelected;

  @override
  ConsumerState<_StepCity> createState() => _StepCityState();
}

class _StepCityState extends ConsumerState<_StepCity> {
  PlaceSelection? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialSelection;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'La tua zona',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.graphite,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Indicaci la tua città o provincia. La usiamo per mostrarti piste e negozi vicini.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.steel,
          ),
        ),
        const SizedBox(height: 32),
        PlacePickerField(
          controller: widget.controller,
          initialSelection: _selectedLocation,
          labelText: 'Città o provincia',
          hintText: 'es. Parma, Milano, Bologna...',
          emptyInfoText:
              'Usiamo questa informazione solo per migliorare la tua esperienza di discovery. Non la condividiamo con terze parti.',
          verifiedInfoBuilder: (selection) =>
              'Località verificata: ${selection.label}.',
          types: const <String>['municipality', 'locality', 'place', 'region'],
          onSelected: (selection) {
            setState(() => _selectedLocation = selection);
            widget.onLocationSelected(selection);
          },
        ),
        if (_selectedLocation != null) ...[
          const SizedBox(height: 16),
          PlaceMapPreviewCard(selection: _selectedLocation!, height: 190),
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F7F3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.concrete),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: AppColors.steel),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Puoi saltare questo step — potrai aggiornare la zona in qualsiasi momento dal profilo.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.steel,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 4 — Obiettivo / Riepilogo
// ─────────────────────────────────────────────────────────────────────────────

class _StepSummary extends StatelessWidget {
  const _StepSummary({
    required this.accountType,
    required this.interests,
    required this.interestOptions,
    required this.city,
  });

  final _AccountTypeOption accountType;
  final Set<String> interests;
  final List<_InterestOption> interestOptions;
  final String city;

  @override
  Widget build(BuildContext context) {
    final interestLabels = interestOptions
        .where((o) => interests.contains(o.key))
        .map((o) => '${o.emoji} ${o.label}')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quasi fatto!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.graphite,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Controlla i dati e conferma per entrare in PitLap.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.steel,
          ),
        ),
        const SizedBox(height: 28),
        // Riepilogo KYC
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F7F3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.concrete),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryRow(
                icon: Icons.person_outline,
                label: 'Profilo',
                value: '${accountType.emoji} ${accountType.title}',
              ),
              if (interestLabels.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),
                _SummaryRow(
                  icon: Icons.interests_outlined,
                  label: 'Interessi',
                  value: interestLabels.join(' · '),
                ),
              ],
              if (city.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),
                _SummaryRow(
                  icon: Icons.place_outlined,
                  label: 'Zona',
                  value: city,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Cosa succede dopo
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF6EFE3), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5DDD0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sei dentro — esplora la community',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              const _NextStepRow(
                icon: Icons.dynamic_feed_outlined,
                text: 'Novità dalla community in tempo reale',
              ),
              const _NextStepRow(
                icon: Icons.flag_outlined,
                text: 'Piste RC con stato aggiornato e servizi reali',
              ),
              const _NextStepRow(
                icon: Icons.place_outlined,
                text: 'Spot e negozi sul territorio',
              ),
              const _NextStepRow(
                icon: Icons.event_outlined,
                text: 'Eventi e gare aperti a tutti',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.steel),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.steel,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NextStepRow extends StatelessWidget {
  const _NextStepRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.signalOrange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.steel,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepPage extends StatelessWidget {
  const _StepPage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(child: child);
  }
}

class _StepProgressBar extends StatelessWidget {
  const _StepProgressBar({
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  static const _stepLabels = ['Chi sei', 'Interessi', 'Zona', 'Riepilogo'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: List.generate(totalSteps, (index) {
            final isActive = index <= currentStep;
            final isCompleted = index < currentStep;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index < totalSteps - 1 ? 6 : 0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 4,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.signalOrange
                            : const Color(0xFFE0DDD6),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    if (isCompleted)
                      const Icon(
                        Icons.check_circle,
                        size: 14,
                        color: AppColors.signalOrange,
                      ),
                  ],
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(totalSteps, (index) {
            return Text(
              _stepLabels[index],
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: index <= currentStep
                    ? AppColors.signalOrange
                    : AppColors.steel,
                fontWeight: index == currentStep
                    ? FontWeight.w700
                    : FontWeight.w400,
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _OnboardingNav extends StatelessWidget {
  const _OnboardingNav({
    required this.currentStep,
    required this.totalSteps,
    required this.saving,
    required this.canProceed,
    required this.onNext,
    this.onBack,
  });

  final int currentStep;
  final int totalSteps;
  final bool saving;
  final bool canProceed;
  final VoidCallback? onBack;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final isLast = currentStep == totalSteps - 1;

    return Row(
      children: [
        if (onBack != null)
          OutlinedButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_outlined),
            label: const Text('Indietro'),
          ),
        const Spacer(),
        FilledButton.icon(
          onPressed: saving ? null : onNext,
          icon: saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  isLast ? Icons.check_outlined : Icons.arrow_forward_outlined,
                ),
          label: Text(isLast ? 'Inizia a usare PitLap' : 'Avanti'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data classes
// ─────────────────────────────────────────────────────────────────────────────

class _AccountTypeOption {
  const _AccountTypeOption({
    required this.key,
    required this.emoji,
    required this.title,
    required this.description,
  });

  final String key;
  final String emoji;
  final String title;
  final String description;
}

class _InterestOption {
  const _InterestOption({
    required this.key,
    required this.emoji,
    required this.label,
  });

  final String key;
  final String emoji;
  final String label;
}
