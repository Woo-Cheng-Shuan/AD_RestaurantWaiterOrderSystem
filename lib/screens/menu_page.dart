import 'package:flutter/material.dart';

import '../models/menu_item.dart';
import '../services/firestore_service.dart';
import 'menu_form.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pizza Menu'),
      ),
      body: StreamBuilder<List<MenuItem>>(
        stream: service.getMenuItems(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading menu items'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!;

          if (items.isEmpty) {
            return const Center(child: Text('No menu items yet'));
          }

          final categories = items.map((item) => item.category).toSet().toList();

          return ListView(
            padding: const EdgeInsets.all(12),
            children: categories.map((category) {
              final categoryItems =
                  items.where((item) => item.category == category).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...categoryItems.map((item) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'RM ${item.price.toStringAsFixed(2)}',
                        ),
                        leading: const Icon(Icons.local_pizza),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            Switch(
                              value: item.available,
                              onChanged: (value) {
                                service.toggleMenuAvailability(item.id, value);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MenuForm(item: item),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete menu item?'),
                                    content: Text('Delete ${item.name}?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  service.deleteMenuItem(item.id);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Menu'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const MenuForm(),
            ),
          );
        },
      ),
    );
  }
}