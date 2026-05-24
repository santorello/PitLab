import 'package:flutter/material.dart';

import '../../app/bootstrap/app_config.dart';
import '../../app/theme/app_colors.dart';

class EnvironmentBanner extends StatelessWidget {
  const EnvironmentBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (AppConfig.hasSupabaseConfig) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningAmber.withAlpha(26),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.warningAmber.withAlpha(90)),
      ),
      child: Text(
        'Supabase non configurato. Avvia l\'app con --dart-define=SUPABASE_URL e --dart-define=SUPABASE_PUBLISHABLE_KEY.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
