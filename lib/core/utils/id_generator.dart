import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

/// Generates offline-safe, time-sortable UUIDv7 primary keys and UUIDv4
/// client idempotency tokens.
@lazySingleton
final class IdGenerator {
  IdGenerator() : _uuid = const Uuid();

  final Uuid _uuid;

  String nextEntityId() => _uuid.v7();

  String nextRequestId() => _uuid.v4();
}
