import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failures.dart';
import '../../../services/api_service.dart';
import '../../notifications/models/notification_item.dart';
import '../../notifications/providers/notification_provider.dart';
import '../models/child.dart';
import '../models/timeline_event.dart';

final childrenProvider =
    StateNotifierProvider<ChildrenNotifier, AsyncValue<List<Child>>>((ref) {
      return ChildrenNotifier();
    });

bool _isToday(DateTime d) {
  final now = DateTime.now();
  return d.year == now.year && d.month == now.month && d.day == now.day;
}

/// ÚNICO provider que las pantallas usan para mostrar hijos: roster del
/// backend (cargado una sola vez) + estado calculado desde la BD local
/// de notificaciones. No genera peticiones extra al backend.
final childrenWithActivityProvider = Provider<AsyncValue<List<Child>>>((ref) {
  final childrenAsync = ref.watch(childrenProvider);
  final notifications = ref.watch(notificationProvider);

  // Último evento por alumno, calculado en memoria desde la BD local.
  final latest = <int, NotificationItem>{};
  for (final n in notifications) {
    final prev = latest[n.studentId];
    if (prev == null || n.timestamp.isAfter(prev.timestamp)) {
      latest[n.studentId] = n;
    }
  }

  return childrenAsync.whenData((children) {
    return children.map((child) {
      final event = latest[child.id];
      if (event == null) return child;
      final isEntry = event.event == 'check_in';
      final isToday = _isToday(event.timestamp);
      debugPrint(
        '[OVERLAY] child=${child.id} eventStudent=${event.studentId} '
        'event=${event.event} ts=${event.timestamp} isToday=$isToday',
      );
      if (isToday) {
        // Evento de hoy: define estado + texto + hora.
        return child.copyWith(
          status: isEntry ? 'inside' : 'outside',
          lastEvent: isEntry ? 'Última entrada' : 'Última salida',
          lastEventTime: event.timestamp,
        );
      }
      // Evento de días anteriores: NO cambia el estado, pero si el backend
      // no trae último evento, el card muestra el último de la BD local.
      if (child.lastEvent == null) {
        return child.copyWith(
          lastEvent: isEntry ? 'Última entrada' : 'Última salida',
          lastEventTime: event.timestamp,
        );
      }
      return child;
    }).toList();
  });
});

/// Historial de accesos del alumno construido desde la BD local de
/// notificaciones (el backend no expone endpoint de asistencias).
final childTimelineProvider = FutureProvider.family<List<TimelineEvent>, int>((
  ref,
  childId,
) {
  final notifications = ref.watch(notificationProvider);
  final events =
      notifications
          .where((n) => n.studentId == childId)
          .map(
            (n) => TimelineEvent(
              id: n.id.hashCode,
              type: n.event,
              recordedAt: n.timestamp,
              location: n.location,
              studentId: n.studentId,
            ),
          )
          .toList()
        ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
  return events;
});

class ChildrenNotifier extends StateNotifier<AsyncValue<List<Child>>> {
  ChildrenNotifier({ApiService? apiService})
    : _apiService = apiService ?? ApiService(),
      super(const AsyncValue.loading());

  /// Inicia la carga de hijos. Se llama explícitamente desde
  /// [MainNavigationScreen] para evitar peticiones automáticas antes de que
  /// el usuario esté autenticado.
  Future<void> initialize() => loadChildren();

  final ApiService _apiService;

  Future<void> loadChildren() async {
    state = const AsyncValue.loading();

    try {
      debugPrint('[CHILDREN] Loading children from /api/user...');
      final response = await _apiService.get('/user');
      debugPrint('[CHILDREN] /api/user response: $response');
      final data = response as Map<String, dynamic>;
      final students = data['students'] as List<dynamic>? ?? [];
      final children = students
          .map((e) => Child.fromJson(e as Map<String, dynamic>))
          .toList();

      await _saveToHive(children);
      state = AsyncValue.data(children);
    } catch (e) {
      final cached = await _loadFromHive();
      if (cached.isNotEmpty) {
        state = AsyncValue.data(cached);
      } else if (e is Failure) {
        state = AsyncValue.error(e, StackTrace.current);
      } else {
        state = AsyncValue.error(
          ServerFailure('Error al cargar hijos: ${e.toString()}'),
          StackTrace.current,
        );
      }
    }
  }

  Future<void> linkChild(String code) async {
    final previousState = state;

    try {
      await _apiService.post('/vincular-alumno', data: {'codigo_alumno': code});

      // El backend no devuelve el estudiante vinculado, así que refrescamos
      // la lista completa desde /api/user para obtener los datos actualizados.
      await loadChildren();
    } catch (e) {
      state = previousState;
      if (e is Failure) {
        rethrow;
      }
      throw ServerFailure('Error al vincular alumno: ${e.toString()}');
    }
  }

  Future<void> unlinkChild(String code) async {
    final previousState = state;

    try {
      await _apiService.post(
        '/desvincular-alumno',
        data: {'codigo_alumno': code},
      );
      await loadChildren();
    } catch (e) {
      state = previousState;
      if (e is Failure) {
        rethrow;
      }
      throw ServerFailure('Error al desvincular alumno: ${e.toString()}');
    }
  }

  Future<void> _saveToHive(List<Child> children) async {
    try {
      final box = Hive.box(AppConstants.childrenBox);
      await box.put('items', children.map((c) => c.toJson()).toList());
    } catch (e) {
      debugPrint('Error saving children to Hive: $e');
    }
  }

  Future<List<Child>> _loadFromHive() async {
    try {
      final box = Hive.box(AppConstants.childrenBox);
      final items = box.get('items', defaultValue: <Map<dynamic, dynamic>>[]);
      return (items as List)
          .map((e) => Child.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('Error loading children from Hive: $e');
      return [];
    }
  }
}
