class SyncQueueItem {
  final String id;
  final String shopId;
  final String tableName;
  final String recordId;
  final String action; // 'INSERT', 'UPDATE', 'DELETE'
  final String payloadJson;
  final String createdAt;
  final String status; // 'PENDING', 'PROCESSING', 'FAILED', 'SUCCESS'
  final int retryCount;
  final String? errorMessage;

  SyncQueueItem({
    required this.id,
    required this.shopId,
    required this.tableName,
    required this.recordId,
    required this.action,
    required this.payloadJson,
    required this.createdAt,
    this.status = 'PENDING',
    this.retryCount = 0,
    this.errorMessage,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shop_id': shopId,
      'table_name': tableName,
      'record_id': recordId,
      'action': action,
      'payload_json': payloadJson,
      'created_at': createdAt,
      'status': status,
      'retry_count': retryCount,
      'error_message': errorMessage,
    };
  }

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id'] as String,
      shopId: map['shop_id'] as String,
      tableName: map['table_name'] as String,
      recordId: map['record_id'] as String,
      action: map['action'] as String,
      payloadJson: map['payload_json'] as String,
      createdAt: map['created_at'] as String,
      status: (map['status'] as String?) ?? 'PENDING',
      retryCount: (map['retry_count'] as int?) ?? 0,
      errorMessage: map['error_message'] as String?,
    );
  }

  Map<String, dynamic> toApiJson() {
    return {
      'id': id,
      'tableName': tableName,
      'recordId': recordId,
      'action': action,
      'payloadJson': payloadJson,
      'createdAt': createdAt,
    };
  }
}
