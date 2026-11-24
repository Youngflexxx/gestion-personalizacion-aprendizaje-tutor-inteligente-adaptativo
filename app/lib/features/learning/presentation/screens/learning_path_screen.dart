import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/error_panel.dart';
import '../../../../core/widgets/gamified_progress_bar.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../../adaptive_engine/domain/adaptive_calculator.dart';
import '../../../auth/presentation/providers/session_providers.dart';
import '../../domain/models/module_overview.dart';
import '../providers/learning_providers.dart';
import '../widgets/lesson_node.dart';

/// Ruta de aprendizaje del módulo: encabezado gamificado + mapa vertical.
class LearningPathScreen extends ConsumerWidget {
  const LearningPathScreen({required this.moduloId, super.key});

  final int moduloId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final overview = ref.watch(moduleOverviewProvider(moduloId));
    final student = ref
        .watch(currentStudentProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          student == null
              ? 'Ruta de aprendizaje'
              : 'Hola, ${_firstName(student.nombreCompleto)}',
        ),
        actions: [
          IconButton(
            tooltip: 'Cambiar de perfil',
            onPressed: () {
              ref.read(selectedStudentIdProvider.notifier).state = null;
              context.go('/');
            },
            icon: const Icon(Icons.switch_account_rounded),
          ),
          IconButton(
            tooltip: 'Actualizar datos',
            onPressed: () => ref.invalidate(moduleOverviewProvider(moduloId)),
            icon: const Icon(Icons.refresh_rounded),
          ),
          const ThemeToggleButton(),
          const SizedBox(width: 4),
        ],
      ),
      body: overview.when(
        data: (data) => RefreshIndicator(
          onRefresh: () async {
            try {
              ref.invalidate(moduleOverviewProvider(moduloId));
              await ref.read(moduleOverviewProvider(moduloId).future);
            } on Object {
              // El error se refleja en el AsyncValue del provider.
            }
          },
          child: ResponsiveCenter(
            maxWidth: 860,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                _ModuleHeader(
                  data: data,
                  studentName: student?.nombreCompleto,
                ),
                const SizedBox(height: 16),
                _ProgressCard(data: data),
                const SizedBox(height: 26),
                Text('Tu ruta', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  'Completa las micro-lecciones en orden. Cada una ajusta tu '
                  'dominio y desbloquea la siguiente.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < data.lecciones.length; i++)
                  LessonNode(
                    item: data.lecciones[i],
                    index: i,
                    isLast: i == data.lecciones.length - 1,
                    onStart: data.lecciones[i].puedeAbrir
                        ? () => context.push(
                              '/module/$moduloId/lesson/'
                              '${data.lecciones[i].leccion.id}',
                            )
                        : null,
                  ),
                const SizedBox(height: 20),
                const _AdaptiveInfoCard(),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ErrorPanel(
          message: '$error',
          onRetry: () => ref.invalidate(moduleOverviewProvider(moduloId)),
        ),
      ),
    );
  }

  static String _firstName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return fullName;
    return parts.first;
  }
}

class _ModuleHeader extends StatelessWidget {
  const _ModuleHeader({required this.data, this.studentName});

  final ModuleOverview data;
  final String? studentName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF3839B5)],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.30),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.storage_rounded,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'MÓDULO ${data.modulo.orden} · '
                  '${data.modulo.activo ? 'ACTIVO' : 'INACTIVO'}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            data.modulo.titulo,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.modulo.descripcion,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroChip(
                icon: Icons.bolt_rounded,
                label: '${data.gamificacion.xpTotal} XP',
              ),
              _HeroChip(
                icon: Icons.local_fire_department_rounded,
                label: '${data.gamificacion.rachaDiasActual} días de racha',
              ),
              _HeroChip(
                icon: Icons.military_tech_rounded,
                label: 'Nivel ${data.gamificacion.nivelActual}',
              ),
            ],
          ),
          if (studentName != null) ...[
            const SizedBox(height: 12),
            Text(
              'Sesión de $studentName',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
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

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.data});

  final ModuleOverview data;

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
              Expanded(
                child: Text(
                  'Dominio del módulo',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${data.progreso.nivelDominio.toStringAsFixed(1)}%',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GamifiedProgressBar(
            value: data.progreso.nivelDominio / 100,
            color: AppColors.success,
          ),
          const SizedBox(height: 8),
          Text(
            'Dificultad actual: ${data.progreso.dificultadActual} · '
            '${AdaptiveCalculator.difficultyLabel(data.progreso.dificultadActual)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const Divider(height: 28),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Lecciones completadas',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${data.completadas} de ${data.totalLecciones}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GamifiedProgressBar(value: data.porcentajeCompletado),
        ],
      ),
    );
  }
}

class _AdaptiveInfoCard extends StatelessWidget {
  const _AdaptiveInfoCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

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
                  'Ajuste en tiempo real',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cada respuesta actualiza tu dominio M (0–100) y la '
                  'dificultad del siguiente ejercicio. Dos errores seguidos '
                  'activan un refuerzo y bajan la dificultad.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.45,
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
