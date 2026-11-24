import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../adaptive_engine/domain/adaptive_calculator.dart';

/// Retroalimentación inmediata + explicación pedagógica + ajuste adaptativo.
class FeedbackPanel extends StatelessWidget {
  const FeedbackPanel({
    required this.esCorrecta,
    required this.explicacion,
    required this.decision,
    required this.vidas,
    super.key,
  });

  final bool esCorrecta;
  final String explicacion;
  final AdaptiveDecision? decision;
  final int vidas;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final color = esCorrecta ? AppColors.success : AppColors.danger;
    final soft = esCorrecta
        ? (isDark ? AppColors.successSoftDark : AppColors.successSoftLight)
        : (isDark ? AppColors.dangerSoftDark : AppColors.dangerSoftLight);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                esCorrecta
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                esCorrecta ? '¡Correcto!' : 'Casi... revisa la explicación',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(explicacion, style: theme.textTheme.bodyMedium),
          if (decision != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FeedbackChip(
                  label:
                      'Dominio ${_signed(decision!.masteryDelta)} → '
                      '${decision!.newMastery.toStringAsFixed(1)}',
                  color: color,
                ),
                _FeedbackChip(
                  label:
                      'Dificultad ${decision!.targetDifficulty} · '
                      '${decision!.difficultyLabel}',
                  color: scheme.primary,
                ),
                if (decision!.isFast)
                  const _FeedbackChip(
                    label: 'Bonus por fluidez',
                    color: AppColors.warning,
                  ),
              ],
            ),
            if (decision!.needsReinforcement) ...[
              const SizedBox(height: 10),
              Text(
                'Dos errores consecutivos: activamos un ejercicio de '
                'refuerzo y bajamos la dificultad para consolidar el concepto.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
          ],
          if (vidas <= 0) ...[
            const SizedBox(height: 10),
            Text(
              'Te quedaste sin vidas. Puedes ver el resumen y reintentar '
              'la lección cuando quieras.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _signed(double value) {
    final sign = value > 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(1)}';
  }
}

class _FeedbackChip extends StatelessWidget {
  const _FeedbackChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
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
