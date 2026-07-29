import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/l10n/generated/app_localizations.dart';
import '../../../app/l10n/locale_controller.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/content_scaffold.dart';
import '../../../shared/media/media_upload_controller.dart';
import '../../../shared/media/media_upload_labels.dart';
import '../../../shared/media/media_upload_service.dart';
import '../../../shared/media/media_upload_state.dart';
import '../../../shared/widgets/adaptive_image.dart';
import '../../../shared/widgets/external_links_section.dart';
import '../../../shared/widgets/image_transfer_progress_card.dart';
import '../../auth/application/auth_providers.dart';
import '../../pitcoin/presentation/pitcoin_badges_section.dart';
import '../../pitcoin/presentation/pitcoin_balance_card.dart';
import '../../garage/application/garage_providers.dart';
import '../../shops/application/public_shops_provider.dart';
import '../../shops/application/shop_follows_providers.dart';
import '../../tracks/application/tracks_providers.dart';
import '../application/profile_hub_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final sessionUser = ref.watch(currentUserProvider);
    final isImpersonating = ref.watch(isImpersonatingProvider);
    final effectiveUserId = ref.watch(effectiveUserIdProvider);
    final profileAsync = ref.watch(effectiveUserProfileProvider);
    final consentsAsync = ref.watch(effectiveUserConsentsProvider);
    final allTracksAsync = ref.watch(publicTracksProvider);
    final followedTrackIdsAsync = ref.watch(effectiveFollowedTrackIdsProvider);
    final savedShopIdsAsync = ref.watch(effectiveFollowedShopIdsProvider);
    final allPublicShopsAsync = ref.watch(publicShopsProvider);
    final createdEventsAsync = ref.watch(effectiveCreatedEventsProvider);
    final garageState = ref.watch(garageProvider);
    final languageValue = Localizations.localeOf(context).languageCode == 'it'
        ? 'Italiano'
        : 'English';
    final emailValue = isImpersonating
        ? _profileText(
            context,
            it: 'Profilo impersonato',
            en: 'Impersonated profile',
          )
        : (sessionUser?.email ?? l10n.profileNotSignedIn);
    final visibleName = profileAsync.maybeWhen(
      data: (profile) {
        final displayName = profile?.displayName.trim() ?? '';
        if (displayName.isNotEmpty) {
          return displayName;
        }
        if (emailValue.contains('@')) {
          return emailValue.split('@').first;
        }
        return emailValue;
      },
      orElse: () => emailValue,
    );
    final avatarUrl = profileAsync.maybeWhen(
      data: (profile) => profile?.avatarUrl,
      orElse: () => null,
    );
    final roleValue = profileAsync.maybeWhen(
      data: (profile) => profile?.role ?? 'user',
      orElse: () => 'user',
    );
    final favoriteTrackEntries = allTracksAsync.maybeWhen(
      data: (tracks) => followedTrackIdsAsync.maybeWhen(
        data: (followedTrackIds) => tracks
            .where((track) => followedTrackIds.contains(track.id))
            .map(
              (track) => _CollectionEntry(
                title: track.name,
                subtitle: track.city,
                onTap: () => context.go('/track/${track.slug}'),
              ),
            )
            .toList(),
        orElse: () => const <_CollectionEntry>[],
      ),
      orElse: () => followedTrackIdsAsync.maybeWhen(
        data: (followedTrackIds) => followedTrackIds
            .map(
              (trackId) => _CollectionEntry(
                title: trackId,
                onTap: null,
              ),
            )
            .toList(),
        orElse: () => const <_CollectionEntry>[],
      ),
    );
    final favoriteShopEntries = savedShopIdsAsync.maybeWhen(
      data: (savedShopIds) => allPublicShopsAsync.maybeWhen(
        data: (allShops) => allShops
            .where((shop) => savedShopIds.contains(shop.id))
            .map(
              (shop) => _CollectionEntry(
                title: shop.name,
                subtitle: shop.city,
                onTap: () => context.go('/shop/${shop.slug}'),
              ),
            )
            .toList(),
        orElse: () => const <_CollectionEntry>[],
      ),
      orElse: () => const <_CollectionEntry>[],
    );
    final createdEventEntries = createdEventsAsync.maybeWhen(
      data: (createdEvents) => createdEvents
          .map(
            (event) => _CollectionEntry(
              title: event.title,
              subtitle: event.location,
              trailing: event.date,
              onTap: () => context.go('/event/${event.id}'),
            ),
          )
          .toList(),
      orElse: () => const <_CollectionEntry>[],
    );
    final buildEntries = garageState.builds
        .map(
          (build) => _CollectionEntry(
            title: build.title,
            subtitle: build.meta,
            onTap: () => context.go('/garage'),
          ),
        )
        .toList();
    final overviewTiles = [
      _OverviewTileData(
        emoji: '🏁',
        label: l10n.profileFavoriteTracks,
        value: followedTrackIdsAsync.maybeWhen(
          data: (ids) => ids.length.toString(),
          orElse: () => '0',
        ),
        helper: _profileText(
          context,
          it: favoriteTrackEntries.isEmpty
              ? 'Nessuna pista salvata.'
              : 'Apri l\'elenco delle piste che segui.',
          en: favoriteTrackEntries.isEmpty
              ? 'No saved tracks yet.'
              : 'Open the list of tracks you follow.',
        ),
        onTap: () => _openCollectionSheet(
          context: context,
          title: l10n.profileFavoriteTracks,
          entries: favoriteTrackEntries,
          emptyMessage: l10n.profileFavoriteTracksEmpty,
        ),
      ),
      _OverviewTileData(
        emoji: '🛒',
        label: l10n.profileFavoriteShops,
        value: savedShopIdsAsync.maybeWhen(
          data: (ids) => ids.length.toString(),
          orElse: () => '0',
        ),
        helper: _profileText(
          context,
          it: favoriteShopEntries.isEmpty
              ? 'Nessun negozio salvato.'
              : 'Apri l\'elenco dei negozi salvati.',
          en: favoriteShopEntries.isEmpty
              ? 'No saved shops yet.'
              : 'Open the list of saved shops.',
        ),
        onTap: () => _openCollectionSheet(
          context: context,
          title: l10n.profileFavoriteShops,
          entries: favoriteShopEntries,
          emptyMessage: l10n.profileFavoriteShopsEmpty,
        ),
      ),
      _OverviewTileData(
        emoji: '📅',
        label: l10n.profileCreatedEventsTitle,
        value: createdEventsAsync.maybeWhen(
          data: (events) => events.length.toString(),
          orElse: () => '0',
        ),
        helper: _profileText(
          context,
          it: createdEventEntries.isEmpty
              ? 'Nessun evento creato.'
              : 'Apri gli eventi che hai pubblicato.',
          en: createdEventEntries.isEmpty
              ? 'No created events yet.'
              : 'Open the events you published.',
        ),
        onTap: () => _openCollectionSheet(
          context: context,
          title: l10n.profileCreatedEventsTitle,
          entries: createdEventEntries,
          emptyMessage: l10n.profileCreatedEventsEmpty,
        ),
      ),
      _OverviewTileData(
        emoji: '🔧',
        label: l10n.profileFavoriteBuilds,
        value: garageState.builds.length.toString(),
        helper: _profileText(
          context,
          it: buildEntries.isEmpty
              ? 'Nessuna build nel garage.'
              : 'Apri il garage per gestire le tue build.',
          en: buildEntries.isEmpty
              ? 'No builds in your garage yet.'
              : 'Open the garage to manage your builds.',
        ),
        onTap: () => _openCollectionSheet(
          context: context,
          title: l10n.profileFavoriteBuilds,
          entries: buildEntries,
          emptyMessage: l10n.profileFavoriteBuildsEmpty,
        ),
      ),
    ];

    return ContentScaffold(
      title: l10n.profileTitle,
      description: l10n.profileDescription,
      child: ListView(
        children: [
          Card(
            color: AppColors.graphite,
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '👤 ${l10n.profileTitle}',
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AvatarPreview(
                        imageUrl: avatarUrl,
                        fallbackLabel: visibleName,
                        size: 88,
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              visibleName,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _profileText(
                                context,
                                it:
                                    'Il tuo spazio personale per profilo, garage, eventi e attivita\' dentro PitLap.',
                                en:
                                    'Your personal space for profile, garage, events, and activity inside PitLap.',
                              ),
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: AppColors.concrete),
                            ),
                            const SizedBox(height: 18),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _StatusChip(
                                  label: sessionUser != null
                                      ? '🟢 ${l10n.accountActiveNow}'
                                      : '👀 ${l10n.guestModeLabel}',
                                ),
                                _StatusChip(label: '🌐 $languageValue'),
                                _StatusChip(
                                  label:
                                      '🏷️ ${_roleLabel(l10n, roleValue)}',
                                ),
                                if (isImpersonating)
                                  _StatusChip(
                                    label: _profileText(
                                      context,
                                      it: 'Vista impersonata',
                                      en: 'Impersonated view',
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (sessionUser != null) ...[
            const PitcoinBalanceCard(),
            const SizedBox(height: 18),
          ],
          if (isImpersonating)
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Card(
                color: AppColors.signalOrange.withAlpha(18),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _profileText(
                      context,
                      it:
                          'Stai vedendo il profilo dell\'utente impersonato. Le azioni sensibili dell\'account reale restano disabilitate finche\' non esci dalla vista impersonata.',
                      en:
                          'You are viewing the impersonated user profile. Sensitive real-account actions stay disabled until you leave impersonation.',
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.graphite,
                    ),
                  ),
                ),
              ),
            ),
          _ProfileSection(
            eyebrow: '🧭 View d’insieme',
            title: 'Panoramica account',
            body:
                'Una lettura rapida di ciò che segui, salvi e pubblichi dentro PitLap.',
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: overviewTiles
                  .map(
                    (tile) => _OverviewTile(
                      data: tile,
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 18),
          _ProfileSection(
            eyebrow: '🪪 Identita',
            title: l10n.profileBasicsTitle,
            body: l10n.profileBasicsBody,
            child: _ProfileBasicsEditor(
              targetUserId: effectiveUserId,
              canEdit: !isImpersonating && sessionUser != null,
              emailValue: emailValue,
              profileAsync: profileAsync,
            ),
          ),
          const SizedBox(height: 18),
          _ProfileSection(
            eyebrow: '⚡ Collegamenti',
            title: l10n.profileQuickLinksTitle,
            body: l10n.profileQuickLinksBody,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _QuickLinkCard(
                  emoji: '🏎️',
                  label: l10n.garageTitle,
                  onTap: () => context.go('/garage'),
                ),
                _QuickLinkCard(
                  emoji: '📅',
                  label: l10n.eventsTitle,
                  onTap: () => context.go('/events'),
                ),
                _QuickLinkCard(
                  emoji: '🔐',
                  label: l10n.legalPrivacyTitle,
                  onTap: () => context.go('/legal/privacy'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _ProfileSection(
            eyebrow: '🔗 Presenza',
            title: l10n.externalLinksTitle,
            body: l10n.externalLinksProfileBody,
            child: Column(
              children: [
                ExternalLinksSection(
                  entityType: 'profile',
                  entityId: effectiveUserId ?? 'guest',
                  title: '',
                  body: '',
                  editable: !isImpersonating && sessionUser != null,
                ),
                const SizedBox(height: 16),
                _ActionRow(
                  label: l10n.profileOnboardingAction,
                  icon: Icons.route_outlined,
                  helper: l10n.profileOnboardingActionHint,
                  onTap: () => context.go('/onboarding'),
                ),
              ],
            ),
          ),
          if (sessionUser != null) ...[
            const SizedBox(height: 18),
            _ProfileSection(
              eyebrow: '🏆 ${l10n.pitcoinBadgesTitle}',
              title: l10n.pitcoinBadgesTitle,
              body: l10n.pitcoinBadgesSubtitle,
              child: const PitcoinBadgesSection(),
            ),
          ],
          const SizedBox(height: 18),
          _ProfileSection(
            eyebrow: '🛡️ Privacy',
            title: l10n.profilePrivacyTitle,
            body: l10n.profilePrivacyBody,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _PublicProfileSettings(),
                const SizedBox(height: 16),
                _ConsentSummary(consentsAsync: consentsAsync),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _ProfileSection(
            eyebrow: '⚙️ Impostazioni',
            title: l10n.profileSettingsTitle,
            body: l10n.profileSettingsBody,
            child: Column(
              children: [
                _ActionRow(
                  label: l10n.profileChangeEmail,
                  icon: Icons.alternate_email_outlined,
                  helper: l10n.profileChangeEmailHint,
                  onTap: sessionUser == null || isImpersonating
                      ? null
                      : () => _showChangeEmailDialog(
                          context,
                          ref,
                          l10n,
                          sessionUser.email ?? '',
                        ),
                ),
                const SizedBox(height: 10),
                _ActionRow(
                  label: l10n.profileResetPassword,
                  icon: Icons.lock_reset_outlined,
                  helper: l10n.profileResetPasswordHint,
                  onTap: sessionUser == null || isImpersonating
                      ? null
                      : () => _showMagicLinkDialog(
                          context,
                          ref,
                          l10n,
                          sessionUser.email ?? '',
                        ),
                ),
                const SizedBox(height: 10),
                _ActionRow(
                  label: l10n.profileSignOut,
                  icon: Icons.logout,
                  helper: l10n.profileSignOutHint,
                  onTap: sessionUser == null || isImpersonating
                      ? null
                      : () async {
                          final client = ref.read(authClientProvider);
                          if (client == null) {
                            return;
                          }
                          await client.auth.signOut();
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.profileSignedOutMessage),
                            ),
                          );
                          context.go('/');
                        },
                ),
                const SizedBox(height: 10),
                _ActionRow(
                  label: l10n.profileCloseAccount,
                  icon: Icons.person_off_outlined,
                  danger: true,
                  helper: l10n.profileCloseAccountHint,
                  onTap: sessionUser == null || isImpersonating
                      ? null
                      : () => _showDeleteAccountDialog(context, ref, l10n),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Cambio email reale ────────────────────────────────────────────────────
  static Future<void> _showChangeEmailDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    String currentEmail,
  ) async {
    final controller = TextEditingController();
    bool sending = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(l10n.profileChangeEmail),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _profileText(
                  ctx,
                  it: 'Email attuale: $currentEmail\n\nInserisci la nuova email. Riceverai un link di conferma su entrambi gli indirizzi.',
                  en: 'Current email: $currentEmail\n\nEnter your new email. A confirmation link will be sent to both addresses.',
                ),
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nuova email',
                  hintText: 'nome@esempio.com',
                  prefixIcon: Icon(Icons.alternate_email_outlined),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.profileCancelEdit),
            ),
            FilledButton(
              onPressed: sending
                  ? null
                  : () async {
                      final newEmail = controller.text.trim();
                      if (newEmail.isEmpty || !newEmail.contains('@')) return;
                      setState(() => sending = true);
                      try {
                        final client = ref.read(authClientProvider);
                        await client?.auth.updateUser(
                          UserAttributes(email: newEmail),
                        );
                        if (!ctx.mounted) return;
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _profileText(
                                context,
                                it: 'Conferma inviata a $newEmail. Controlla la casella e clicca il link per completare il cambio.',
                                en: 'Confirmation sent to $newEmail. Check your inbox and click the link to complete the change.',
                              ),
                            ),
                            duration: const Duration(seconds: 6),
                          ),
                        );
                      } catch (e) {
                        if (!ctx.mounted) return;
                        setState(() => sending = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Errore: $e')),
                        );
                      }
                    },
              child: sending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Invia conferma'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }

  // ── Reset accesso via magic link ──────────────────────────────────────────
  static Future<void> _showMagicLinkDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    String currentEmail,
  ) async {
    bool sending = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(l10n.profileResetPassword),
          content: Text(
            _profileText(
              ctx,
              it: 'Ti invieremo un nuovo magic link all\'indirizzo $currentEmail per rientrare nell\'account.',
              en: 'We will send a new magic link to $currentEmail so you can sign back in.',
            ),
            style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.profileCancelEdit),
            ),
            FilledButton(
              onPressed: sending || currentEmail.isEmpty
                  ? null
                  : () async {
                      setState(() => sending = true);
                      try {
                        final client = ref.read(authClientProvider);
                        await client?.auth.signInWithOtp(email: currentEmail);
                        if (!ctx.mounted) return;
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _profileText(
                                context,
                                it: 'Magic link inviato a $currentEmail.',
                                en: 'Magic link sent to $currentEmail.',
                              ),
                            ),
                          ),
                        );
                      } catch (e) {
                        if (!ctx.mounted) return;
                        setState(() => sending = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Errore: $e')),
                        );
                      }
                    },
              child: sending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Invia magic link'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Eliminazione account GDPR ──────────────────────────────────────────────
  static Future<void> _showDeleteAccountDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD32F2F), size: 36),
        title: Text(l10n.profileCloseAccount),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _profileText(
                ctx,
                it: 'Stai richiedendo l\'eliminazione del tuo account PitLap.\n\nI tuoi dati personali verranno rimossi entro 30 giorni. Questa operazione non può essere annullata una volta confermata.',
                en: 'You are requesting the deletion of your PitLap account.\n\nYour personal data will be removed within 30 days. This action cannot be undone once confirmed.',
              ),
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3F3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFCDD2)),
              ),
              child: Text(
                _profileText(
                  ctx,
                  it: '⚠️ Accessi, dati di sessione e preferiti verranno eliminati definitivamente.',
                  en: '⚠️ Check-ins, session data and saved items will be permanently deleted.',
                ),
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFB71C1C),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.profileCancelEdit),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sì, elimina account'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final client = ref.read(authClientProvider);
      await client?.rpc('request_account_deletion');

      // Sign out immediately
      await client?.auth.signOut();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _profileText(
              context,
              it: 'Richiesta di eliminazione inviata. Verrai contattato entro 30 giorni.',
              en: 'Deletion request submitted. You will be notified within 30 days.',
            ),
          ),
          duration: const Duration(seconds: 5),
        ),
      );
      context.go('/');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: $e')),
      );
    }
  }

  static void _openCollectionSheet({
    required BuildContext context,
    required String title,
    required List<_CollectionEntry> entries,
    required String emptyMessage,
  }) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: 420,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(sheetContext).textTheme.titleLarge),
                const SizedBox(height: 16),
                if (entries.isEmpty)
                  Text(
                    emptyMessage,
                    style: Theme.of(sheetContext).textTheme.bodyLarge?.copyWith(
                      color: AppColors.steel,
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: entries.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: entry.onTap == null
                              ? null
                              : () {
                                  Navigator.of(sheetContext).pop();
                                  entry.onTap!.call();
                                },
                          child: Ink(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F7F3),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.concrete),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.title,
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                      if (entry.subtitle != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          entry.subtitle!,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: AppColors.steel,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (entry.trailing != null) ...[
                                  const SizedBox(width: 12),
                                  Text(
                                    entry.trailing!,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.steel,
                                    ),
                                  ),
                                ],
                                if (entry.onTap != null) ...[
                                  const SizedBox(width: 12),
                                  const Icon(Icons.chevron_right, color: AppColors.steel),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _roleLabel(AppLocalizations l10n, String role) {
    switch (role) {
      case 'shop_owner':
        return l10n.loginAccountTypeShopOwner;
      case 'track_organizer':
        return l10n.loginAccountTypeTrackOrganizer;
      case 'admin':
        return l10n.adminRoleAdmin;
      default:
        return l10n.loginAccountTypeUser;
    }
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.child,
  });

  final String eyebrow;
  final String title;
  final String body;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final resolvedEyebrow = _cleanProfileEyebrow(eyebrow);
    final resolvedBody = _cleanProfileSectionBody(context, body);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              resolvedEyebrow,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: AppColors.signalOrange),
            ),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              resolvedBody,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

String _cleanProfileEyebrow(String value) {
  if (value.contains('View d')) {
    return 'Panoramica';
  }
  if (value.contains('Identita')) {
    return 'Identita\'';
  }
  if (value.contains('Collegamenti')) {
    return 'Collegamenti';
  }
  if (value.contains('Presenza')) {
    return 'Presenza';
  }
  if (value.contains('Privacy')) {
    return 'Privacy';
  }
  if (value.contains('Impostazioni')) {
    return 'Impostazioni';
  }
  return value;
}

String _cleanProfileSectionBody(BuildContext context, String value) {
  if (value.contains('nei test') || value.contains('current tests')) {
    return _profileText(
      context,
      it: 'Accessi rapidi alle aree principali del tuo account.',
      en: 'Quick access to the main areas of your account.',
    );
  }
  return value;
}

String _profileText(
  BuildContext context, {
  required String it,
  required String en,
}) {
  return Localizations.localeOf(context).languageCode == 'it' ? it : en;
}

class _OverviewTileData {
  const _OverviewTileData({
    required this.emoji,
    required this.label,
    required this.value,
    required this.helper,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final String value;
  final String helper;
  final VoidCallback onTap;
}

class _OverviewTile extends StatelessWidget {
  const _OverviewTile({required this.data});

  final _OverviewTileData data;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: data.onTap,
      child: Ink(
        width: 220,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F7F3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.concrete),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text(
              data.label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppColors.steel),
            ),
            const SizedBox(height: 6),
            Text(
              data.value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.graphite,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              data.helper,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.steel),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickLinkCard extends StatelessWidget {
  const _QuickLinkCard({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji),
          const SizedBox(width: 10),
          Text(label),
        ],
      ),
    );
  }
}

class _ProfileBasicsEditor extends ConsumerStatefulWidget {
  const _ProfileBasicsEditor({
    required this.targetUserId,
    required this.canEdit,
    required this.emailValue,
    required this.profileAsync,
  });

  final String? targetUserId;
  final bool canEdit;
  final String emailValue;
  final AsyncValue<UserProfileRecord?> profileAsync;

  @override
  ConsumerState<_ProfileBasicsEditor> createState() => _ProfileBasicsEditorState();
}

class _ProfileBasicsEditorState extends ConsumerState<_ProfileBasicsEditor> {
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _avatarUrlController = TextEditingController();
  String _languageCode = 'it';
  String? _syncedProfileSignature;
  bool _editing = false;
  bool _saving = false;
  bool _uploadingAvatar = false;
  MediaUploadBatchState? _avatarTransferState;

  @override
  void dispose() {
    _displayNameController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userId = widget.targetUserId;

    widget.profileAsync.whenData((profile) {
      final signature = [
        userId ?? '',
        profile?.displayName ?? '',
        profile?.preferredLanguage ?? '',
        profile?.avatarUrl ?? '',
      ].join('|');
      if (_syncedProfileSignature == signature) {
        return;
      }
      _syncedProfileSignature = signature;
      _displayNameController.text = profile?.displayName ?? '';
      _avatarUrlController.text = profile?.avatarUrl ?? '';
      _languageCode = profile?.preferredLanguage ?? Localizations.localeOf(context).languageCode;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Spacer(),
            if (_editing)
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ElevatedButton.icon(
                    onPressed: !widget.canEdit || _saving ? null : () => _save(context),
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(l10n.profileSaveBasics),
                  ),
                  OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () {
                            _syncedProfileSignature = null;
                            setState(() {
                              _editing = false;
                            });
                          },
                    child: Text(l10n.profileCancelEdit),
                  ),
                ],
              )
            else
              OutlinedButton.icon(
                onPressed: !widget.canEdit
                    ? null
                    : () {
                        setState(() {
                          _editing = true;
                        });
                      },
                icon: const Icon(Icons.edit_outlined),
                label: Text(l10n.profileEditBasics),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AvatarPreview(
              imageUrl: _avatarUrlController.text.trim().isEmpty
                  ? null
                  : _avatarUrlController.text.trim(),
              fallbackLabel: _displayNameController.text.trim().isEmpty
                  ? widget.emailValue
                  : _displayNameController.text.trim(),
              size: 76,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _avatarUrlController,
                    enabled: _editing && widget.canEdit,
                    decoration: InputDecoration(
                      labelText: l10n.profilePhotoUrl,
                      hintText: l10n.profilePhotoUrlHint,
                    ),
                    onChanged: (_) {
                      if (_editing) {
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: !_editing || !widget.canEdit || _uploadingAvatar
                        ? null
                        : () => _pickAvatar(context),
                    icon: const Icon(Icons.upload_file_outlined),
                    label: Text(
                      _profileText(
                        context,
                        it: 'Carica da dispositivo',
                        en: 'Upload from device',
                      ),
                    ),
                  ),
                  if (_uploadingAvatar) ...[
                    const SizedBox(height: 12),
                    ImageTransferProgressCard(
                      label: _profileText(
                        context,
                        it: 'Preparazione foto profilo',
                        en: 'Preparing profile photo',
                      ),
                      batchState: _avatarTransferState,
                      icon: Icons.account_circle_outlined,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _profileText(
            context,
            it: 'Puoi usare un link immagine oppure caricare una foto direttamente dal tuo dispositivo.',
            en: 'You can use an image link or upload a photo directly from your device.',
          ),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.steel),
        ),
        if (!widget.canEdit) ...[
          const SizedBox(height: 12),
          Text(
            _profileText(
              context,
              it:
                  'In vista impersonata puoi consultare il profilo, ma le modifiche restano bloccate per evitare aggiornamenti involontari sull\'account reale.',
              en:
                  'In impersonated view you can inspect the profile, but edits stay blocked to avoid accidental changes on the real account.',
            ),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.steel),
          ),
        ],
        const SizedBox(height: 16),
        TextField(
          controller: _displayNameController,
          enabled: _editing && widget.canEdit,
          decoration: InputDecoration(labelText: l10n.profileVisibleName),
          onChanged: (_) {
            if (_editing) {
              setState(() {});
            }
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _languageCode,
          key: ValueKey('profile-language-$_languageCode-$_editing'),
          decoration: InputDecoration(labelText: l10n.profilePreferredLanguage),
          items: const [
            DropdownMenuItem(value: 'it', child: Text('Italiano')),
            DropdownMenuItem(value: 'en', child: Text('English')),
          ],
          onChanged: !_editing || !widget.canEdit
              ? null
              : (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _languageCode = value;
                  });
                },
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _FieldPreview(label: l10n.profileCurrentEmail, value: widget.emailValue),
            _FieldPreview(
              label: l10n.profileAccountStatus,
              value: widget.targetUserId != null
                  ? l10n.profileAccountStatusActive
                  : l10n.profileAccountStatusGuest,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _profileText(
            context,
            it: 'Puoi aggiornare nome visibile, foto profilo e lingua del tuo account.',
            en: 'You can update display name, profile photo, and language for your account.',
          ),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
        ),
      ],
    );
  }

  Future<void> _pickAvatar(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final preparingAvatarLabel = _profileText(
      context,
      it: 'Sto preparando la foto profilo',
      en: 'Preparing profile photo',
    );
    final genericUploadErrorMessage = _profileText(
      context,
      it: 'Errore imprevisto durante il caricamento.',
      en: 'Unexpected error during upload.',
    );
    setState(() {
      _uploadingAvatar = true;
      _avatarTransferState = null;
    });

    try {
      final userId = widget.targetUserId;
      final uploadService = ref.read(mediaUploadServiceProvider);

      if (userId == null || uploadService == null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              _profileText(
                context,
                it: 'Devi essere autenticato per caricare immagini.',
                en: 'You must be signed in to upload images.',
              ),
            ),
          ),
        );
        return;
      }

      final picked = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (picked == null || picked.files.isEmpty) {
        return;
      }
      final bytes = picked.files.first.bytes;
      if (bytes == null) {
        return;
      }

      final uploadController = MediaUploadController(
        totalItems: 1,
        initialStageLabel: preparingAvatarLabel,
      );
      setState(() {
        _avatarTransferState = uploadController.snapshot;
      });

      try {
        final result = await uploadService.uploadImage(
          bytes: bytes,
          userId: userId,
          entityType: 'profiles',
          filePrefix: 'avatar',
          onProgress: (stage, progress) {
            if (!mounted) return;
            uploadController.setStageLabel(mediaUploadStageLabel(context, stage));
            uploadController.updateItem(index: 0, stage: stage, progress: progress);
            setState(() {
              _avatarTransferState = uploadController.snapshot;
            });
          },
        );
        if (!mounted) return;
        uploadController.markDone(0);
        setState(() {
          _avatarTransferState = uploadController.snapshot;
          _avatarUrlController.text = result.publicUrl;
        });
      } on MediaUploadException catch (e) {
        if (!mounted) return;
        uploadController.markError(0);
        setState(() {
          _avatarTransferState = uploadController.snapshot;
        });
        messenger.showSnackBar(SnackBar(content: Text(e.message)));
      } catch (e) {
        if (!mounted) return;
        uploadController.markError(0);
        setState(() {
          _avatarTransferState = uploadController.snapshot;
        });
        messenger.showSnackBar(
          SnackBar(
            content: Text(genericUploadErrorMessage),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploadingAvatar = false;
          _avatarTransferState = null;
        });
      }
    }
  }

  Future<void> _save(BuildContext context) async {
    final repository = ref.read(authProfileRepositoryProvider);
    final userId = widget.targetUserId;
    if (repository == null || userId == null || !widget.canEdit) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _saving = true;
    });

    try {
      debugPrint(
        '[ProfileFlow] Saving basics user=$userId displayName="${_displayNameController.text.trim()}" language=$_languageCode',
      );
      await repository.upsertProfileBasics(
        userId: userId,
        displayName: _displayNameController.text.trim(),
        languageCode: _languageCode,
        avatarUrl: _avatarUrlController.text.trim().isEmpty ? null : _avatarUrlController.text.trim(),
      );
      ref.read(localeProvider.notifier).setLocale(Locale(_languageCode));
      ref.invalidate(effectiveUserProfileProvider);
      ref.invalidate(preferredLanguageProfileProvider);
      _syncedProfileSignature = null;
      if (!mounted) {
        return;
      }
      setState(() {
        _editing = false;
      });
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.profileSavedMessage)),
      );
    } catch (error) {
      debugPrint('[ProfileFlow] Unable to save basics for user=$userId: $error');
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }
}

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({
    required this.imageUrl,
    required this.fallbackLabel,
    required this.size,
  });

  final String? imageUrl;
  final String fallbackLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = imageUrl?.trim();
    final initials = fallbackLabel.trim().isEmpty
        ? 'TH'
        : fallbackLabel
              .trim()
              .split(RegExp(r'\s+'))
              .where((part) => part.isNotEmpty)
              .take(2)
              .map((part) => part.substring(0, 1).toUpperCase())
              .join();

    return ClipOval(
      child: Container(
        width: size,
        height: size,
        color: const Color(0xFFF3F4F6),
        child: resolvedUrl == null || resolvedUrl.isEmpty
            ? _AvatarFallback(initials: initials)
            : AdaptiveImage(
                source: resolvedUrl,
                fit: BoxFit.cover,
                fallback: _AvatarFallback(initials: initials),
              ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: AppColors.graphite,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FieldPreview extends StatelessWidget {
  const _FieldPreview({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Ink(
      width: 210,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7F3),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.concrete),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: AppColors.steel),
          ),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.label,
    required this.icon,
    this.onTap,
    this.danger = false,
    this.helper,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool danger;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.closedRed : AppColors.graphite;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F7F3),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.concrete),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
                  ),
                  if (helper != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      helper!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              onTap == null ? Icons.block : Icons.chevron_right,
              color: AppColors.steel,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Profilo pubblico ──────────────────────────────────────────────────────────

class _PublicProfileSettings extends ConsumerStatefulWidget {
  const _PublicProfileSettings();

  @override
  ConsumerState<_PublicProfileSettings> createState() => _PublicProfileSettingsState();
}

class _PublicProfileSettingsState extends ConsumerState<_PublicProfileSettings> {
  late TextEditingController _slugController;
  bool? _pendingIsPublic;
  bool _saving = false;
  String? _slugError;

  static final _slugRegex = RegExp(r'^[a-z0-9][a-z0-9\-]{2,29}$');

  @override
  void initState() {
    super.initState();
    _slugController = TextEditingController();
  }

  @override
  void dispose() {
    _slugController.dispose();
    super.dispose();
  }

  Future<void> _save(String userId, bool isPublic, String? currentSlug) async {
    final slug = _slugController.text.trim();
    if (isPublic && slug.isEmpty) {
      setState(() => _slugError = 'Inserisci uno slug per attivare il profilo pubblico.');
      return;
    }
    if (slug.isNotEmpty && !_slugRegex.hasMatch(slug)) {
      setState(() => _slugError = 'Usa solo lettere minuscole, numeri e trattini (min 3, max 30 caratteri).');
      return;
    }
    setState(() { _saving = true; _slugError = null; });
    try {
      final repository = ref.read(authProfileRepositoryProvider);
      if (repository == null) return;
      await repository.updatePublicProfileSettings(
        userId: userId,
        isPublic: isPublic,
        publicSlug: slug.isEmpty ? currentSlug : slug,
      );
      ref.invalidate(effectiveUserProfileProvider);
      if (mounted) {
        setState(() => _pendingIsPublic = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impostazioni profilo pubblico aggiornate.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nel salvataggio: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(effectiveUserProfileProvider);
    final targetUserId = ref.watch(effectiveUserIdProvider);
    final canEdit = !ref.watch(isImpersonatingProvider) && ref.watch(currentUserProvider) != null;

    return profileAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
      data: (profile) {
        final isPublic = _pendingIsPublic ?? (profile?.isPublic ?? false);
        final currentSlug = profile?.publicSlug;

        if (_slugController.text.isEmpty && currentSlug != null) {
          _slugController.text = currentSlug;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Profilo pubblico'),
              subtitle: Text(
                isPublic
                    ? 'Visibile a chiunque tramite link'
                    : 'Visibile solo a te (privato)',
                style: TextStyle(color: AppColors.steel),
              ),
              value: isPublic,
              onChanged: !canEdit
                  ? null
                  : (val) => setState(() => _pendingIsPublic = val),
            ),
            if (isPublic) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _slugController,
                decoration: InputDecoration(
                  labelText: 'Slug profilo',
                  hintText: 'es. mario-rossi-rc',
                  helperText: 'URL: pitlap.app/u/${_slugController.text.isNotEmpty ? _slugController.text : "tuo-slug"}',
                  errorText: _slugError,
                  prefixIcon: const Icon(Icons.link_outlined),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() => _slugError = null),
              ),
              const SizedBox(height: 12),
            ],
            if (_pendingIsPublic != null || (currentSlug?.isEmpty ?? true)) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton(
                  onPressed: _saving || !canEdit || targetUserId == null
                      ? null
                      : () => _save(targetUserId, isPublic, currentSlug),
                  child: _saving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Salva'),
                ),
              ),
            ],
            if (currentSlug != null && currentSlug.isNotEmpty && isPublic) ...[
              const SizedBox(height: 8),
              Text(
                'pitlap.app/u/$currentSlug',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.steel,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}


class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white),
      ),
    );
  }
}

class _CollectionEntry {
  const _CollectionEntry({
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final String? trailing;
  final VoidCallback? onTap;
}

class _ConsentSummary extends StatelessWidget {
  const _ConsentSummary({required this.consentsAsync});

  final AsyncValue<List<UserConsentRecord>> consentsAsync;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7F3),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.concrete),
      ),
      child: consentsAsync.when(
        data: (consents) {
          UserConsentRecord? findConsent(String type) {
            for (final item in consents) {
              if (item.consentType == type) {
                return item;
              }
            }
            return null;
          }

          final terms = findConsent('terms_accepted');
          final privacy = findConsent('privacy_notice_seen');
          final marketing = findConsent('marketing_email_opt_in');
          final lastUpdated = [
            terms?.updatedAt,
            privacy?.updatedAt,
            marketing?.updatedAt,
          ].whereType<DateTime>().fold<DateTime?>(null, (latest, value) {
            if (latest == null || value.isAfter(latest)) {
              return value;
            }
            return latest;
          });
          final version = terms?.documentVersion ?? privacy?.documentVersion ?? legalDocumentVersion;
          final source = terms?.source ?? privacy?.source ?? marketing?.source;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.profileConsentTitle, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _FieldPreview(
                    label: l10n.profileConsentTerms,
                    value: _consentValue(l10n, terms?.accepted == true),
                  ),
                  _FieldPreview(
                    label: l10n.profileConsentPrivacy,
                    value: _consentValue(l10n, privacy?.accepted == true),
                  ),
                  _FieldPreview(
                    label: l10n.profileConsentMarketing,
                    value: _consentValue(l10n, marketing?.accepted == true),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                l10n.profileConsentVersion(version),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
              ),
              if (lastUpdated != null) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.profileConsentUpdatedAt(_formatConsentDate(context, lastUpdated)),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
                ),
              ],
              if (source != null && source.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.profileConsentSource(source),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
                ),
              ],
            ],
          );
        },
        loading: () => Text(
          l10n.profileConsentLoading,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
        ),
        error: (_, _) => Text(
          l10n.profileConsentUnavailable,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.steel),
        ),
      ),
    );
  }

  static String _consentValue(AppLocalizations l10n, bool accepted) {
    return accepted ? l10n.profileConsentAccepted : l10n.profileConsentNotAccepted;
  }

  static String _formatConsentDate(BuildContext context, DateTime value) {
    final local = value.toLocal();
    final date = MaterialLocalizations.of(context).formatShortDate(local);
    final time = TimeOfDay.fromDateTime(local).format(context);
    return '$date · $time';
  }
}
