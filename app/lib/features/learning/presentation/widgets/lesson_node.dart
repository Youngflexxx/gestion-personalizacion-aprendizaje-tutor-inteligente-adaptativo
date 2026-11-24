import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/models/leccion_estado.dart';

/// Nodo de la ruta vertical de aprendizaje con conector y estados visuales.
class LessonNode extends StatelessWidget {
  const LessonNode({
    required this.item,
    required this.index,
    required this.isLast,
    this.onStart,
    super.key,
  });

  final LeccionEstado item;
  final int index;
  final bool isLast;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final estado = item.estado;
    final color = switch (estado) {
      EstadoLeccion.completada => AppColors.success,
      EstadoLeccion.disponible => scheme.primary,
      EstadoLeccion.bloqueada => scheme.onSurfaceVariant,
    };
    final bloqueada = estado == EstadoLeccion.bloqueada;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 58,
            child: Column(
              children: [
                _StatusCircle(estado: estado, color: color, index: index),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 3,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: AppCard(
                padding: const EdgeInsets.all(16),
                color: bloqueada
                    ? scheme.surface.withValues(alpha: 0.6)
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _StatusChip(estado: estado, color: color),
                        const Spacer(),
                        Text(
                          '+${item.leccion.xpRecompensa} XP',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: bloqueada
                                ? scheme.onSurfaceVariant
                                : AppColors.warning,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.leccion.titulo,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: bloqueada
                            ? scheme.onSurfaceVariant
                            : scheme.onSurface,
                      ),
                    ),
                    if (item.leccion.resumenTeorico != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.leccion.resumenTeorico!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (bloqueada)
                      Row(
                        children: [
                          Icon(
                            Icons.lock_rounded,
                            size: 16,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Completa la lección anterior para desbloquear.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${item.ejerciciosCorrectos}/'
                              '${item.ejerciciosTotales} ejercicios',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: onStart,
                            icon: Icon(
                              estado == EstadoLeccion.completada
                                  ? Icons.replay_rounded
                                  : Icons.play_arrow_rounded,
                              size: 18,
                            ),
                            label: Text(
                              estado == EstadoLeccion.completada
                                  ? 'Repetir'
                                  : 'Comenzar',
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCircle extends StatelessWidget {
  const _StatusCircle({
    required this.estado,
    required this.color,
    required this.index,
  });

  final EstadoLeccion estado;
  final Color color;
  final int index;

  @override
  Widget build(BuildContext context) {
    final icon = switch (estado) {
      EstadoLeccion.completada => Icons.check_rounded,
      EstadoLeccion.disponible => Icons.play_arrow_rounded,
      EstadoLeccion.bloqueada => Icons.lock_rounded,
    };

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color, width: 2),
        boxShadow: estado == EstadoLeccion.disponible
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.32),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Icon(icon, color: color, size: 25),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.estado, required this.color});

  final EstadoLeccion estado;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final label = switch (estado) {
      EstadoLeccion.completada => 'Completada',
      EstadoLeccion.disponible => 'Disponible',
      EstadoLeccion.bloqueada => 'Bloqueada',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}
