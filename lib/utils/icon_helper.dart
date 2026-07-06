import 'package:flutter/material.dart';

IconData getCategoryIcon(String category) {
  switch (category) {
    case 'Pizza':
      return Icons.local_pizza;

    case 'Drink':
      return Icons.local_drink;

    case 'Dessert':
      return Icons.cake;

    case 'Side':
      return Icons.lunch_dining;

    default:
      return Icons.restaurant_menu;
  }
}