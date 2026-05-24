import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';

/// Schermata 404 — mostrata da GoRouter quando la route non esiste.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                RichText(
                  text: TextSpan(
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.graphite,
                    ),
                    children: const [
                      TextSpan(text: 'Pit'),
                      TextSpan(
                        text: 'Lap',
                        style: TextStyle(color: AppColors.signalOrange),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // 404
                Text(
                  '404',
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.graphite,
                    letterSpacing: -4,
                  ),
                ),
                const SizedBox(height: 12),

                // Titolo
                Text(
                  'Pagina non trovata',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.graphite,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Sottotitolo
                Text(
                  'La pagina che stai cercando non esiste o è stata spostata.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.steel,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),

                // CTA primaria
                FilledButton.icon(
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('Torna alla home'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.signalOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
