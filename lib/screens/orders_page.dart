import 'package:flutter/material.dart';

import '../models/order.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';
import 'new_order_page.dart';
import 'order_detail_page.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final _service = FirestoreService();
  String _selectedStatus = 'Pending';

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Pending':
        return Icons.hourglass_bottom;
      case 'Preparing':
        return Icons.restaurant;
      case 'Served':
        return Icons.room_service;
      case 'Paid':
        return Icons.payments;
      default:
        return Icons.receipt_long;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧾 Orders'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 64,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: AppConstants.orderStatuses.map((status) {
                final selected = _selectedStatus == status;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: Icon(
                      _getStatusIcon(status),
                      size: 18,
                      color: selected ? Colors.white : Colors.deepOrange,
                    ),
                    label: Text(status),
                    selected: selected,
                    selectedColor: Colors.deepOrange,
                    backgroundColor: Colors.orange.shade50,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.deepOrange,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _selectedStatus = status;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<RestaurantOrder>>(
              stream: _service.getOrders(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading orders'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final orders = snapshot.data!
                    .where((order) => order.status == _selectedStatus)
                    .toList();

                if (orders.isEmpty) {
                  return Center(
                    child: Text('No $_selectedStatus orders'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.shade100,
                          child: Icon(
                            _getStatusIcon(order.status),
                            color: Colors.deepOrange,
                          ),
                        ),
                        title: Text(
                          'Table ${order.tableNo}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${order.status} • RM ${order.total.toStringAsFixed(2)}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrderDetailPage(order: order),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_circle),
        label: const Text('New Order'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const NewOrderPage(),
            ),
          );
        },
      ),
    );
  }
}