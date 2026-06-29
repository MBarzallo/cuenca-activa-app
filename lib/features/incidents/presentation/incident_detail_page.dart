import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/logic/auth_cubit.dart';
import '../../auth/logic/auth_state.dart';
import '../../home/presentation/widgets/home_shared_widgets.dart';
import '../data/incident_comment_model.dart';
import '../data/incident_completion_confirmation_model.dart';
import '../data/incident_image_attachment.dart';
import '../data/incident_model.dart';
import '../data/incident_status_history_model.dart';
import '../data/incident_status_option_model.dart';
import '../data/incident_vote_model.dart';
import '../data/multimedia_model.dart';
import '../logic/incidents_cubit.dart';
import '../logic/incidents_state.dart';

class IncidentDetailPage extends StatefulWidget {
  final String idIncidencia;

  const IncidentDetailPage({super.key, required this.idIncidencia});

  @override
  State<IncidentDetailPage> createState() => _IncidentDetailPageState();
}

class _IncidentDetailPageState extends State<IncidentDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IncidentsCubit>().loadIncidentDetail(widget.idIncidencia);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<IncidentsCubit, IncidentsState>(
      listenWhen: (previous, current) =>
          previous.statusChangeMessage != current.statusChangeMessage ||
          previous.contentReportMessage != current.contentReportMessage,
      listener: (context, state) {
        final message =
            state.statusChangeMessage ?? state.contentReportMessage;
        if (message != null && message.isNotEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      },
      builder: (context, state) {
        if (state.detailLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detalle')),
            body: const _DetailLoadingView(),
          );
        }

        if (state.detailErrorMessage != null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detalle')),
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: HomeInfoState(
                icon: Icons.cloud_off_rounded,
                title: 'No pudimos cargar el detalle',
                message: state.detailErrorMessage!,
                actionLabel: 'Reintentar',
                onAction: () => context
                    .read<IncidentsCubit>()
                    .loadIncidentDetail(widget.idIncidencia),
              ),
            ),
          );
        }

        final incident = state.selectedIncident;
        if (incident == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detalle')),
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: HomeInfoState(
                icon: Icons.report_problem_outlined,
                title: 'Incidencia no disponible',
                message: 'No encontramos información para esta incidencia.',
                actionLabel: 'Volver',
                onAction: () => context.pop(),
              ),
            ),
          );
        }

        return _IncidentDetailContent(
          incident: incident,
          multimedia: state.selectedIncidentMultimedia,
        );
      },
    );
  }
}

class _IncidentDetailContent extends StatefulWidget {
  final IncidentModel incident;
  final List<MultimediaModel> multimedia;

  const _IncidentDetailContent({
    required this.incident,
    required this.multimedia,
  });

  @override
  State<_IncidentDetailContent> createState() => _IncidentDetailContentState();
}

class _IncidentDetailContentState extends State<_IncidentDetailContent> {
  int _activeTab = 0;

  void _showVoteSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<IncidentsCubit>(),
        child: _VoteSheet(incident: widget.incident),
      ),
    );
  }

  void _showChangeStatusSheet(
    BuildContext context,
    List<IncidentStatusOptionModel> statuses,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return BlocProvider.value(
          value: context.read<IncidentsCubit>(),
          child: _ChangeStatusSheet(incident: widget.incident, statuses: statuses),
        );
      },
    );
  }

  Widget _buildTabButton(int index, String label) {
    final isActive = _activeTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTab = index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppColors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.navy.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isActive ? AppColors.teal : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final currentUserId = authState is AuthAuthenticated
        ? authState.user.idUsuario
        : '';
    final isOwner =
        currentUserId.isNotEmpty && currentUserId == widget.incident.idUsuarioReporta;
    final date = widget.incident.fechaReporte;
    final formattedDate = date == null
        ? 'Fecha no disponible'
        : DateFormat('dd MMM yyyy, HH:mm').format(date.toLocal());

    return BlocBuilder<IncidentsCubit, IncidentsState>(
      builder: (context, state) {
        final following = state.followStatus?.siguiendo == true;
        final availableStatuses = state.statusOptions
            .where((status) => status.codigo != widget.incident.codigoEstado)
            .toList();

        Widget? bottomBar;
        final isFinalState = _isFinalIncidentState(widget.incident);
        if (!isFinalState) {
          final Widget button;
          if (isOwner) {
            if (availableStatuses.isNotEmpty) {
              button = FilledButton.icon(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: state.statusChanging
                    ? null
                    : () => _showChangeStatusSheet(context, availableStatuses),
                icon: state.statusChanging
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.sync_alt_rounded),
                label: const Text('Cambiar estado de incidencia'),
              );
              bottomBar = Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navy.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: SizedBox(height: 48, child: button),
                  ),
                ),
              );
            }
          } else if (!following) {
            button = FilledButton.icon(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: state.followActionLoading
                  ? null
                  : () => context.read<IncidentsCubit>().followIncident(widget.incident.idIncidencia),
              icon: state.followActionLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.notifications_active_rounded),
              label: const Text('Seguir este reporte'),
            );
            bottomBar = Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navy.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: SizedBox(height: 48, child: button),
                ),
              ),
            );
          } else {
            button = FilledButton.icon(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => _showVoteSheet(context),
              icon: const Icon(Icons.how_to_vote_rounded),
              label: const Text('Validar esta incidencia'),
            );
            bottomBar = Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navy.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: SizedBox(height: 48, child: button),
                ),
              ),
            );
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detalle'),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (value) {
                  if (value == 'denunciar') {
                    _showReportContentSheet(
                      context,
                      tipoEntidad: 'INCIDENCIA',
                      idEntidad: widget.incident.idIncidencia,
                      title: 'Denunciar incidencia',
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'denunciar',
                    child: Row(
                      children: [
                        Icon(Icons.flag_outlined, color: AppColors.danger, size: 20),
                        SizedBox(width: 8),
                        Text('Denunciar reporte', style: TextStyle(color: AppColors.danger)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _ImageGallery(images: widget.incident.imagenes, multimedia: widget.multimedia),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IncidentCategoryIcon(
                              category: widget.incident.nombreCategoria,
                              size: 44,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.incident.titulo.isEmpty
                                        ? 'Incidencia sin título'
                                        : widget.incident.titulo,
                                    style: Theme.of(context).textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.incident.nombreCategoria,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.incident.descripcion.isEmpty
                              ? 'Sin descripción disponible.'
                              : widget.incident.descripcion,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            StatusChip(
                              icon: Icons.flag_rounded,
                              label: widget.incident.nombreEstado,
                              color: AppColors.teal,
                            ),
                            StatusChip(
                              icon: Icons.person_outline_rounded,
                              label: widget.incident.aliasUsuarioReporta.isEmpty
                                  ? 'Ciudadano'
                                  : '@${widget.incident.aliasUsuarioReporta}',
                              color: AppColors.textSecondary,
                            ),
                            StatusChip(
                              icon: Icons.schedule_rounded,
                              label: formattedDate,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _MetricsSection(incident: widget.incident),
                const SizedBox(height: 12),
                _QuickActionsSection(incident: widget.incident),
                const SizedBox(height: 8),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.lightGray.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        _buildTabButton(0, 'Resumen'),
                        _buildTabButton(1, 'Comunidad'),
                        _buildTabButton(2, 'Seguimiento'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (_activeTab == 0) ...[
                  _LocationSection(incident: widget.incident),
                ] else if (_activeTab == 1) ...[
                  _VoteSection(incident: widget.incident),
                  const SizedBox(height: 12),
                  _CommentsSection(idIncidencia: widget.incident.idIncidencia),
                  const SizedBox(height: 12),
                  _RelatedIncidentsSection(incident: widget.incident),
                ] else ...[
                  _CompletionSection(incident: widget.incident),
                  const SizedBox(height: 12),
                  _StatusHistorySection(idIncidencia: widget.incident.idIncidencia),
                  if (isOwner) ...[
                    const SizedBox(height: 12),
                    _OwnerStatusAction(incident: widget.incident),
                  ],
                ],
              ],
            ),
          ),
          bottomNavigationBar: bottomBar,
        );
      },
    );
  }
}

class _ImageGallery extends StatelessWidget {
  final List<String> images;
  final List<MultimediaModel> multimedia;

  const _ImageGallery({required this.images, required this.multimedia});

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Container(
        height: 120, // Compact height 120 px
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.gold,
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sin imágenes adjuntas',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final mediaItems = multimedia
        .where((media) => media.downloadUrl.isNotEmpty)
        .toList();
    final itemCount = mediaItems.isNotEmpty ? mediaItems.length : images.length;

    return SizedBox(
      height: 200,
      child: PageView.builder(
        itemCount: itemCount,
        itemBuilder: (context, index) {
          final media = mediaItems.isNotEmpty ? mediaItems[index] : null;
          final imageUrl = media?.downloadUrl ?? images[index];

          return Padding(
            padding: EdgeInsets.only(right: index == itemCount - 1 ? 0 : 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showImageViewer(
                          context,
                          imageUrl: imageUrl,
                          title: media?.nombreArchivo ?? 'Imagen de incidencia',
                        ),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppColors.lightGray,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.navy,
                            child: const Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: AppColors.gold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (media != null)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _ReportIconButton(
                        tooltip: 'Denunciar imagen',
                        tipoEntidad: 'MULTIMEDIA',
                        idEntidad: media.idMultimedia,
                        title: 'Denunciar imagen',
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}



Future<void> _showImageViewer(
  BuildContext context, {
  required String imageUrl,
  required String title,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.92),
    builder: (dialogContext) {
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Center(
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (_, _) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (_, _, _) => const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.gold,
                          size: 42,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title.trim().isEmpty ? 'Imagen' : title.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Material(
                      color: AppColors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      child: IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: AppColors.white,
                        tooltip: 'Cerrar',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ReportIconButton extends StatelessWidget {
  final String tooltip;
  final String tipoEntidad;
  final String idEntidad;
  final String title;

  const _ReportIconButton({
    required this.tooltip,
    required this.tipoEntidad,
    required this.idEntidad,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.navy.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(999),
      child: IconButton(
        tooltip: tooltip,
        onPressed: () => _showReportContentSheet(
          context,
          tipoEntidad: tipoEntidad,
          idEntidad: idEntidad,
          title: title,
        ),
        icon: const Icon(Icons.flag_outlined),
        color: AppColors.white,
        iconSize: 18,
        constraints: const BoxConstraints.tightFor(width: 38, height: 38),
      ),
    );
  }
}

Future<void> _showReportContentSheet(
  BuildContext context, {
  required String tipoEntidad,
  required String idEntidad,
  required String title,
  String? preselectedMotive,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<IncidentsCubit>(),
      child: _ReportContentSheet(
        tipoEntidad: tipoEntidad,
        idEntidad: idEntidad,
        title: title,
        preselectedMotive: preselectedMotive,
      ),
    ),
  );
}

class _ReportContentSheet extends StatefulWidget {
  final String tipoEntidad;
  final String idEntidad;
  final String title;
  final String? preselectedMotive;

  const _ReportContentSheet({
    required this.tipoEntidad,
    required this.idEntidad,
    required this.title,
    this.preselectedMotive,
  });

  @override
  State<_ReportContentSheet> createState() => _ReportContentSheetState();
}

class _ReportContentSheetState extends State<_ReportContentSheet> {
  static const _motivos = [
    'Contenido inapropiado',
    'Información falsa',
    'Spam o publicidad',
    'Riesgo para la comunidad',
    'Incidencia duplicada',
    'Incidencia relacionada',
    'Otro',
  ];

  final _detalleController = TextEditingController();
  late String _motivo;

  @override
  void initState() {
    super.initState();
    _motivo = widget.preselectedMotive ?? _motivos.first;
  }

  @override
  void dispose() {
    _detalleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: BlocBuilder<IncidentsCubit, IncidentsState>(
          builder: (context, state) {
            final submitting = state.contentReportSubmitting;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.lightGray,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.flag_outlined,
                        color: AppColors.danger,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _motivo,
                  decoration: const InputDecoration(
                    labelText: 'Motivo',
                    prefixIcon: Icon(Icons.error_outline_rounded),
                  ),
                  items: _motivos
                      .map(
                        (motivo) => DropdownMenuItem(
                          value: motivo,
                          child: Text(motivo),
                        ),
                      )
                      .toList(),
                  onChanged: submitting
                      ? null
                      : (value) => setState(() {
                          _motivo = value ?? _motivos.first;
                        }),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _detalleController,
                  enabled: !submitting,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'Detalle opcional',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: submitting ? null : _submit,
                    icon: submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_outlined),
                    label: Text(submitting ? 'Enviando...' : 'Enviar denuncia'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: AppColors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final success = await context.read<IncidentsCubit>().reportContent(
      tipoEntidad: widget.tipoEntidad,
      idEntidad: widget.idEntidad,
      motivo: _motivo,
      detalle: _detalleController.text,
    );

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }
}

bool _isFinalIncidentState(IncidentModel incident) {
  final normalized = '${incident.codigoEstado} ${incident.nombreEstado}'
      .toUpperCase();

  return normalized.contains('CERR') ||
      normalized.contains('FINAL') ||
      normalized.contains('RESUEL') ||
      normalized.contains('SOLUCION');
}

class _MetricsSection extends StatelessWidget {
  final IncidentModel incident;

  const _MetricsSection({required this.incident});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.lightGray.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCompactMetric(
            context,
            icon: Icons.check_circle_outline_rounded,
            value: incident.cantidadConfirmaciones,
            label: 'Confirmaciones',
            color: AppColors.success,
          ),
          _buildCompactMetric(
            context,
            icon: Icons.comment_outlined,
            value: incident.cantidadComentarios,
            label: 'Comentarios',
            color: AppColors.teal,
          ),
          _buildCompactMetric(
            context,
            icon: Icons.notifications_none_rounded,
            value: incident.cantidadSeguidores,
            label: 'Seguidores',
            color: AppColors.gold,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMetric(
    BuildContext context, {
    required IconData icon,
    required int value,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          '$value',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(width: 4),
        Text(
          label.toLowerCase(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
        ),
      ],
    );
  }
}



class _OwnerStatusAction extends StatelessWidget {
  final IncidentModel incident;

  const _OwnerStatusAction({required this.incident});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IncidentsCubit, IncidentsState>(
      builder: (context, state) {
        final availableStatuses = state.statusOptions
            .where((status) => status.codigo != incident.codigoEstado)
            .toList();

        if (availableStatuses.isEmpty) return const SizedBox.shrink();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.edit_road_rounded,
                        color: AppColors.gold,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gestionar estado',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          Text(
                            'Actualizar el avance del reporte',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: state.statusOptionsLoading || state.statusChanging
                        ? null
                        : () => _showChangeStatusSheet(context, availableStatuses),
                    icon: state.statusChanging
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync_alt_rounded, size: 16),
                    label: Text(
                      state.statusOptionsLoading ? 'Cargando estados...' : 'Cambiar estado',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showChangeStatusSheet(
    BuildContext context,
    List<IncidentStatusOptionModel> statuses,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      builder: (_) {
        return BlocProvider.value(
          value: context.read<IncidentsCubit>(),
          child: _ChangeStatusSheet(incident: incident, statuses: statuses),
        );
      },
    );
  }
}

class _ChangeStatusSheet extends StatefulWidget {
  final IncidentModel incident;
  final List<IncidentStatusOptionModel> statuses;

  const _ChangeStatusSheet({required this.incident, required this.statuses});

  @override
  State<_ChangeStatusSheet> createState() => _ChangeStatusSheetState();
}

class _ChangeStatusSheetState extends State<_ChangeStatusSheet> {
  final TextEditingController _observationController = TextEditingController();
  String? _selectedStatusCode;

  @override
  void initState() {
    super.initState();
    _selectedStatusCode = widget.statuses.isEmpty
        ? null
        : widget.statuses.first.codigo;
  }

  @override
  void dispose() {
    _observationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: BlocBuilder<IncidentsCubit, IncidentsState>(
          builder: (context, state) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.lightGray,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Cambiar estado',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.incident.titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  initialValue: _selectedStatusCode,
                  decoration: const InputDecoration(
                    labelText: 'Nuevo estado',
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                  items: widget.statuses.map((status) {
                    return DropdownMenuItem<String>(
                      value: status.codigo,
                      child: Text(status.nombre),
                    );
                  }).toList(),
                  onChanged: state.statusChanging
                      ? null
                      : (value) => setState(() => _selectedStatusCode = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _observationController,
                  enabled: !state.statusChanging,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Observación opcional',
                    hintText: 'Ej. Ya fue atendido parcialmente',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: state.statusChanging || _selectedStatusCode == null
                      ? null
                      : () async {
                          await context
                              .read<IncidentsCubit>()
                              .changeIncidentStatus(
                                idIncidencia: widget.incident.idIncidencia,
                                codigoEstado: _selectedStatusCode!,
                                observacion: _observationController.text,
                              );

                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                  icon: state.statusChanging
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: const Text('Guardar estado'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatusHistorySection extends StatefulWidget {
  final String idIncidencia;

  const _StatusHistorySection({required this.idIncidencia});

  @override
  State<_StatusHistorySection> createState() => _StatusHistorySectionState();
}

class _StatusHistorySectionState extends State<_StatusHistorySection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IncidentsCubit, IncidentsState>(
      builder: (context, state) {
        final history = state.statusHistory;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.teal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.timeline_rounded,
                        color: AppColors.teal,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Historial de estado',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Actualizar historial',
                      onPressed: state.statusHistoryLoading
                          ? null
                          : () => context
                                .read<IncidentsCubit>()
                                .refreshIncidentStatusHistory(widget.idIncidencia),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (state.statusHistoryLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else if (state.statusHistoryErrorMessage != null)
                  _InlineErrorState(
                    message: state.statusHistoryErrorMessage!,
                    onRetry: () => context
                        .read<IncidentsCubit>()
                        .refreshIncidentStatusHistory(widget.idIncidencia),
                  )
                else if (history.isEmpty)
                  const _InlineEmptyState(
                    icon: Icons.history_toggle_off_rounded,
                    message: 'Sin cambios de estado registrados.',
                  )
                else ...[
                  if (!_isExpanded) ...[
                    _StatusHistoryItem(item: history.first, isLast: true),
                    if (history.length > 1)
                      Center(
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () => setState(() => _isExpanded = true),
                          icon: const Icon(Icons.expand_more_rounded, size: 16),
                          label: const Text('Ver historial completo'),
                        ),
                      ),
                  ] else ...[
                    ...history.map((item) {
                      final isLast = item == history.last;
                      return _StatusHistoryItem(item: item, isLast: isLast);
                    }),
                    Center(
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => setState(() => _isExpanded = false),
                        icon: const Icon(Icons.expand_less_rounded, size: 16),
                        label: const Text('Colapsar historial'),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusHistoryItem extends StatelessWidget {
  final IncidentStatusHistoryModel item;
  final bool isLast;

  const _StatusHistoryItem({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final date = item.cambiadoEn == null
        ? 'Fecha no disponible'
        : DateFormat('dd MMM yyyy, HH:mm').format(item.cambiadoEn!.toLocal());
    final actor = item.aliasUsuarioAccion.isEmpty
        ? 'Sistema'
        : '@${item.aliasUsuarioAccion}';
    final previous = item.nombreEstadoAnterior.isEmpty
        ? 'Inicio'
        : item.nombreEstadoAnterior;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: AppColors.teal,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(width: 2, height: 74, color: AppColors.lightGray),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$previous → ${item.nombreEstadoNuevo}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '$actor · $date',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _historyOriginLabel(item.origenCambio),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.teal,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                if (item.observacion.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.observacion,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InlineErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _InlineErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.3,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

String _historyOriginLabel(String origin) {
  return switch (origin.toUpperCase()) {
    'CREACION' => 'Creación',
    'CIUDADANO' => 'Ciudadano',
    'ADMINISTRACION' => 'Administración',
    'MANUAL' => 'Manual',
    'SISTEMA' => 'Sistema',
    _ => origin.isEmpty ? 'Cambio' : origin,
  };
}

class _InlineEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _InlineEmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationSection extends StatelessWidget {
  final IncidentModel incident;

  const _LocationSection({required this.incident});

  @override
  Widget build(BuildContext context) {
    final lat = incident.latitud;
    final lng = incident.longitud;
    final hasCoordinates = lat != null && lng != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ubicación',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            if ((incident.nombreSector ?? '').trim().isNotEmpty)
              _DetailRow(
                icon: Icons.map_outlined,
                text: 'Sector: ${incident.nombreSector!}',
              ),
            if ((incident.direccionReferencial ?? '').trim().isNotEmpty)
              _DetailRow(
                icon: Icons.place_outlined,
                text: incident.direccionReferencial!,
              ),
            if (hasCoordinates) ...[
              const SizedBox(height: 12),
              Container(
                height: 130, // Mini map compact height
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.lightGray),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(lat, lng),
                      initialZoom: 15,
                      minZoom: 10,
                      maxZoom: 18,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.cuenca_activa_app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(lat, lng),
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: AppColors.danger,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CompletionSection extends StatelessWidget {
  final IncidentModel incident;

  const _CompletionSection({required this.incident});

  void _showCompletionSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<IncidentsCubit>(),
        child: _CompletionSheet(incident: incident),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IncidentsCubit, IncidentsState>(
      builder: (context, state) {
        final summary = state.completionSummary ?? const IncidentCompletionSummaryModel.empty();
        final userConfirmation = summary.confirmacionUsuario;
        final isFinalState = _isFinalIncidentState(incident);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.11),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.task_alt_rounded,
                        color: AppColors.success,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Confirmar completado',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          Text(
                            '${summary.totalConfirmaciones} confirmaciones registradas',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: state.completionSummaryLoading
                          ? null
                          : () => context
                                .read<IncidentsCubit>()
                                .refreshIncidentCompletionSummary(incident.idIncidencia),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (state.completionSummaryLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else if (state.completionSummaryErrorMessage != null)
                  _CompletionErrorState(
                    message: state.completionSummaryErrorMessage!,
                    onRetry: () => context
                        .read<IncidentsCubit>()
                        .refreshIncidentCompletionSummary(incident.idIncidencia),
                  )
                else ...[
                  if (isFinalState)
                    const _InlineEmptyState(
                      icon: Icons.verified_rounded,
                      message: 'La incidencia ya está resuelta.',
                    )
                  else if (summary.usuarioYaConfirmo && userConfirmation != null)
                    _AlreadyConfirmedState(confirmation: userConfirmation)
                  else
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _showCompletionSheet(context),
                        icon: const Icon(Icons.verified_rounded, size: 16),
                        label: const Text('Confirmar completado'),
                      ),
                    ),
                  if (state.recentConfirmations.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _RecentConfirmationsList(confirmations: state.recentConfirmations),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CompletionComposer extends StatelessWidget {
  final TextEditingController observationController;
  final double? latitude;
  final double? longitude;
  final XFile? selectedImage;
  final bool locating;
  final bool submitting;
  final String? errorMessage;
  final VoidCallback onUseLocation;
  final VoidCallback onClearLocation;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;
  final VoidCallback onClearImage;
  final VoidCallback onSubmit;

  const _CompletionComposer({
    required this.observationController,
    required this.latitude,
    required this.longitude,
    required this.selectedImage,
    required this.locating,
    required this.submitting,
    required this.errorMessage,
    required this.onUseLocation,
    required this.onClearLocation,
    required this.onPickCamera,
    required this.onPickGallery,
    required this.onClearImage,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocation = latitude != null && longitude != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Usa esta acción solo si observas que la incidencia aparentemente ya fue solucionada.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: observationController,
          enabled: !submitting,
          maxLines: 3,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'Observación opcional',
            filled: true,
            fillColor: AppColors.lightGray.withValues(alpha: 0.55),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: AppColors.success,
                width: 1.4,
              ),
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
        const SizedBox(height: 8),
        _CompletionImagePicker(
          selectedImage: selectedImage,
          submitting: submitting,
          onPickCamera: onPickCamera,
          onPickGallery: onPickGallery,
          onClearImage: onClearImage,
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: hasLocation
                ? AppColors.success.withValues(alpha: 0.08)
                : AppColors.lightGray.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                hasLocation
                    ? Icons.location_on_outlined
                    : Icons.location_off_outlined,
                color: hasLocation
                    ? AppColors.success
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hasLocation
                      ? '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}'
                      : 'Puedes adjuntar tu ubicación actual como evidencia.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: submitting || locating
                    ? null
                    : hasLocation
                    ? onClearLocation
                    : onUseLocation,
                child: Text(
                  locating
                      ? 'Ubicando...'
                      : hasLocation
                      ? 'Quitar'
                      : 'Usar',
                ),
              ),
            ],
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 10),
          Text(
            errorMessage!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.danger,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: submitting ? null : onSubmit,
            icon: submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.task_alt_rounded),
            label: Text(submitting ? 'Registrando...' : 'Confirmar completado'),
          ),
        ),
      ],
    );
  }
}

class _CompletionImagePicker extends StatelessWidget {
  final XFile? selectedImage;
  final bool submitting;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;
  final VoidCallback onClearImage;

  const _CompletionImagePicker({
    required this.selectedImage,
    required this.submitting,
    required this.onPickCamera,
    required this.onPickGallery,
    required this.onClearImage,
  });

  @override
  Widget build(BuildContext context) {
    final image = selectedImage;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: image == null
            ? AppColors.lightGray.withValues(alpha: 0.58)
            : AppColors.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                image == null
                    ? Icons.image_outlined
                    : Icons.image_search_rounded,
                color: image == null ? AppColors.textSecondary : AppColors.gold,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  image == null
                      ? 'Puedes adjuntar una foto como evidencia.'
                      : image.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (image != null)
                TextButton(
                  onPressed: submitting ? null : onClearImage,
                  child: const Text('Quitar'),
                ),
            ],
          ),
          if (image == null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: submitting ? null : onPickCamera,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Cámara'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: submitting ? null : onPickGallery,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Galería'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RecentConfirmationsList extends StatelessWidget {
  final List<IncidentCompletionConfirmationDetailModel> confirmations;

  const _RecentConfirmationsList({required this.confirmations});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirmaciones recientes',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        ...confirmations.map((confirmation) {
          return _ConfirmationDetailCard(confirmation: confirmation);
        }),
      ],
    );
  }
}

class _ConfirmationDetailCard extends StatelessWidget {
  final IncidentCompletionConfirmationDetailModel confirmation;

  const _ConfirmationDetailCard({required this.confirmation});

  @override
  Widget build(BuildContext context) {
    final date = confirmation.creadoEn == null
        ? 'Fecha no disponible'
        : DateFormat('dd MMM, HH:mm').format(confirmation.creadoEn!.toLocal());
    final observation = (confirmation.observacion ?? '').trim();
    final alias = confirmation.aliasUsuario.isEmpty
        ? 'Ciudadano'
        : '@${confirmation.aliasUsuario}';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_outlined, color: AppColors.success),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$alias · $date',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _ReportIconButton(
                tooltip: 'Denunciar confirmación',
                tipoEntidad: 'CONFIRMACION',
                idEntidad: confirmation.idConfirmacion,
                title: 'Denunciar confirmación',
              ),
            ],
          ),
          if (observation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              observation,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ],
          if (confirmation.hasLocation) ...[
            const SizedBox(height: 8),
            _DetailRow(
              icon: Icons.location_on_outlined,
              text:
                  '${confirmation.latitud!.toStringAsFixed(6)}, ${confirmation.longitud!.toStringAsFixed(6)}',
            ),
          ],
          if (confirmation.multimedia.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 78,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: confirmation.multimedia.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final media = confirmation.multimedia[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 96,
                      height: 78,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showImageViewer(
                                context,
                                imageUrl: media.downloadUrl,
                                title: media.nombreArchivo.isEmpty
                                    ? 'Evidencia'
                                    : media.nombreArchivo,
                              ),
                              child: CachedNetworkImage(
                                imageUrl: media.downloadUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, _) => Container(
                                  color: AppColors.lightGray,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                                errorWidget: (_, _, _) => Container(
                                  color: AppColors.navy,
                                  child: const Icon(
                                    Icons.broken_image_outlined,
                                    color: AppColors.gold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: _ReportIconButton(
                              tooltip: 'Denunciar evidencia',
                              tipoEntidad: 'MULTIMEDIA',
                              idEntidad: media.idMultimedia,
                              title: 'Denunciar evidencia',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AlreadyConfirmedState extends StatelessWidget {
  final IncidentCompletionConfirmationModel confirmation;

  const _AlreadyConfirmedState({required this.confirmation});

  @override
  Widget build(BuildContext context) {
    final observation = (confirmation.observacion ?? '').trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.success,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ya confirmaste el completado',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  confirmation.hasLocation
                      ? 'Incluiste ubicación como respaldo.'
                      : 'Confirmación registrada sin ubicación.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (observation.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    observation,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _CompletionErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.danger),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}



class _VoteSection extends StatelessWidget {
  final IncidentModel incident;

  const _VoteSection({required this.incident});

  void _showVoteSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<IncidentsCubit>(),
        child: _VoteSheet(incident: incident),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IncidentsCubit, IncidentsState>(
      builder: (context, state) {
        final summary = state.voteSummary ?? const IncidentVoteSummaryModel.empty();
        final userVote = summary.votoUsuario;
        final isFinalState = _isFinalIncidentState(incident);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.how_to_vote_outlined,
                        color: AppColors.gold,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Validación comunitaria',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          Text(
                            '${summary.total} votos registrados',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: state.voteSummaryLoading
                          ? null
                          : () => context
                                .read<IncidentsCubit>()
                                .refreshIncidentVoteSummary(incident.idIncidencia),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (state.voteSummaryLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else if (state.voteSummaryErrorMessage != null)
                  _VoteErrorState(
                    message: state.voteSummaryErrorMessage!,
                    onRetry: () => context
                        .read<IncidentsCubit>()
                        .refreshIncidentVoteSummary(incident.idIncidencia),
                  )
                else ...[
                  _VoteCounts(summary: summary),
                  const SizedBox(height: 12),
                  if (isFinalState)
                    const _InlineEmptyState(
                      icon: Icons.lock_outline_rounded,
                      message: 'La validación se cerró por estado final.',
                    )
                  else if (summary.usuarioYaVoto && userVote != null)
                    _AlreadyVotedState(vote: userVote)
                  else
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _showVoteSheet(context),
                        icon: const Icon(Icons.how_to_vote_rounded, size: 16),
                        label: const Text('Validar reporte'),
                      ),
                    ),
                  if (state.recentVotes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _RecentVotesList(votes: state.recentVotes),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _VoteCounts extends StatelessWidget {
  final IncidentVoteSummaryModel summary;

  const _VoteCounts({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _VoteCountPill(
            label: 'Existe',
            value: summary.countFor('CONFIRMA_EXISTENCIA'),
            icon: Icons.verified_outlined,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _VoteCountPill(
            label: 'No existe',
            value: summary.countFor('NO_EXISTE'),
            icon: Icons.report_off_outlined,
            color: AppColors.danger,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _VoteCountPill(
            label: 'Importante',
            value: summary.countFor('IMPORTANTE'),
            icon: Icons.priority_high_rounded,
            color: AppColors.gold,
          ),
        ),
      ],
    );
  }
}

class _VoteCountPill extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _VoteCountPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentVotesList extends StatelessWidget {
  final List<IncidentVoteModel> votes;

  const _RecentVotesList({required this.votes});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Validaciones recientes',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        ...votes.map((vote) => _RecentVoteTile(vote: vote)),
      ],
    );
  }
}

class _RecentVoteTile extends StatelessWidget {
  final IncidentVoteModel vote;

  const _RecentVoteTile({required this.vote});

  @override
  Widget build(BuildContext context) {
    final alias = vote.aliasUsuario.isEmpty
        ? 'Ciudadano'
        : '@${vote.aliasUsuario}';
    final date = vote.creadoEn == null
        ? ''
        : DateFormat('dd MMM, HH:mm').format(vote.creadoEn!.toLocal());
    final observation = (vote.observacion ?? '').trim();
    final color = _voteTypeColor(vote.tipoVoto);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_voteTypeIcon(vote.tipoVoto), color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$alias · ${_voteLabel(vote.tipoVoto)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
                if (date.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (observation.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    observation,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VoteComposer extends StatelessWidget {
  final String selectedVoteType;
  final TextEditingController observationController;
  final bool submitting;
  final String? errorMessage;
  final ValueChanged<String> onVoteChanged;
  final VoidCallback onSubmit;

  const _VoteComposer({
    required this.selectedVoteType,
    required this.observationController,
    required this.submitting,
    required this.errorMessage,
    required this.onVoteChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _VoteChoiceChip(
              label: 'Confirmo que existe',
              value: 'CONFIRMA_EXISTENCIA',
              selectedValue: selectedVoteType,
              onSelected: onVoteChanged,
            ),
            _VoteChoiceChip(
              label: 'No corresponde',
              value: 'NO_EXISTE',
              selectedValue: selectedVoteType,
              onSelected: onVoteChanged,
            ),
            _VoteChoiceChip(
              label: 'Es importante',
              value: 'IMPORTANTE',
              selectedValue: selectedVoteType,
              onSelected: onVoteChanged,
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: observationController,
          enabled: !submitting,
          maxLines: 3,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'Observación opcional',
            filled: true,
            fillColor: AppColors.lightGray.withValues(alpha: 0.55),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppColors.gold, width: 1.4),
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 6),
          Text(
            errorMessage!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.danger,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: submitting ? null : onSubmit,
            icon: submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.how_to_vote_rounded),
            label: Text(submitting ? 'Registrando...' : 'Validar reporte'),
          ),
        ),
      ],
    );
  }
}

String _voteLabel(String type) {
  return switch (type) {
    'CONFIRMA_EXISTENCIA' => 'Existe',
    'NO_EXISTE' => 'No corresponde',
    'IMPORTANTE' => 'Importante',
    _ => 'Validación',
  };
}

IconData _voteTypeIcon(String type) {
  return switch (type) {
    'CONFIRMA_EXISTENCIA' => Icons.check_circle_outline_rounded,
    'NO_EXISTE' => Icons.cancel_outlined,
    'IMPORTANTE' => Icons.priority_high_rounded,
    _ => Icons.how_to_vote_outlined,
  };
}

Color _voteTypeColor(String type) {
  return switch (type) {
    'CONFIRMA_EXISTENCIA' => AppColors.success,
    'NO_EXISTE' => AppColors.danger,
    'IMPORTANTE' => AppColors.gold,
    _ => AppColors.teal,
  };
}

class _VoteChoiceChip extends StatelessWidget {
  final String label;
  final String value;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  const _VoteChoiceChip({
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == selectedValue;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(value),
      selectedColor: AppColors.gold.withValues(alpha: 0.24),
      labelStyle: TextStyle(
        color: selected ? AppColors.navy : AppColors.textSecondary,
        fontWeight: FontWeight.w800,
      ),
      side: BorderSide(
        color: selected
            ? AppColors.gold
            : AppColors.lightGray.withValues(alpha: 0.8),
      ),
    );
  }
}

class _AlreadyVotedState extends StatelessWidget {
  final IncidentVoteModel vote;

  const _AlreadyVotedState({required this.vote});

  @override
  Widget build(BuildContext context) {
    final observation = (vote.observacion ?? '').trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.success,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ya validaste este reporte',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  _voteLabel(vote.tipoVoto),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (observation.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    observation,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _voteLabel(String type) {
    return switch (type) {
      'CONFIRMA_EXISTENCIA' => 'Confirmaste que la incidencia existe.',
      'NO_EXISTE' => 'Indicastes que no corresponde o no existe.',
      'IMPORTANTE' => 'Marcaste esta incidencia como importante.',
      _ => 'Validación registrada.',
    };
  }
}

class _VoteErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _VoteErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.danger),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

class _CommentsSection extends StatelessWidget {
  final String idIncidencia;

  const _CommentsSection({required this.idIncidencia});

  void _showCommentSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<IncidentsCubit>(),
        child: _CommentSheet(idIncidencia: idIncidencia),
      ),
    );
  }

  void _showAllCommentsDialog(BuildContext context, List<IncidentCommentModel> comments) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Comentarios (${comments.length})',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: comments.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _CommentTile(comment: comments[index]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IncidentsCubit, IncidentsState>(
      builder: (context, state) {
        final commentsCount = state.selectedIncidentComments.length;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.teal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.forum_outlined,
                        color: AppColors.teal,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Comentarios',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          Text(
                            '$commentsCount comentarios publicados',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: state.commentsLoading
                          ? null
                          : () => context
                                .read<IncidentsCubit>()
                                .refreshIncidentComments(idIncidencia),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (state.commentsLoading && state.selectedIncidentComments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _showCommentSheet(context),
                      icon: const Icon(Icons.comment_outlined, size: 16),
                      label: const Text('Escribir un comentario'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (state.selectedIncidentComments.isEmpty)
                    const _InlineEmptyState(
                      icon: Icons.chat_bubble_outline_rounded,
                      message: 'Sé el primero en comentar.',
                    )
                  else ...[
                    ...state.selectedIncidentComments.take(3).map((comment) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _CommentTile(comment: comment),
                        )),
                    if (commentsCount > 3)
                      Center(
                        child: TextButton(
                          onPressed: () => _showAllCommentsDialog(context, state.selectedIncidentComments),
                          child: const Text('Ver todos los comentarios'),
                        ),
                      ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CommentComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool submitting;
  final String? errorMessage;
  final VoidCallback onSubmit;

  const _CommentComposer({
    required this.controller,
    required this.submitting,
    required this.errorMessage,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          enabled: !submitting,
          minLines: 2,
          maxLines: 4,
          maxLength: 1000,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            hintText: 'Aporta información útil sobre esta incidencia...',
            filled: true,
            fillColor: AppColors.lightGray.withValues(alpha: 0.55),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppColors.teal, width: 1.4),
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 6),
          Text(
            errorMessage!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.danger,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: submitting ? null : onSubmit,
            icon: submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(submitting ? 'Publicando...' : 'Publicar comentario'),
          ),
        ),
      ],
    );
  }
}



class _CommentTile extends StatelessWidget {
  final IncidentCommentModel comment;

  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    final createdAt = comment.creadoEn;
    final formattedDate = createdAt == null
        ? 'Ahora'
        : DateFormat('dd MMM, HH:mm').format(createdAt.toLocal());
    final alias = comment.aliasUsuario.trim().isEmpty
        ? 'Ciudadano'
        : '@${comment.aliasUsuario.trim()}';
    final avatarLabel = alias.replaceFirst('@', '');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.navy.withValues(alpha: 0.08),
          foregroundColor: AppColors.navy,
          child: Text(
            avatarLabel.isEmpty
                ? 'C'
                : avatarLabel.substring(0, 1).toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      alias,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formattedDate,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: 'Denunciar comentario',
                    onPressed: () => _showReportContentSheet(
                      context,
                      tipoEntidad: 'COMENTARIO',
                      idEntidad: comment.idComentario,
                      title: 'Denunciar comentario',
                    ),
                    icon: const Icon(Icons.flag_outlined),
                    color: AppColors.danger,
                    iconSize: 18,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints.tightFor(
                      width: 32,
                      height: 32,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                comment.contenido,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.32,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailLoadingView extends StatelessWidget {
  const _DetailLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      children: [
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: AppColors.lightGray,
            borderRadius: BorderRadius.circular(26),
          ),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        const SizedBox(height: 16),
        const IncidentLoadingList(),
      ],
    );
  }
}

class _RelatedIncidentsSection extends StatefulWidget {
  final IncidentModel incident;

  const _RelatedIncidentsSection({required this.incident});

  @override
  State<_RelatedIncidentsSection> createState() => _RelatedIncidentsSectionState();
}

class _RelatedIncidentsSectionState extends State<_RelatedIncidentsSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IncidentsCubit, IncidentsState>(
      builder: (context, state) {
        final count = state.relatedIncidents.length;

        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: () {
                  setState(() => _isExpanded = !_isExpanded);
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.link_rounded,
                          color: AppColors.gold,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Incidencias relacionadas',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            Text(
                              '$count vinculadas',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Actualizar',
                        onPressed: state.relatedLoading
                            ? null
                            : () => context
                                  .read<IncidentsCubit>()
                                  .refreshRelatedIncidents(widget.incident.idIncidencia),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                      ),
                      Icon(
                        _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              if (_isExpanded) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      if (state.relatedLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      else if (state.relatedErrorMessage != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            state.relatedErrorMessage!,
                            style: const TextStyle(color: AppColors.danger, fontSize: 12),
                          ),
                        )
                      else if (state.relatedIncidents.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Sin reportes relacionados.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.relatedIncidents.length,
                          separatorBuilder: (context, index) => const Divider(height: 12),
                          itemBuilder: (context, index) {
                            final related = state.relatedIncidents[index];
                            final isDuplicated = related.tipoRelacion == 'DUPLICADA';

                            return InkWell(
                              onTap: () {
                                context.push('/incidents/${related.idIncidenciaRelacionada}');
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isDuplicated
                                            ? AppColors.danger.withValues(alpha: 0.1)
                                            : AppColors.teal.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isDuplicated ? 'DUPLICADA' : 'VINCULADA',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: isDuplicated ? AppColors.danger : AppColors.teal,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        related.titulo.isNotEmpty ? related.titulo : 'Incidencia sin título',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right_rounded, size: 16),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            textStyle: const TextStyle(fontSize: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            _showReportContentSheet(
                              context,
                              tipoEntidad: 'INCIDENCIA',
                              idEntidad: widget.incident.idIncidencia,
                              title: 'Sugerir reporte duplicado',
                              preselectedMotive: 'Incidencia duplicada',
                            );
                          },
                          icon: const Icon(Icons.info_outline_rounded, size: 14),
                          label: const Text('Creo que ya fue reportado'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _VoteSheet extends StatefulWidget {
  final IncidentModel incident;

  const _VoteSheet({required this.incident});

  @override
  State<_VoteSheet> createState() => _VoteSheetState();
}

class _VoteSheetState extends State<_VoteSheet> {
  final TextEditingController _observationController = TextEditingController();
  String _selectedVoteType = 'CONFIRMA_EXISTENCIA';

  @override
  void dispose() {
    _observationController.dispose();
    super.dispose();
  }

  Future<void> _submitVote() async {
    final created = await context.read<IncidentsCubit>().createIncidentVote(
      idIncidencia: widget.incident.idIncidencia,
      tipoVoto: _selectedVoteType,
      observacion: _observationController.text,
    );

    if (created && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: BlocBuilder<IncidentsCubit, IncidentsState>(
          builder: (context, state) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.lightGray,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Validar reporte',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ayuda a la comunidad confirmando si este problema es real o si necesita atención.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 16),
                _VoteComposer(
                  selectedVoteType: _selectedVoteType,
                  observationController: _observationController,
                  submitting: state.voteSubmitting,
                  errorMessage: state.voteSubmitMessage,
                  onVoteChanged: (value) {
                    setState(() => _selectedVoteType = value);
                  },
                  onSubmit: _submitVote,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CommentSheet extends StatefulWidget {
  final String idIncidencia;

  const _CommentSheet({required this.idIncidencia});

  @override
  State<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<_CommentSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final created = await context.read<IncidentsCubit>().createIncidentComment(
      idIncidencia: widget.idIncidencia,
      contenido: _controller.text,
    );

    if (created && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: BlocBuilder<IncidentsCubit, IncidentsState>(
          builder: (context, state) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.lightGray,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Agregar comentario',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 16),
                _CommentComposer(
                  controller: _controller,
                  submitting: state.commentSubmitting,
                  errorMessage: state.commentSubmitMessage,
                  onSubmit: _submit,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CompletionSheet extends StatefulWidget {
  final IncidentModel incident;

  const _CompletionSheet({required this.incident});

  @override
  State<_CompletionSheet> createState() => _CompletionSheetState();
}

class _CompletionSheetState extends State<_CompletionSheet> {
  final TextEditingController _observationController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  double? _latitude;
  double? _longitude;
  XFile? _selectedImage;
  bool _locating = false;

  @override
  void dispose() {
    _observationController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMessage('Activa la ubicación para adjuntarla.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showMessage('No tenemos permiso para leer tu ubicación.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (_) {
      _showMessage('No se pudo obtener tu ubicación.');
    } finally {
      if (mounted) {
        setState(() => _locating = false);
      }
    }
  }

  Future<void> _submitConfirmation() async {
    final created = await context
        .read<IncidentsCubit>()
        .createCompletionConfirmation(
          idIncidencia: widget.incident.idIncidencia,
          observacion: _observationController.text,
          latitud: _latitude,
          longitud: _longitude,
          imageAttachment: _selectedImage == null
              ? null
              : IncidentImageAttachment(_selectedImage!),
        );

    if (created && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1800,
      );

      if (image == null) return;

      setState(() => _selectedImage = image);
    } catch (_) {
      _showMessage('No se pudo seleccionar la imagen.');
    }
  }

  void _clearImage() {
    setState(() => _selectedImage = null);
  }

  void _clearLocation() {
    setState(() {
      _latitude = null;
      _longitude = null;
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: BlocBuilder<IncidentsCubit, IncidentsState>(
          builder: (context, state) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.lightGray,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Confirmar completado',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Confirma si esta incidencia ya fue resuelta. Puedes adjuntar fotos y tu ubicación como prueba.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 16),
                _CompletionComposer(
                  observationController: _observationController,
                  latitude: _latitude,
                  longitude: _longitude,
                  selectedImage: _selectedImage,
                  locating: _locating,
                  submitting: state.completionSubmitting,
                  errorMessage: state.completionSubmitMessage,
                  onUseLocation: _useCurrentLocation,
                  onClearLocation: _clearLocation,
                  onPickCamera: () => _pickImage(ImageSource.camera),
                  onPickGallery: () => _pickImage(ImageSource.gallery),
                  onClearImage: _clearImage,
                  onSubmit: _submitConfirmation,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  final IncidentModel incident;

  const _QuickActionsSection({required this.incident});

  void _showVoteSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<IncidentsCubit>(),
        child: _VoteSheet(incident: incident),
      ),
    );
  }

  void _showCommentSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<IncidentsCubit>(),
        child: _CommentSheet(idIncidencia: incident.idIncidencia),
      ),
    );
  }

  void _showCompletionSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<IncidentsCubit>(),
        child: _CompletionSheet(incident: incident),
      ),
    );
  }

  void _showChangeStatusSheet(
    BuildContext context,
    List<IncidentStatusOptionModel> statuses,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return BlocProvider.value(
          value: context.read<IncidentsCubit>(),
          child: _ChangeStatusSheet(incident: incident, statuses: statuses),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final currentUserId = authState is AuthAuthenticated ? authState.user.idUsuario : '';
    final isOwner = currentUserId.isNotEmpty && currentUserId == incident.idUsuarioReporta;

    return BlocBuilder<IncidentsCubit, IncidentsState>(
      builder: (context, state) {
        final following = state.followStatus?.siguiendo == true;
        final availableStatuses = state.statusOptions
            .where((status) => status.codigo != incident.codigoEstado)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                'Acciones rápidas',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.navy,
                    ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _QuickActionChip(
                    icon: following ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                    label: following ? 'Siguiendo' : 'Seguir',
                    onPressed: state.followActionLoading
                        ? null
                        : () {
                            if (following) {
                              context.read<IncidentsCubit>().unfollowIncident(incident.idIncidencia);
                            } else {
                              context.read<IncidentsCubit>().followIncident(incident.idIncidencia);
                            }
                          },
                    isActive: following,
                  ),
                  const SizedBox(width: 8),
                  _QuickActionChip(
                    icon: Icons.how_to_vote_rounded,
                    label: 'Validar',
                    onPressed: () => _showVoteSheet(context),
                  ),
                  const SizedBox(width: 8),
                  _QuickActionChip(
                    icon: Icons.comment_rounded,
                    label: 'Comentar',
                    onPressed: () => _showCommentSheet(context),
                  ),
                  const SizedBox(width: 8),
                  _QuickActionChip(
                    icon: Icons.verified_rounded,
                    label: 'Confirmar completado',
                    onPressed: () => _showCompletionSheet(context),
                  ),
                  const SizedBox(width: 8),
                  _QuickActionChip(
                    icon: Icons.copy_rounded,
                    label: 'Ya reportado',
                    onPressed: () {
                      _showReportContentSheet(
                        context,
                        tipoEntidad: 'INCIDENCIA',
                        idEntidad: incident.idIncidencia,
                        title: 'Sugerir reporte duplicado',
                        preselectedMotive: 'Incidencia duplicada',
                      );
                    },
                  ),
                  if (isOwner && availableStatuses.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _QuickActionChip(
                      icon: Icons.sync_alt_rounded,
                      label: 'Cambiar estado',
                      onPressed: () => _showChangeStatusSheet(context, availableStatuses),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isActive;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onPressed,
      avatar: Icon(
        icon,
        size: 16,
        color: isActive ? AppColors.white : AppColors.teal,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isActive ? AppColors.white : AppColors.navy,
        ),
      ),
      backgroundColor: isActive ? AppColors.teal : AppColors.white,
      side: BorderSide(
        color: isActive ? Colors.transparent : AppColors.lightGray,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}
