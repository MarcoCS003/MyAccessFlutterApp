import 'package:cliente_flutter_myaccess/features/notifications/models/notification_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationItem.fromFcm', () {
    test('payload canónico (event/timestamp) se comporta como siempre', () {
      final item = NotificationItem.fromFcm({
        'student_id': '1',
        'student_name': 'Juan Pérez',
        'event': 'check_in',
        'timestamp': '2026-06-29T08:00:00.000Z',
        'type': 'attendance',
      });

      expect(item.id, '1_check_in_2026-06-29T08:00:00.000Z');
      expect(item.event, 'check_in');
      expect(item.studentId, 1);
      expect(item.studentName, 'Juan Pérez');
      expect(
        item.timestamp,
        DateTime.parse('2026-06-29T08:00:00.000Z').toLocal(),
      );
    });

    test('payload real del backend: attendance_type exit + recorded_at', () {
      // Formato exacto documentado en docs/reporte_notificaciones_fcm.md.
      final item = NotificationItem.fromFcm({
        'type': 'student_attendance',
        'student_id': '10',
        'attendance_type': 'exit',
        'recorded_at': '2026-07-18T14:32:00-06:00',
      });

      expect(item.event, 'check_out');
      expect(item.studentId, 10);
      expect(item.type, 'student_attendance');
      // El timestamp viene del payload, no de DateTime.now().
      expect(
        item.timestamp,
        DateTime.parse('2026-07-18T14:32:00-06:00').toLocal(),
      );
      // Id único por evento: la deduplicación vuelve a funcionar.
      expect(item.id, '10_exit_2026-07-18T14:32:00-06:00');
    });

    test('attendance_type entry se normaliza a check_in', () {
      final item = NotificationItem.fromFcm({
        'type': 'student_attendance',
        'student_id': '10',
        'attendance_type': 'entry',
        'recorded_at': '2026-07-18T07:55:00-06:00',
      });

      expect(item.event, 'check_in');
    });

    test('variantes de salida se normalizan a check_out', () {
      for (final raw in ['exit', 'salida', 'check_out', 'EXIT']) {
        final item = NotificationItem.fromFcm({
          'student_id': '1',
          'attendance_type': raw,
          'recorded_at': '2026-07-18T14:32:00-06:00',
        });
        expect(item.event, 'check_out', reason: 'variante: $raw');
      }
    });

    test('entrada y salida del mismo alumno generan ids distintos', () {
      // Regresión: antes el id quedaba '{student_id}_null_null' para todos
      // los eventos y la deduplicación descartaba la salida.
      final entrada = NotificationItem.fromFcm({
        'type': 'student_attendance',
        'student_id': '10',
        'attendance_type': 'entry',
        'recorded_at': '2026-07-18T07:55:00-06:00',
      });
      final salida = NotificationItem.fromFcm({
        'type': 'student_attendance',
        'student_id': '10',
        'attendance_type': 'exit',
        'recorded_at': '2026-07-18T14:32:00-06:00',
      });

      expect(entrada.id, isNot(salida.id));
    });

    test('sin student_name cae en Alumno', () {
      final item = NotificationItem.fromFcm({
        'type': 'student_attendance',
        'student_id': '10',
        'attendance_type': 'exit',
        'recorded_at': '2026-07-18T14:32:00-06:00',
      });

      expect(item.studentName, 'Alumno');
      expect(item.title, 'Salida registrada');
    });

    test('payload con notification_id y person_name del backend', () {
      final item = NotificationItem.fromFcm({
        'notification_id': '456',
        'type': 'student_attendance',
        'event': 'check_out',
        'student_id': '10',
        'person_name': 'Pedrito Perez',
        'recorded_at': '2026-08-01T14:32:00-06:00',
      });

      expect(item.backendId, 456);
      expect(item.studentName, 'Pedrito Perez');
      expect(item.event, 'check_out');
      expect(item.studentId, 10);
    });
  });

  group('NotificationItem.fromSyncApi', () {
    test('mapea respuesta del endpoint sync', () {
      final item = NotificationItem.fromSyncApi({
        'id': 789,
        'type': 'attendance',
        'event': 'check_in',
        'student_id': 5,
        'student_name': 'María López',
        'timestamp': '2026-08-01T07:30:00-06:00',
      });

      expect(item.backendId, 789);
      expect(item.type, 'attendance');
      expect(item.event, 'check_in');
      expect(item.studentId, 5);
      expect(item.studentName, 'María López');
      expect(
        item.timestamp,
        DateTime.parse('2026-08-01T07:30:00-06:00').toLocal(),
      );
      expect(item.id, '5_check_in_${item.timestamp.toIso8601String()}');
    });

    test('mapea teacher_id cuando no hay student_id', () {
      final item = NotificationItem.fromSyncApi({
        'id': 100,
        'type': 'teacher_attendance',
        'event': 'check_out',
        'teacher_id': '20',
        'student_name': 'Profesor García',
        'timestamp': '2026-08-01T15:00:00-06:00',
      });

      expect(item.backendId, 100);
      expect(item.studentId, 20);
      expect(item.type, 'teacher_attendance');
    });

    test('student_id como string se convierte a int', () {
      final item = NotificationItem.fromSyncApi({
        'id': 101,
        'type': 'attendance',
        'event': 'check_in',
        'student_id': '7',
        'student_name': 'Luis Hernández',
        'timestamp': '2026-08-01T08:00:00-06:00',
      });

      expect(item.studentId, 7);
    });
  });
}
