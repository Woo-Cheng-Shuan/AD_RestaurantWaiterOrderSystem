import 'package:flutter/material.dart';

import '../models/menu_item.dart';
import '../services/firestore_service.dart';
import '../utils/constants.dart';

class MenuForm extends StatefulWidget {
  final MenuItem? item;

  const MenuForm({super.key, this.item});

  @override
  State<MenuForm> createState() => _MenuFormState();
}

class _MenuFormState extends State<MenuForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();

  final _service = FirestoreService();

  String _category = AppConstants.categories.first;
  bool _available = true;

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();

    if (_isEdit) {
      _nameController.text = widget.item!.name;
      _priceController.text = widget.item!.price.toStringAsFixed(2);
      _category = widget.item!.category;
      _available = widget.item!.available;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _saveMenuItem() async {
    if (!_formKey.currentState!.validate()) return;

    final item = MenuItem(
      id: widget.item?.id ?? '',
      name: _nameController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      category: _category,
      available: _available,
    );

    if (_isEdit) {
      await _service.updateMenuItem(item);
    } else {
      await _service.addMenuItem(item);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Menu Item' : 'Add Menu Item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Item name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_pizza),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter item name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                  prefixText: 'RM ',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter price';
                  }

                  final price = double.tryParse(value.trim());
                  if (price == null || price <= 0) {
                    return 'Please enter a valid price';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: AppConstants.categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _category = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Available'),
                subtitle: const Text('Show this item as available for order'),
                value: _available,
                onChanged: (value) {
                  setState(() {
                    _available = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saveMenuItem,
                icon: const Icon(Icons.save),
                label: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}