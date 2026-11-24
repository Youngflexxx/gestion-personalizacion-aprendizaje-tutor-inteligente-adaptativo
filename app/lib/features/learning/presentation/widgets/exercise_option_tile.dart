import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/ejercicio.dart';

/// Opción táctil de un ejercicio con estados seleccionado/correcto/incorrecto.
class ExerciseOptionTile extends StatelessWidget {
  const ExerciseOptionTile({
    required this.option,
    required this.selected,
    required this.verified,
    required this.onTap,
    this.letter,
    this.leadingIcon,
    this.monospace = false,
    super.key,
  });

  final OpcionEjercicio option;
  final bool selected;
  final bool verified;
  final VoidCallback? onTap;
  final String? letter;
  final IconData? leadingIcon;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final Color borderColor;
    final Color background;
    if (verified) {
      if (option.esCorrecta) {
        borderColor = AppColors.success;
        background = AppColors.success.withValues(alpha: 0.12);
      } else if (selected) {
        borderColor = AppColors.danger;
        background = AppColors.danger.withValues(alpha: 0.12);
      } else {
        borderColor = scheme.outlineVariant;
        background = scheme.surface;
      }
    } else if (selected) {
      borderColor = scheme.primary;
      background = scheme.primary.withValues(alpha: 0.10);
    } else {
      borderColor = scheme.outlineVariant;
      background = scheme.surface;
    }

    final highlight = selected || (verified && option.esCorrecta);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: verified ? null : onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: borderColor,
              width: highlight ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              if (letter != null)
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: borderColor.withValues(alpha: 0.14),
                  ),
                  child: Text(
                    letter!,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: borderColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              else if (leadingIcon != null)
                Icon(leadingIcon, size: 24, color: borderColor),
              if (letter != null || leadingIcon != null)
                const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option.textoOpcion,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontFamily: monospace ? 'monospace' : null,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                _trailingIcon,
                size: 22,
                color: _trailingColor(scheme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData get _trailingIcon {
    if (verified && option.esCorrecta) return Icons.check_circle_rounded;
    if (verified && selected && !option.esCorrecta) {
      return Icons.cancel_rounded;
    }
    return selected
        ? Icons.radio_button_checked_rounded
        : Icons.radio_button_unchecked_rounded;
  }

  Color _trailingColor(ColorScheme scheme) {
    if (verified && option.esCorrecta) return AppColors.success;
    if (verified && selected && !option.esCorrecta) return AppColors.danger;
    return selected ? scheme.primary : scheme.outline;
  }
}
