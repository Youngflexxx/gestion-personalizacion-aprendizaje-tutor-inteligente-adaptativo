import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/gamified_progress_bar.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/stat_pill.dart';
import '../../../adaptive_engine/domain/adaptive_calculator.dart';
import '../../../learning/presentation/providers/learning_providers.dart';
import '../../domain/entities/usuario.dart';

/// Tarjeta de acceso rápido a un estudiante de prueba.
///
/// Muestra el estado real del seed (XP, racha y dominio) y evita cualquier
/// flujo de autenticación para la demostración del vertical slice.
class StudentProfileCard extends ConsumerWidget {
  const StudentProfileCard({
    required this.usuario,
    required this.onEnter,
    super.key,
  });

  final Usuario usuario;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final gamificacion = ref
        .watch(studentGamificationProvider(usuario.id))
        .maybeWhen(data: (value) => value, orElse: () => null);
    final progreso = ref
        .watch(
          studentProgressProvider(
            (usuarioId: usuario.id, moduloId: AppConfig.primerModuloId),
          ),
        )
        .maybeWhen(data: (value) => value, orElse: () => null);

    final dominio = progreso?.nivelDominio ?? 20;
    final dificultad = progreso?.dificultadActual ?? 1;
    final etiqueta = gamificacion == null
        ? null
        : (gamificacion.xpTotal > 0 ? 'Con progreso' : 'Desde cero');

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primary,
                      AppColors.primaryLight.withValues(alpha: 0.9),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  usuario.iniciales,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usuario.nombreCompleto,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      usuario.correo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (etiqueta != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: (gamificacion!.xpTotal > 0
                            ? AppColors.success
                            : scheme.primary)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    etiqueta,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: gamificacion.xpTotal > 0
                          ? AppColors.success
                          : scheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatPill(
                icon: Icons.bolt_rounded,
                label: 'XP',
                value: '${gamificacion?.xpTotal ?? 0}',
                color: AppColors.warning,
              ),
              StatPill(
                icon: Icons.local_fire_department_rounded,
                label: 'Racha',
                value: '${gamificacion?.rachaDiasActual ?? 0} d',
                color: AppColors.danger,
              ),
              StatPill(
                icon: Icons.school_rounded,
                label: 'Dominio',
                value: '${dominio.toStringAsFixed(0)}%',
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 14),
          GamifiedProgressBar(
            value: dominio / 100,
            color: AppColors.success,
          ),
          const SizedBox(height: 6),
          Text(
            'Módulo 1 · Dificultad $dificultad '
            '(${AdaptiveCalculator.difficultyLabel(dificultad)})',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Entrar como estudiante de prueba',
            icon: Icons.arrow_forward_rounded,
            onPressed: onEnter,
          ),
        ],
      ),
    );
  }
}
