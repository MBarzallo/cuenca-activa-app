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

class _HomeMapViewState extends State<HomeMapView> with WidgetsBindingObserver {
  static const _cuencaCenter = LatLng(-2.90055, -79.00453);

  final MapController _mapController = MapController();
  _LocationStatus _locationStatus = _LocationStatus.initial;
  String? _locationMessage;
  double _currentZoom = 13.0;
  bool _dismissedLocationWarning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerOnUserLocation(silent: true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _centerOnUserLocation(silent: true);
    }
  }

  Future<void> _centerOnUserLocation({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _dismissedLocationWarning = false;
      });
    }

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
        _dismissedLocationWarning = false;
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

  void _handleLocationWarningAction() {
    if (_locationStatus == _LocationStatus.serviceDisabled) {
      Geolocator.openLocationSettings();
    } else {
      openAppSettings();
    }
  }

  void _showIncident(IncidentModel incident) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: false,
      isScrollControlled: true,
      builder: (_) => IncidentBottomSheet(incident: incident),
    );
  }

  void _showClusterIncidents(List<IncidentModel> incidents) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      builder: (BuildContext sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: incidents.length > 3 ? 0.6 : 0.45,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.teal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.layers_rounded,
                          color: AppColors.teal,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Incidencias en este punto (${incidents.length})',
                        style: Theme.of(sheetContext)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: AppColors.navy,
                            ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: incidents.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final incident = incidents[index];
                      return _ClusterIncidentItem(
                        incident: incident,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _showIncident(incident);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<List<IncidentModel>> _groupNearbyIncidents(
    List<IncidentModel> incidents,
    double zoom,
  ) {
    final double maxDistance;
    if (zoom <= 12) {
      maxDistance = 100;
    } else if (zoom <= 14) {
      maxDistance = 60;
    } else if (zoom <= 16) {
      maxDistance = 30;
    } else {
      maxDistance = 10;
    }

    const distanceCalculator = Distance();
    final List<List<IncidentModel>> groups = [];

    for (final incident in incidents) {
      final lat = incident.latitud;
      final lng = incident.longitud;
      if (lat == null || lng == null) continue;

      final incidentLatLng = LatLng(lat, lng);
      bool addedToGroup = false;

      for (final group in groups) {
        final repIncident = group.first;
        final repLatLng = LatLng(repIncident.latitud!, repIncident.longitud!);
        
        final dist = distanceCalculator(incidentLatLng, repLatLng);
        if (dist < maxDistance) {
          group.add(incident);
          addedToGroup = true;
          break;
        }
      }

      if (!addedToGroup) {
        groups.add([incident]);
      }
    }

    return groups;
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

        final groups = _groupNearbyIncidents(incidentsWithLocation, _currentZoom);

        final markers = groups.map((list) {
          final first = list.first;
          final point = LatLng(first.latitud!, first.longitud!);

          if (list.length == 1) {
            return Marker(
              point: point,
              width: 58,
              height: 68,
              alignment: Alignment.topCenter,
              child: _IncidentMarker(
                incident: first,
                onTap: () => _showIncident(first),
              ),
            );
          } else {
            return Marker(
              point: point,
              width: 60,
              height: 70,
              alignment: Alignment.topCenter,
              child: _IncidentClusterMarker(
                count: list.length,
                onTap: () => _showClusterIncidents(list),
              ),
            );
          }
        }).toList();

        return Stack(
          fit: StackFit.expand,
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _cuencaCenter,
                initialZoom: 13,
                minZoom: 11,
                maxZoom: 18,
                backgroundColor: AppColors.background,
                onPositionChanged: (camera, hasGesture) {
                  if (camera.zoom != _currentZoom) {
                    setState(() {
                      _currentZoom = camera.zoom;
                    });
                  }
                },
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
                  markers: markers,
                ),
              ],
            ),
            Positioned(
              top: 14,
              left: 16,
              child: _MapStatusChip(
                loading: state.loading,
                nearbyLoading: state.nearbyLoading,
                errorMessage: state.errorMessage,
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
                ],
              ),
            ),
            if ((_locationStatus == _LocationStatus.denied ||
                    _locationStatus == _LocationStatus.serviceDisabled) &&
                !_dismissedLocationWarning)
              Positioned(
                left: 20,
                right: 20,
                bottom: 92,
                child: _LocationWarningCard(
                  status: _locationStatus,
                  onActionPressed: _handleLocationWarningAction,
                  onDismiss: () => setState(() => _dismissedLocationWarning = true),
                ),
              )
            else if (!state.loading &&
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

class _MapStatusChip extends StatelessWidget {
  final bool loading;
  final bool nearbyLoading;
  final String? errorMessage;
  final String? locationMessage;
  final VoidCallback onRetry;

  const _MapStatusChip({
    required this.loading,
    required this.nearbyLoading,
    required this.errorMessage,
    required this.locationMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading = loading || nearbyLoading;
    final hasError = errorMessage != null;
    final hasLocationMessage = locationMessage != null;

    if (!isLoading && !hasError && !hasLocationMessage) {
      return const SizedBox.shrink();
    }

    Widget icon;
    String text;
    Color textColor = AppColors.textPrimary;
    Widget? action;

    if (isLoading) {
      icon = const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.teal),
        ),
      );
      text = 'Cargando\nreportes...';
    } else if (hasError) {
      icon = const Icon(
        Icons.error_outline_rounded,
        color: AppColors.danger,
        size: 16,
      );
      text = errorMessage!;
      textColor = AppColors.danger;
      action = GestureDetector(
        onTap: onRetry,
        child: Container(
          margin: const EdgeInsets.only(left: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.refresh_rounded, size: 12, color: AppColors.danger),
              SizedBox(width: 4),
              Text(
                'Reintentar',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      icon = const Icon(
        Icons.location_on_outlined,
        color: AppColors.teal,
        size: 16,
      );
      text = locationMessage!;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    // Evita solaparse con el view toggle flotante en el HomePage (der: 16, ancho: ~214)
    final maxWidth = screenWidth - 260;

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth > 100 ? maxWidth : 100),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.lightGray.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ),
          // ignore: use_null_aware_elements
          if (action != null) action,
        ],
      ),
    );
  }
}

class _MapActionButton extends StatelessWidget {
  final String tooltip;
  final IconData? icon;
  final Widget? child;
  final VoidCallback? onPressed;

  const _MapActionButton({
    required this.tooltip,
    required this.icon,
    this.child,
    required this.onPressed,
  });

  Color get color => AppColors.white;
  Color get foregroundColor => AppColors.teal;

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

class _IncidentClusterMarker extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _IncidentClusterMarker({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navy.withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.layers_rounded,
                        color: AppColors.gold,
                        size: 14,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '$count',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Container(
            width: 12,
            height: 12,
            transform: Matrix4.translationValues(0, -3, 0)..rotateZ(0.785398),
            decoration: const BoxDecoration(
              color: AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClusterIncidentItem extends StatelessWidget {
  final IncidentModel incident;
  final VoidCallback onTap;

  const _ClusterIncidentItem({
    required this.incident,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.lightGray, width: 1),
      ),
      color: AppColors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              IncidentCategoryIcon(
                category: incident.nombreCategoria,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      incident.titulo.isEmpty
                          ? 'Incidencia sin título'
                          : incident.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      incident.descripcion.isEmpty
                          ? 'Sin descripción disponible'
                          : incident.descripcion,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  incident.nombreEstado,
                  style: const TextStyle(
                    color: AppColors.teal,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationWarningCard extends StatelessWidget {
  final _LocationStatus status;
  final VoidCallback onActionPressed;
  final VoidCallback onDismiss;

  const _LocationWarningCard({
    required this.status,
    required this.onActionPressed,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isServiceDisabled = status == _LocationStatus.serviceDisabled;
    final title = isServiceDisabled ? 'Ubicación desactivada' : 'Permiso de ubicación requerido';
    final description = isServiceDisabled
        ? 'Para mostrar los reportes en el mapa y usar tu posición actual, por favor activa el GPS de tu dispositivo.'
        : 'CuencaActiva necesita acceso a tu ubicación para centrar el mapa y mostrar incidencias cercanas.';
    final buttonText = isServiceDisabled ? 'Activar GPS' : 'Habilitar en Ajustes';
    final icon = isServiceDisabled ? Icons.location_off_rounded : Icons.location_disabled_rounded;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 6,
      shadowColor: AppColors.navy.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.danger.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Container(
        color: AppColors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.danger,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.navy,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.3,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onDismiss,
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: onDismiss,
                    child: const Text(
                      'Explorar sin ubicación',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: onActionPressed,
                    child: Text(
                      buttonText,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
