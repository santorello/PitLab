import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_providers.dart';
import 'package:pitlap_app/app/l10n/tr.dart';

/// Apre il dialog di feedback. Disponibile a chiunque (anche guest).
Future<void> showFeedbackDialog(BuildContext context) {
  final page = GoRouterState.of(context).uri.toString();
  return showDialog<void>(
    context: context,
    builder: (_) => FeedbackDialog(page: page),
  );
}

class FeedbackDialog extends ConsumerStatefulWidget {
  const FeedbackDialog({required this.page, super.key});

  final String page;

  @override
  ConsumerState<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends ConsumerState<FeedbackDialog> {
  final _messageController = TextEditingController();
  final _emailController = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // Precompila l'email se l'utente è loggato.
    final email = ref.read(currentUserProvider)?.email;
    if (email != null) {
      _emailController.text = email;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final client = ref.read(authClientProvider);
    final message = _messageController.text.trim();
    if (message.isEmpty || client == null) {
      return;
    }
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final email = _emailController.text.trim();
      // Edge Function: salva il feedback e invia l'email di avviso al titolare.
      await client.functions.invoke('submit-feedback', body: {
        'message': message,
        'contactEmail': email.isEmpty ? null : email,
        'userId': ref.read(currentUserProvider)?.id,
        'page': widget.page,
      });
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text(tr('Grazie per il feedback!'))),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(trf('Invio non riuscito: {0}', [error]))),
      );
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(tr('Invia feedback')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('Raccontaci cosa ne pensi o segnala un problema.')),
          const SizedBox(height: 16),
          TextField(
            controller: _messageController,
            maxLines: 4,
            autofocus: true,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: tr('Il tuo messaggio'),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: tr('Email (opzionale, se vuoi risposta)'),
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.of(context).pop(),
          child: Text(tr('Annulla')),
        ),
        FilledButton(
          onPressed: _sending ? null : _send,
          child: Text(_sending ? 'Invio…' : tr('Invia')),
        ),
      ],
    );
  }
}
