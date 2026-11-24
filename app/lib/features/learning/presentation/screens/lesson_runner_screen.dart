import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/error_panel.dart';
import '../../../../core/widgets/gamified_progress_bar.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../adaptive_engine/domain/adaptive_calculator.dart';
import '../../domain/entities/ejercicio.dart';
import '../controllers/lesson_controller.dart';
import '../providers/learning_providers.dart';
import '../widgets/exercise_option_tile.dart';
import '../widgets/feedback_panel.dart';

/// Pantalla de ejecución de una micro-lección.
class LessonRunnerScreen extends ConsumerStatefulWidget {
  const LessonRunnerScreen({
    required this.usuarioId,
    required this.moduloId,
    required this.leccionId,
    super.key,
  });

  final int usuarioId;
  final int moduloId;
  final int leccionId;

  @override
  ConsumerState<LessonRunnerScreen> createState() =>
      _LessonRunnerScreenState();
}

class _LessonRunnerScreenState extends ConsumerState<LessonRunnerScreen> {
  late final LessonRequest _request;

  @override
  void initState() {
    super.initState();
    _request = LessonRequest(
      usuarioId: widget.usuarioId,
      moduloId: widget.moduloId,
      leccionId: widget.leccionId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = lessonControllerProvider(_request);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);

    ref.listen<LessonState>(provider, (previous, next) {
      final resumen = next.resumen;
      if (resumen != null && previous?.resumen == null && mounted) {
        context.go(
          '/module/${widget.moduloId}/summary',
          extra: resumen,
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Salir de la lección',
          onPressed: _confirmExit,
          icon: const Icon(Icons.close_rounded),
        ),
        title: Text(state.leccion?.titulo ?? 'Lección'),
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 4),
        ],
      ),
      body: _buildBody(
        context,
        state,
        controller,
        () => ref.invalidate(provider),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    LessonState state,
    LessonController controller,
    VoidCallback onRetry,
  ) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = state.error;
    final ejercicio = state.ejercicioActual;

    if (error != null && ejercicio == null) {
      return ErrorPanel(
        message: error,
        retryLabel: 'Reintentar lección',
        onRetry: onRetry,
      );
    }

    if (ejercicio == null) {
      return const Center(
        child: Text('No hay ejercicios disponibles para esta lección.'),
      );
    }

    return _LessonContent(
      state: state,
      ejercicio: ejercicio,
      controller: controller,
      error: error,
    );
  }

  Future<void> _confirmExit() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Salir de la lección?'),
        content: const Text(
          'Los intentos ya registrados se conservan, pero la lección quedará '
          'incompleta hasta que la termines.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Seguir practicando'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    if (shouldExit == true && mounted) {
      context.go('/module/${widget.moduloId}');
    }
  }
}

class _LessonContent extends StatelessWidget {
  const _LessonContent({
    required this.state,
    required this.ejercicio,
    required this.controller,
    this.error,
  });

  final LessonState state;
  final Ejercicio ejercicio;
  final LessonController controller;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fragmento = _fragmentoConSeleccion(ejercicio, state);
    final errorMessage = error;

    return ResponsiveCenter(
      maxWidth: 760,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _LessonHeader(state: state),
          const SizedBox(height: 16),
          if (errorMessage != null) ...[
            _InlineError(message: errorMessage),
            const SizedBox(height: 12),
          ],
          if (state.refuerzoActivo && !state.respuestaVerificada) ...[
            const _ReinforcementBanner(),
            const SizedBox(height: 12),
          ],
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetaChip(
                      icon: Icons.category_rounded,
                      label: ejercicio.tipo.label,
                    ),
                    _MetaChip(
                      icon: Icons.signal_cellular_alt_rounded,
                      label: 'Nivel ${ejercicio.nivelDificultad} · '
                          '${AdaptiveCalculator.difficultyLabel(ejercicio.nivelDificultad)}',
                      color: scheme.primary,
                    ),
                    if (state.refuerzoActivo)
                      const _MetaChip(
                        icon: Icons.fitness_center_rounded,
                        label: 'Refuerzo',
                        color: AppColors.warning,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  ejercicio.enunciado,
                  style: theme.textTheme.titleLarge?.copyWith(height: 1.3),
                ),
                if (fragmento != null) ...[
                  const SizedBox(height: 14),
                  _CodeBlock(text: fragmento),
                ],
                const SizedBox(height: 18),
                ..._buildOptions(context),
              ],
            ),
          ),
          if (state.respuestaVerificada) ...[
            const SizedBox(height: 14),
            FeedbackPanel(
              esCorrecta: state.esCorrecta == true,
              explicacion: ejercicio.explicacionPedagogica,
              decision: state.ultimaDecision,
              vidas: state.vidas,
            ),
          ],
          const SizedBox(height: 20),
          if (state.respuestaVerificada)
            PrimaryButton(
              label: state.vidas <= 0 || state.esUltimoEjercicio
                  ? 'Ver resumen'
                  : 'Continuar',
              icon: state.vidas <= 0 || state.esUltimoEjercicio
                  ? Icons.insights_rounded
                  : Icons.arrow_forward_rounded,
              tone: state.esCorrecta == true
                  ? AppButtonTone.success
                  : AppButtonTone.primary,
              onPressed: () {
                controller.continuar();
              },
            )
          else
            PrimaryButton(
              label: 'Comprobar',
              icon: Icons.check_rounded,
              onPressed: state.puedeComprobar
                  ? () {
                      controller.comprobarRespuesta();
                    }
                  : null,
            ),
          const SizedBox(height: 10),
          Text(
            'Intento '
            '${state.respondidos + (state.respuestaVerificada ? 0 : 1)} '
            'de ${state.totalEjercicios} · ${state.xpSesion} XP en esta sesión',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOptions(BuildContext context) {
    final opciones = ejercicio.opciones;
    if (opciones.isEmpty) {
      return [
        Text(
          'Este ejercicio no tiene opciones configuradas.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
        ),
      ];
    }

    final esVerdaderoFalso =
        ejercicio.tipo == TipoEjercicio.trueFalse && opciones.length == 2;

    if (esVerdaderoFalso) {
      return [
        Row(
          children: [
            Expanded(
              child: ExerciseOptionTile(
                option: opciones[0],
                selected: state.opcionSeleccionada == opciones[0].id,
                verified: state.respuestaVerificada,
                onTap: () => controller.seleccionarOpcion(opciones[0].id),
                leadingIcon: Icons.check_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ExerciseOptionTile(
                option: opciones[1],
                selected: state.opcionSeleccionada == opciones[1].id,
                verified: state.respuestaVerificada,
                onTap: () => controller.seleccionarOpcion(opciones[1].id),
                leadingIcon: Icons.close_rounded,
              ),
            ),
          ],
        ),
      ];
    }

    return [
      for (var i = 0; i < opciones.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ExerciseOptionTile(
            option: opciones[i],
            letter: String.fromCharCode(65 + i),
            selected: state.opcionSeleccionada == opciones[i].id,
            verified: state.respuestaVerificada,
            onTap: () => controller.seleccionarOpcion(opciones[i].id),
            monospace: ejercicio.tipo == TipoEjercicio.fillSql,
          ),
        ),
    ];
  }

  static String? _fragmentoConSeleccion(
    Ejercicio ejercicio,
    LessonState state,
  ) {
    final fragmento = ejercicio.fragmentoCodigo;
    if (fragmento == null) return null;
    final seleccionada = state.opcionSeleccionada;
    if (seleccionada == null) return fragmento;
    for (final opcion in ejercicio.opciones) {
      if (opcion.id == seleccionada) {
        return fragmento.replaceAll('___', opcion.textoOpcion);
      }
    }
    return fragmento;
  }
}

class _LessonHeader extends StatelessWidget {
  const _LessonHeader({required this.state});

  final LessonState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dificultad =
        state.ejercicioActual?.nivelDificultad ?? state.dificultadObjetivo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${state.respondidos}/${state.totalEjercicios}',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GamifiedProgressBar(value: state.progreso),
            ),
            const SizedBox(width: 10),
            _LivesIndicator(vidas: state.vidas),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MetaChip(
              icon: Icons.bolt_rounded,
              label: '${state.xpSesion} XP',
              color: AppColors.warning,
            ),
            _MetaChip(
              icon: Icons.tune_rounded,
              label:
                  'Nivel $dificultad · ${AdaptiveCalculator.difficultyLabel(dificultad)}',
              color: scheme.primary,
            ),
            if (state.erroresConsecutivos > 0)
              _MetaChip(
                icon: Icons.error_outline_rounded,
                label:
                    '${state.erroresConsecutivos} error(es) seguido(s)',
                color: AppColors.danger,
              ),
          ],
        ),
      ],
    );
  }
}

class _LivesIndicator extends StatelessWidget {
  const _LivesIndicator({required this.vidas});

  final int vidas;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 2),
            child: Icon(
              i < vidas
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              size: 20,
              color: i < vidas ? AppColors.danger : scheme.outline,
            ),
          ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = color ?? theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.dangerSoftDark : AppColors.dangerSoftLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: AppColors.danger.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.danger,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReinforcementBanner extends StatelessWidget {
  const _ReinforcementBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isDark ? AppColors.warningSoftDark : AppColors.warningSoftLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.fitness_center_rounded,
            color: AppColors.warning,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Refuerzo activo: repetimos el concepto con una dificultad '
              'menor para consolidarlo antes de avanzar.',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF14141D),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            height: 1.5,
            color: Color(0xFFE8E8F0),
          ),
        ),
      ),
    );
  }
}
