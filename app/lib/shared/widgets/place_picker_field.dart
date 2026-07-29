import 'dart:async';

import 'package:pitlap_app/app/bootstrap/error_reporting.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../places/place_search_provider.dart';
import '../places/place_search_service.dart';
import '../places/place_selection.dart';

class PlacePickerField extends ConsumerStatefulWidget {
  const PlacePickerField({
    required this.controller,
    required this.onSelected,
    this.initialSelection,
    this.labelText = 'Localita',
    this.hintText,
    this.prefixIcon = const Icon(Icons.place_outlined),
    this.emptyInfoText,
    this.verifiedInfoBuilder,
    this.countryCode = 'IT',
    this.types = const <String>[],
    this.minQueryLength = 2,
    super.key,
  });

  final TextEditingController controller;
  final PlaceSelection? initialSelection;
  final ValueChanged<PlaceSelection?> onSelected;
  final String labelText;
  final String? hintText;
  final Widget prefixIcon;
  final String? emptyInfoText;
  final String Function(PlaceSelection selection)? verifiedInfoBuilder;
  final String countryCode;
  final List<String> types;
  final int minQueryLength;

  @override
  ConsumerState<PlacePickerField> createState() => _PlacePickerFieldState();
}

class _PlacePickerFieldState extends ConsumerState<PlacePickerField> {
  Timer? _debounce;
  List<PlaceSelection> _suggestions = const <PlaceSelection>[];
  PlaceSelection? _selected;
  bool _loading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelection;
    widget.controller.addListener(_handleTextChanged);
  }

  @override
  void didUpdateWidget(covariant PlacePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleTextChanged);
      widget.controller.addListener(_handleTextChanged);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.removeListener(_handleTextChanged);
    super.dispose();
  }

  void _handleTextChanged() {
    final query = widget.controller.text.trim();
    if (_selected != null && query != _selected!.label) {
      _selected = null;
      widget.onSelected(null);
    }

    _debounce?.cancel();
    if (query.length < widget.minQueryLength) {
      setState(() {
        _loading = false;
        _errorMessage = null;
        _suggestions = const <PlaceSelection>[];
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), _search);
  }

  Future<void> _search() async {
    final query = widget.controller.text.trim();
    if (query.length < widget.minQueryLength) {
      return;
    }
    final locale = Localizations.localeOf(context);
    final request = PlaceSearchRequest(
      query: query,
      language: locale.languageCode,
      countryCode: widget.countryCode,
      types: widget.types,
    );

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(placeSearchProvider);
      final results = await service.search(request);
      if (!mounted || widget.controller.text.trim() != query) {
        return;
      }
      setState(() {
        _loading = false;
        _suggestions = results;
      });
    } catch (e, st) {
      AppErrorReporter.report(e, st, context: 'place_picker_field');
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _suggestions = const <PlaceSelection>[];
        _errorMessage =
            'Ricerca luogo non disponibile in questo momento. Puoi comunque compilare manualmente.';
      });
    }
  }

  void _select(PlaceSelection selection) {
    _debounce?.cancel();
    _selected = selection;
    widget.onSelected(selection);
    widget.controller.value = TextEditingValue(
      text: selection.label,
      selection: TextSelection.collapsed(offset: selection.label.length),
    );
    setState(() {
      _loading = false;
      _errorMessage = null;
      _suggestions = const <PlaceSelection>[];
    });
  }

  @override
  Widget build(BuildContext context) {
    final showSuggestions =
        _selected == null &&
        widget.controller.text.trim().length >= widget.minQueryLength &&
        (_loading || _errorMessage != null || _suggestions.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            prefixIcon: widget.prefixIcon,
          ),
        ),
        if (showSuggestions) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.concrete),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Expanded(child: Text('Sto cercando il luogo corretto...')),
                      ],
                    ),
                  )
                : _errorMessage != null
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _errorMessage!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.steel,
                      ),
                    ),
                  )
                : Column(
                    children: _suggestions
                        .map(
                          (suggestion) => InkWell(
                            onTap: () => _select(suggestion),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Icon(
                                      Icons.location_on_outlined,
                                      size: 18,
                                      color: AppColors.steel,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          suggestion.label,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        if ((suggestion.subtitle ?? '')
                                            .trim()
                                            .isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            suggestion.subtitle!,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: AppColors.steel,
                                                ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
        if (widget.emptyInfoText != null || _selected != null) ...[
          const SizedBox(height: 12),
          Text(
            _selected == null
                ? widget.emptyInfoText ?? ''
                : widget.verifiedInfoBuilder?.call(_selected!) ??
                    'Luogo verificato: ${_selected!.label}.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.steel,
            ),
          ),
        ],
      ],
    );
  }
}
