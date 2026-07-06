import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/menu_item.dart';
import '../models/order.dart';
import '../models/order_item.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collections
  CollectionReference get _menuItems => _db.collection('menu_items');
  CollectionReference get _orders => _db.collection('orders');
  CollectionReference get _orderItems => _db.collection('order_items');

  // ================= MENU CRUD =================

  Stream<List<MenuItem>> getMenuItems() {
    return _menuItems.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return MenuItem.fromFirestore(doc);
      }).toList();
    });
  }

  Future<void> addMenuItem(MenuItem item) async {
    await _menuItems.add(item.toMap());
  }

  Future<void> updateMenuItem(MenuItem item) async {
    await _menuItems.doc(item.id).update(item.toMap());
  }

  Future<void> deleteMenuItem(String id) async {
    await _menuItems.doc(id).delete();
  }

  Future<void> toggleMenuAvailability(String id, bool available) async {
    await _menuItems.doc(id).update({
      'available': available,
    });
  }

  // ================= ORDER CRUD =================

  Stream<List<RestaurantOrder>> getOrders() {
    return _orders
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return RestaurantOrder.fromFirestore(doc);
      }).toList();
    });
  }

  Future<String> createOrder({
    required String tableNo,
    required double total,
    required List<OrderItem> items,
  }) async {
    final orderRef = await _orders.add({
      'table_no': tableNo,
      'status': 'Pending',
      'total': total,
      'created_at': Timestamp.now(),
    });

    for (final item in items) {
      await _orderItems.add({
        'order_id': orderRef.id,
        'menu_item_id': item.menuItemId,
        'name_snapshot': item.nameSnapshot,
        'price_snapshot': item.priceSnapshot,
        'quantity': item.quantity,
      });
    }

    return orderRef.id;
  }

  Stream<List<OrderItem>> getOrderItems(String orderId) {
    return _orderItems
        .where('order_id', isEqualTo: orderId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return OrderItem.fromFirestore(doc);
      }).toList();
    });
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _orders.doc(orderId).update({
      'status': status,
    });
  }

  Future<void> deleteOrder(String orderId) async {
    final itemsSnapshot =
        await _orderItems.where('order_id', isEqualTo: orderId).get();

    for (final doc in itemsSnapshot.docs) {
      await doc.reference.delete();
    }

    await _orders.doc(orderId).delete();
  }
}