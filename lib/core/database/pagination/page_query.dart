import 'package:flutter/foundation.dart';

/// Standard offset-based SQLite pagination request for searchable lists.
@immutable
final class PageRequest {
  const PageRequest({
    this.limit = 50,
    this.offset = 0,
    this.searchQuery,
  }) : assert(limit > 0),
       assert(offset >= 0);

  final int limit;
  final int offset;
  final String? searchQuery;
}

/// Keyset/cursor pagination request for append-only high-volume ledgers
/// (`stock_movements`, `audit_logs`) avoiding O(N) SQLite `OFFSET` scans.
@immutable
final class CursorPageRequest {
  const CursorPageRequest({
    this.limit = 50,
    this.cursorTransactionAt,
    this.cursorId,
  }) : assert(limit > 0);

  final int limit;
  final int? cursorTransactionAt;
  final String? cursorId;
}

/// Immutable paginated query result with exact total/hasMore metadata.
@immutable
final class PagedResult<T> {
  const PagedResult({
    required this.items,
    required this.totalCount,
    required this.hasMore,
    this.nextCursorTransactionAt,
    this.nextCursorId,
  });

  final List<T> items;
  final int totalCount;
  final bool hasMore;
  final int? nextCursorTransactionAt;
  final String? nextCursorId;
}
