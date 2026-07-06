import 'package:flutter/material.dart';

import '../models/menu_item.dart';
import '../models/order_item.dart';
import '../services/firestore_service.dart';

class NewOrderPage extends StatefulWidget {
  const NewOrderPage({super.key});

  @override
  State<NewOrderPage> createState() => _NewOrderPageState();
}

class _NewOrderPageState extends State<NewOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final _tableController = TextEditingController();
  final _service = FirestoreService();

  final Map<String, int> _quantities = {};
  bool _isSaving = false;

  @override
  void dispose() {
    _tableController.dispose();
    super.dispose();
  }

  double _calculateTotal(List<MenuItem> menuItems) {
    double total = 0;

    for (final item in menuItems) {
      final qty = _quantities[item.id] ?? 0;
      total += item.price * qty;
    }

    return total;
  }

  Future<void> _saveOrder(List<MenuItem> menuItems) async {
    if (!_formKey.currentState!.validate()) return;

    final selectedItems = menuItems.where((item) {
      return (_quantities[item.id] ?? 0) > 0;
    }).toList();

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one item')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final orderItems = selectedItems.map((item) {
      return OrderItem(
        id: '',
        orderId: '',
        menuItemId: item.id,
        nameSnapshot: item.name,
        priceSnapshot: item.price,
        quantity: _quantities[item.id]!,
      );
    }).toList();

    await _service.createOrder(
      tableNo: _tableController.text.trim(),
      total: _calculateTotal(menuItems),
      items: orderItems,
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _increaseQty(String itemId) {
    setState(() {
      _quantities[itemId] = (_quantities[itemId] ?? 0) + 1;
    });
  }

  void _decreaseQty(String itemId) {
    setState(() {
      final current = _quantities[itemId] ?? 0;
      if (current > 0) {
        _quantities[itemId] = current - 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Order'),
      ),
      body: StreamBuilder<List<MenuItem>>(
        stream: _service.getMenuItems(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading menu items'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final menuItems =
              snapshot.data!.where((item) => item.available).toList();

          if (menuItems.isEmpty) {
            return const Center(
              child: Text('No available menu items'),
            );
          }

          final total = _calculateTotal(menuItems);

          return Form(
            key: _formKey,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextFormField(
                    controller: _tableController,
                    decoration: const InputDecoration(
                      labelText: 'Table number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.table_restaurant),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter table number';
                      }
                      return null;
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: menuItems.length,
                    itemBuilder: (context, index) {
                      final item = menuItems[index];
                      final qty = _quantities[item.id] ?? 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(Icons.local_pizza),
                          title: Text(item.name),
                          subtitle: Text(
                            '${item.category} • RM ${item.price.toStringAsFixed(2)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => _decreaseQty(item.id),
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Text(
                                '$qty',
                                style: const TextStyle(fontSize: 16),
                              ),
                              IconButton(
                                onPressed: () => _increaseQty(item.id),
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Total: RM ${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed:
                            _isSaving ? null : () => _saveOrder(menuItems),
                        icon: const Icon(Icons.save),
                        label: Text(_isSaving ? 'Saving...' : 'Save Order'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}