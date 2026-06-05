import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../incidents/data/incident_model.dart';
import '../../../incidents/logic/incidents_cubit.dart';
import '../../../incidents/logic/incidents_state.dart';
import 'home_shared_widgets.dart';
import 'incident_bottom_sheet.dart';

enum _LocationStatus { initial, loading, ready, denied, serviceDisabled, error }

class HomeMapView extends StatefulWidget {
  const HomeMapView({super.key});

  @override
  State<HomeMapView> createState() => _HomeMapViewState();
}

class _HomeMapViewState extends State<HomeMapView> {
  static const _cuencaCenter = LatLng(-2.90055, -79.00453);

  final MapController _mapController = MapController();
  _LocationStatus _locationStatus = _LocationStatus.initial;
  String? _locationMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerOnUserLocation(silent: true);
    });
  }

  Future<void> _centerOnUserLocation({bool silent = false}) async {
    setState(() {
      _locationStatus = _LocationStatus.loading;
      _locationMessage = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationStatus = _LocationStatus.serviceDisabled;
          _locationMessage =
              'Activa la ubicacion del dispositivo para centrar el mapa.';
        });
        if (!silent) _showMessage(_locationMessage!);
        return;
      }

      var permission = await Permission.locationWhenInUse.status;
      if (permission.isDenied) {
        permission = await Permission.locationWhenInUse.request();
      }

      if (permission.isPermanentlyDenied) {
        setState(() {
          _locationStatus = _LocationStatus.denied;
          _locationMessage =
              'La ubicacion esta bloqueada. Puedes habilitarla en ajustes.';
        });
        if (!silent) _showLocationSettingsMessage();
        return;
      }

      if (!permission.isGranted) {
        setState(() {
          _locationStatus = _LocationStatus.denied;
          _locationMessage =
              'No tenemos permiso para mostrar tu ubicacion actual.';
        });
        if (!silent) _showMessage(_locationMessage!);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final point = LatLng(position.latitude, position.longitude);

      setState(() {
        _locationStatus = _LocationStatus.ready;
      });
      _mapController.move(point, 15);
      if (mounted) {
        await context.read<IncidentsCubit>().loadNearbyPreferredIncidents(
          latitud: position.latitude,
          longitud: position.longitude,
          notifyNearby: !silent,
        );
      }
    } catch (_) {
      setState(() {
        _locationStatus = _LocationStatus.error;
        _locationMessage = 'No se pudo obtener tu ubicacion actual.';
      });
      if (!silent) _showMessage(_locationMessage!);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showLocationSettingsMessage() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Habilita la ubicacion en ajustes para continuar.'),
        action: SnackBarAction(
          label: 'Ajustes',
          textColor: AppColors.gold,
          onPressed: openAppSettings,
        ),
      ),
    );
  }

  void _showIncident(IncidentModel incident) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: false,
      isScrollControlled: true,
      builder: (_) => IncidentBottomSheet(incident: incident),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<IncidentsCubit, IncidentsState>(
      listenWhen: (previous, current) =>
          previous.nearbyMessage != current.nearbyMessage,
      listener: (context, state) {
        final message = state.nearbyMessage;
        if (message != null && message.isNotEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      },
      builder: (context, state) {
        final incidentsWithLocation = state.incidents
            .where((incident) => incident.latitud != null)
            .where((incident) => incident.longitud != null)
            .toList();

        return Stack(
          fit: StackFit.expand,
          children: [
            FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialCenter: _cuencaCenter,
                initialZoom: 13,
                minZoom: 11,
                maxZoom: 18,
                backgroundColor: AppColors.background,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.cuenca_activa_app',
                ),
                if (_locationStatus == _LocationStatus.ready)
                  CurrentLocationLayer(
                    style: const LocationMarkerStyle(
                      marker: DefaultLocationMarker(
                        color: AppColors.teal,
                        child: Icon(
                          Icons.navigation_rounded,
                          color: AppColors.white,
                          size: 13,
                        ),
                      ),
                      markerSize: Size.square(28),
                      accuracyCircleColor: Color(0x261FA99A),
                      headingSectorColor: Color(0x661FA99A),
                    ),
                  ),
                MarkerLayer(
                  markers: incidentsWithLocation
                      .map(
                        (incident) => Marker(
                          point: LatLng(incident.latitud!, incident.longitud!),
                          width: 58,
                          height: 68,
                          alignment: Alignment.topCenter,
                          child: _IncidentMarker(
                            incident: incident,
                            onTap: () => _showIncident(incident),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            Positioned(
              top: 14,
              left: 16,
              right: 16,
              child: _MapSummaryCard(
                loading: state.loading,
                nearbyLoading: state.nearbyLoading,
                errorMessage: state.errorMessage,
                totalIncidents: state.incidents.length,
                mappedIncidents: incidentsWithLocation.length,
                locationMessage: _locationMessage,
                onRetry: context.read<IncidentsCubit>().loadInitialData,
              ),
            ),
            Positioned(
              right: 16,
              bottom: 92,
              child: Column(
                children: [
                  _MapActionButton(
                    tooltip: 'Centrar en mi ubicacion',
                    icon:
                        _locationStatus == _LocationStatus.loading ||
                            state.nearbyLoading
                        ? null
                        : Icons.my_location_rounded,
                    onPressed:
                        _locationStatus == _LocationStatus.loading ||
                            state.nearbyLoading
                        ? null
                        : () => _centerOnUserLocation(),
                    child:
                        _locationStatus == _LocationStatus.loading ||
                            state.nearbyLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                  ),
                  const SizedBox(height: 10),
                  _MapActionButton(
                    tooltip: 'Reportar incidencia',
                    icon: Icons.add_location_alt_rounded,
                    color: AppColors.gold,
                    foregroundColor: AppColors.navy,
                    onPressed: () => context.go('/report-incident'),
                  ),
                ],
              ),
            ),
            if (!state.loading &&
                state.errorMessage == null &&
                incidentsWithLocation.isEmpty)
              Positioned(
                left: 20,
                right: 20,
                bottom: 92,
                child: SizedBox(
                  height: 132,
                  child: _MapEmptyCard(
                    hasIncidentsWithoutLocation: state.incidents.isNotEmpty,
                    onCreate: () => context.go('/report-incident'),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _IncidentMarker extends StatelessWidget {
  final IncidentModel incident;
  final VoidCallback onTap;

  const _IncidentMarker({required this.incident, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: IncidentCategoryIcon(
                category: incident.nombreCategoria,
                size: 34,
              ),
            ),
          ),
          Container(
            width: 12,
            height: 12,
            transform: Matrix4.translationValues(0, -3, 0)..rotateZ(0.785398),
            decoration: const BoxDecoration(color: AppColors.white),
          ),
        ],
      ),
    );
  }
}

class _MapSummaryCard extends StatelessWidget {
  final bool loading;
  final bool nearbyLoading;
  final String? errorMessage;
  final int totalIncidents;
  final int mappedIncidents;
  final String? locationMessage;
  final VoidCallback onRetry;

  const _MapSummaryCard({
    required this.loading,
    required this.nearbyLoading,
    required this.errorMessage,
    required this.totalIncidents,
    required this.mappedIncidents,
    required this.locationMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final message =
        errorMessage ??
        locationMessage ??
        '$mappedIncidents reportes dentro de tu radio preferido';
    final isLoading = loading || nearbyLoading;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.lightGray),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.1),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      errorMessage == null
                          ? Icons.map_outlined
                          : Icons.cloud_off_rounded,
                      color: errorMessage == null
                          ? AppColors.teal
                          : AppColors.danger,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mapa ciudadano',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    totalIncidents == 0 && errorMessage == null && !isLoading
                        ? 'No hay reportes dentro de tu radio por ahora.'
                        : message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (errorMessage != null)
              IconButton(
                tooltip: 'Reintentar',
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
              ),
          ],
        ),
      ),
    );
  }
}

class _MapActionButton extends StatelessWidget {
  final String tooltip;
  final IconData? icon;
  final Widget? child;
  final Color color;
  final Color foregroundColor;
  final VoidCallback? onPressed;

  const _MapActionButton({
    required this.tooltip,
    required this.icon,
    this.child,
    this.color = AppColors.white,
    this.foregroundColor = AppColors.teal,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(18),
      elevation: 4,
      shadowColor: AppColors.navy.withValues(alpha: 0.18),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        color: foregroundColor,
        icon: child ?? Icon(icon),
      ),
    );
  }
}

class _MapEmptyCard extends StatelessWidget {
  final bool hasIncidentsWithoutLocation;
  final VoidCallback onCreate;

  const _MapEmptyCard({
    required this.hasIncidentsWithoutLocation,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.location_searching_rounded,
                color: AppColors.teal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasIncidentsWithoutLocation
                    ? 'Hay reportes sin coordenadas para mostrar en mapa.'
                    : 'Aun no hay reportes visibles cerca de Cuenca.',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 104,
              height: 46,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(104, 46),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onPressed: onCreate,
                child: const Text('Reportar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
