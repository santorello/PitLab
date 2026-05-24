import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../app/bootstrap/app_config.dart';
import '../../app/theme/app_colors.dart';
import '../places/place_selection.dart';

class PlaceMapPreviewCard extends StatelessWidget {
  const PlaceMapPreviewCard({
    required this.selection,
    this.height = 180,
    super.key,
  });

  final PlaceSelection selection;
  final double height;

  static String get _tileUrlTemplate =>
      'https://api.maptiler.com/maps/streets-v2/256/{z}/{x}/{y}.png?key=${AppConfig.mapTilerApiKey}';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.concrete),
        color: const Color(0xFFF8F7F3),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: height,
            child: AppConfig.hasMapTilerConfig
                ? FlutterMap(
                    options: MapOptions(
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                      initialCenter: LatLng(
                        selection.latitude,
                        selection.longitude,
                      ),
                      initialZoom: 11,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: _tileUrlTemplate,
                        userAgentPackageName: 'pitlap_app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(selection.latitude, selection.longitude),
                            width: 44,
                            height: 44,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.signalOrange,
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x26000000),
                                    blurRadius: 14,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.place,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Mappa pronta, ma manca la API key MapTiler in questa build.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.steel,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.place_outlined,
                  color: AppColors.signalOrange,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selection.label,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if ((selection.subtitle ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          selection.subtitle!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
        ],
      ),
    );
  }
}
