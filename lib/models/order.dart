import 'package:cloud_firestore/cloud_firestore.dart';

class RestaurantOrder {
  final String id;
  final String tableNo;
  final String status;
  final double total;
  final DateTime createdAt;

  RestaurantOrder({
    required this.id,
    required this.tableNo,
    required this.status,
    required this.total,
    required this.createdAt,
  });

  factory RestaurantOrder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return RestaurantOrder(
      id: doc.id,
      tableNo: data['table_no'] ?? '',
      status: data['status'] ?? 'Pending',
      total: (data['total'] ?? 0).toDouble(),
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'table_no': tableNo,
      'status': status,
      'total': total,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}