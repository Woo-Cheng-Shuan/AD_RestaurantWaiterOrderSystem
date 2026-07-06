import 'package:flutter/material.dart';

import '../models/order.dart';
import '../models/order_item.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';

class OrderDetailPage extends StatelessWidget {
  final RestaurantOrder order;

  const OrderDetailPage({
    super.key,
    required this.order,
  });

  String? _getNextStatus(String currentStatus) {
    final statuses = AppConstants.orderStatuses;
    final index = statuses.indexOf(currentStatus);

    if (index == -1 || index == statuses.length - 1) {
      return null;
    }

    return statuses[index + 1];
  }

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();
    final nextStatus = _getNextStatus(order.status);

    return Scaffold(
      appBar: AppBar(
        title: Text('Table ${order.tableNo}'),
      ),
      body: StreamBuilder<List<OrderItem>>(
        stream: service.getOrderItems(order.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading order items'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text('Status: ${order.status}'),
                    subtitle: Text(
                      'Total: RM ${order.total.toStringAsFixed(2)}',
                    ),
                  ),
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? const Center(child: Text('No items found'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const Icon(Icons.local_pizza),
                              title: Text(item.nameSnapshot),
                              subtitle: Text(
                                'RM ${item.priceSnapshot.toStringAsFixed(2)} x ${item.quantity}',
                              ),
                              trailing: Text(
                                'RM ${item.subtotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (nextStatus != null)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.arrow_forward),
                          label: Text('Move to $nextStatus'),
                          onPressed: () async {
                            await service.updateOrderStatus(
                              order.id,
                              nextStatus,
                            );

                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ),
                    if (order.status == 'Pending') ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.delete),
                          label: const Text('Cancel Order'),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Cancel order?'),
                                content: Text(
                                  'Cancel order for Table ${order.tableNo}?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('No'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Yes, cancel'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await service.deleteOrder(order.id);

                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}