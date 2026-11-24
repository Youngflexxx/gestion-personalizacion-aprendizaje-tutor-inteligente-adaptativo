import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/error_panel.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../adaptive_engine/domain/adaptive_calculator.dart';
import '../../domain/entities/insignia.dart';
import '../../domain/models/resumen_leccion.dart';

/// Resumen de la sesión: XP, precisión, cambio adaptativo e insignias.
class LessonSummaryScreen extends StatelessWidget {
  const LessonSummaryScreen({
    required this.moduloId,
    required this.resumen,
    super.key,
  });

  final int moduloId;
  final ResumenLeccion? resumen;

  @override
  Widget build(BuildContext context) {
    final data = resumen;
    if (data == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Resumen de la lección'),
          actions: const [ThemeToggleButton(), SizedBox(width: 4)],
        ),
        body: ErrorPanel(
          message: 'No encontramos los datos de esta sesión. Vuelve a la '
              'ruta y abre la lección de nuevo.',
          retryLabel: 'Volver a la ruta',
          onRetry: () => context.go('/module/$moduloId'),
        ),
      );
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final completada = data.leccionCompletada;

    return Scaffold(
      body: SafeArea(
        child: ResponsiveCenter(
          maxWidth: 820,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => context.go('/module/$moduloId'),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  const Spacer(),
                  const ThemeToggleButton(),
                  const SizedBox(width: 4),
                ],
              ),
              _SummaryHero(resumen: data),
              const SizedBox(height: 18),
              _StatsGrid(resumen: data),
              const SizedBox(height: 16),
              _AdaptiveCard(resumen: data),
              if (data.nuevasInsignias.isNotEmpty) ...[
                const SizedBox(height: 16),
                _BadgesCard(insignias: data.nuevasInsignias),
              ],
              const SizedBox(height: 16),
              _AttemptsCard(intentos: data.intentos),
              const SizedBox(height: 22),
              PrimaryButton(
                label:
                    completada ? 'Volver a la ruta' : 'Reintentar lección',
                icon: completada
                    ? Icons.route_rounded
                    : Icons.replay_rounded,
                tone: completada
                    ? AppButtonTone.success
                    : AppButtonTone.primary,
                onPressed: () {
                  if (completada) {
                    context.go('/module/$moduloId');
                  } else {
                    context.go(
                      '/module/$moduloId/lesson/${data.leccion.id}',
                    );
                  }
                },
              ),
              if (completada) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => context.go(
                    '/module/$moduloId/lesson/${data.leccion.id}',
                  ),
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Repetir lección'),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'El intento quedó registrado en el historial local, '
                'equivalente a la tabla intentos_ejercicio del esquema '
                'PostgreSQL.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryHero extends StatelessWidget {
  const _SummaryHero({required this.resumen});

  final ResumenLeccion resumen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completada = resumen.leccionCompletada;
    final colors = completada
        ? const [AppColors.success, Color(0xFF127A4B)]
        : const [AppColors.warning, Color(0xFFC47A05)];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.30),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.30),
                  ),
                ),
                child: Icon(
                  completada
                      ? Icons.emoji_events_rounded
                      : Icons.favorite_border_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      completada
                          ? '¡Lección completada!'
                          : 'Sesión finalizada',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      resumen.leccion.titulo,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${resumen.xpTotal}',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  'XP',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              _HeroTag(
                icon: Icons.track_changes_rounded,
                label:
                    '${(resumen.precision * 100).round()}% precisión',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            completada
                ? 'Has dominado los conceptos de esta micro-lección. '
                    'Tu ruta sigue avanzando.'
                : 'Te quedaste sin vidas antes de completar la lección. '
                    'Reintenta para consolidar los conceptos.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  const _HeroTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.resumen});

  final ResumenLeccion resumen;

  @override
  Widget build(BuildContext context) {
    final delta = resumen.deltaDominio;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 2 : 1;
        const spacing = 12.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        final items = <Widget>[
          _StatCard(
            icon: Icons.bolt_rounded,
            color: AppColors.warning,
            label: 'XP ganado',
            value: '+${resumen.xpTotal}',
            caption:
                'Sesión ${resumen.xpSesion} + bonus ${resumen.xpBonus}',
          ),
          _StatCard(
            icon: Icons.track_changes_rounded,
            color: AppColors.success,
            label: 'Precisión',
            value: '${(resumen.precision * 100).round()}%',
            caption:
                '${resumen.respuestasCorrectas} de '
                '${resumen.respuestasTotales} correctas',
          ),
          _StatCard(
            icon: Icons.school_rounded,
            color: AppColors.primary,
            label: 'Dominio',
            value: '${resumen.dominioAntes.toStringAsFixed(1)} → '
                '${resumen.dominioDespues.toStringAsFixed(1)}',
            caption: '${delta >= 0 ? '+' : ''}'
                '${delta.toStringAsFixed(1)} puntos',
          ),
          _StatCard(
            icon: Icons.tune_rounded,
            color: AppColors.danger,
            label: 'Dificultad',
            value:
                '${resumen.dificultadAntes} → ${resumen.dificultadDespues}',
            caption:
                'Ahora: ${AdaptiveCalculator.difficultyLabel(resumen.dificultadDespues)}',
          ),
        ];

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(width: width, child: item),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.caption,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  caption,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
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

class _AdaptiveCard extends StatelessWidget {
  const _AdaptiveCard({required this.resumen});

  final ResumenLeccion resumen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final delta = resumen.deltaDominio;

    return AppCard(
      color: scheme.primary.withValues(alpha: 0.05),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: scheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ajuste adaptativo',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _mensaje(resumen),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MiniTag(
                      label: 'M ${resumen.dominioAntes.toStringAsFixed(1)} '
                          '→ ${resumen.dominioDespues.toStringAsFixed(1)}',
                      color: delta >= 0
                          ? AppColors.success
                          : AppColors.danger,
                    ),
                    _MiniTag(
                      label:
                          'Dificultad ${resumen.dificultadDespues} · '
                          '${AdaptiveCalculator.difficultyLabel(resumen.dificultadDespues)}',
                      color: scheme.primary,
                    ),
                    if (resumen.vidasRestantes > 0)
                      _MiniTag(
                        label:
                            '${resumen.vidasRestantes} vida(s) restante(s)',
                        color: AppColors.warning,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _mensaje(ResumenLeccion resumen) {
    final delta = resumen.deltaDominio;
    final prefix = resumen.leccionCompletada
        ? ''
        : 'La sesión se cerró antes de completar la lección. ';

    if (delta > 0) {
      return '${prefix}Tu dominio subió '
          '${delta.toStringAsFixed(1)} puntos. El motor fijó la dificultad '
          'en ${resumen.dificultadDespues} '
          '(${AdaptiveCalculator.difficultyLabel(resumen.dificultadDespues)}) '
          'para el próximo ejercicio.';
    }
    if (delta < 0) {
      return '${prefix}Tu dominio bajó '
          '${delta.abs().toStringAsFixed(1)} puntos. El motor reducirá la '
          'dificultad y priorizará el refuerzo.';
    }
    return '${prefix}Tu dominio se mantuvo. El motor conserva la dificultad '
        '${resumen.dificultadDespues}.';
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _BadgesCard extends StatelessWidget {
  const _BadgesCard({required this.insignias});

  final List<Insignia> insignias;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.military_tech_rounded,
                color: AppColors.warning,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Nuevas insignias',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final insignia in insignias)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _badgeIcon(insignia.icono),
                      color: AppColors.warning,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          insignia.nombre,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          insignia.descripcion,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
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

  static IconData _badgeIcon(String? icono) {
    return switch (icono) {
      'flag' => Icons.flag_rounded,
      'local_fire_department' => Icons.local_fire_department_rounded,
      'explore' => Icons.explore_rounded,
      'code' => Icons.code_rounded,
      _ => Icons.military_tech_rounded,
    };
  }
}

class _AttemptsCard extends StatelessWidget {
  const _AttemptsCard({required this.intentos});

  final List<ResumenIntento> intentos;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fact_check_rounded, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tus respuestas',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${intentos.length}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (intentos.isEmpty)
            Text(
              'No se registraron respuestas en esta sesión.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          else
            for (var i = 0; i < intentos.length; i++) ...[
              if (i > 0) const Divider(height: 18),
              _AttemptRow(intento: intentos[i]),
            ],
        ],
      ),
    );
  }
}

class _AttemptRow extends StatelessWidget {
  const _AttemptRow({required this.intento});

  final ResumenIntento intento;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          intento.esCorrecto
              ? Icons.check_circle_rounded
              : Icons.cancel_rounded,
          color: intento.esCorrecto ? AppColors.success : AppColors.danger,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                intento.enunciado,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
              ),
              const SizedBox(height: 2),
              Text(
                'Dificultad ${intento.dificultadAlMomento} · '
                '${intento.tiempoLabel}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
