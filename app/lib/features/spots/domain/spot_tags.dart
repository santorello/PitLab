import 'package:flutter/material.dart';

/// Scelte guidate degli spot. Le chiavi sono vincolate da CHECK in DB
/// (delta 2026-09-16-spot-tags.sql): aggiungere una voce = aggiornare anche il vincolo.
class SpotTag {
  const SpotTag(this.key, this.it, this.en, this.icon);
  final String key;
  final String it;
  final String en;
  final IconData icon;

  String label(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'en' ? en : it;
}

const spotBestForTags = [
  SpotTag('scaler', 'Scaler / Trail', 'Scaler / Trail', Icons.forest_outlined),
  SpotTag('crawler', 'Crawler (roccia)', 'Rock crawler', Icons.landscape_outlined),
  SpotTag('bashing', 'Bashing / Salti', 'Bashing / Jumps', Icons.flight_takeoff_outlined),
  SpotTag('buggy', 'Buggy e Truggy', 'Buggy & Truggy', Icons.sports_motorsports_outlined),
  SpotTag('drift', 'Drift', 'Drift', Icons.rotate_right),
  SpotTag('onroad', 'On-road / Pista', 'On-road / Track', Icons.flag_outlined),
  SpotTag('mini', 'Mini e Micro (1:24 e più piccoli)', 'Mini & Micro (1:24 and smaller)', Icons.toys_outlined),
  SpotTag('fpv_drone', 'Drone FPV', 'FPV drone', Icons.videocam_outlined),
  SpotTag('rc_plane', 'Aerei e alianti RC', 'RC planes & gliders', Icons.airplanemode_active_outlined),
  SpotTag('rc_boat', 'Barche RC', 'RC boats', Icons.directions_boat_outlined),
  SpotTag('rc_tank', 'Carri armati RC', 'RC tanks', Icons.shield_outlined),
  SpotTag('family', 'Famiglie / Principianti', 'Families / Beginners', Icons.family_restroom_outlined),
];

const spotSurfaceTags = [
  SpotTag('dirt', 'Sterrato', 'Dirt', Icons.terrain_outlined),
  SpotTag('rock', 'Roccia', 'Rock', Icons.landscape_outlined),
  SpotTag('grass', 'Erba', 'Grass', Icons.grass_outlined),
  SpotTag('sand', 'Sabbia', 'Sand', Icons.beach_access_outlined),
  SpotTag('mud', 'Fango', 'Mud', Icons.water_drop_outlined),
  SpotTag('gravel', 'Ghiaia', 'Gravel', Icons.blur_on_outlined),
  SpotTag('asphalt', 'Asfalto', 'Asphalt', Icons.add_road_outlined),
  SpotTag('concrete', 'Cemento / Parcheggio', 'Concrete / Car park', Icons.local_parking_outlined),
  SpotTag('water', 'Acqua (laghetto)', 'Water (pond)', Icons.waves_outlined),
  SpotTag('indoor', 'Indoor', 'Indoor', Icons.home_work_outlined),
  SpotTag('mixed', 'Misto', 'Mixed', Icons.layers_outlined),
];

const spotAccessTags = [
  SpotTag('free', 'Accesso libero', 'Free access', Icons.lock_open_outlined),
  SpotTag('permission', 'Su permesso', 'Permission needed', Icons.how_to_reg_outlined),
  SpotTag('private', 'Privato', 'Private', Icons.lock_outline),
];

const spotSeasonTags = [
  SpotTag('all_year', 'Tutto l\'anno', 'All year', Icons.event_available_outlined),
  SpotTag('avoid_after_rain', 'Evitare dopo la pioggia', 'Avoid after rain', Icons.umbrella_outlined),
  SpotTag('summer', 'Meglio d\'estate', 'Best in summer', Icons.wb_sunny_outlined),
];

/// Voci con regole di volo (ENAC / d-flight).
const spotFlyingKeys = {'fpv_drone', 'rc_plane'};

List<SpotTag> spotTagsFor(List<SpotTag> all, Iterable<String> keys) =>
    all.where((t) => keys.contains(t.key)).toList();

SpotTag? spotTagFor(List<SpotTag> all, String? key) =>
    key == null ? null : all.where((t) => t.key == key).firstOrNull;

/// Chip selezionabili. [multi] = più voci; altrimenti una sola, ri-toccarla la deseleziona.
class SpotTagPicker extends StatelessWidget {
  const SpotTagPicker({
    super.key,
    required this.title,
    required this.tags,
    required this.selected,
    required this.onChanged,
    this.multi = true,
  });

  final String title;
  final List<SpotTag> tags;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  final bool multi;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in tags)
              FilterChip(
                avatar: Icon(tag.icon, size: 18),
                label: Text(tag.label(context)),
                selected: selected.contains(tag.key),
                onSelected: (on) {
                  final next = multi ? {...selected} : <String>{};
                  if (on) {
                    next.add(tag.key);
                  } else {
                    next.remove(tag.key);
                  }
                  onChanged(next);
                },
              ),
          ],
        ),
      ],
    );
  }
}
