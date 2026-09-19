import 'package:flutter/foundation.dart';

import '../models/customer_product.dart';

class CustomerCartItem {
  CustomerCartItem({
    required this.product,
    this.quantity = 1,
  }) : assert(quantity > 0);

  final CustomerProduct product;
  int quantity;

  double get referenceUnitPrice => product.referencePrice;

  double get referenceTotalPrice => referenceUnitPrice * quantity;
}

class CustomerCartService extends ChangeNotifier {
  CustomerCartService._();

  static final CustomerCartService instance = CustomerCartService._();

  final List<CustomerCartItem> _items = <CustomerCartItem>[];

  List<CustomerCartItem> get items =>
      List<CustomerCartItem>.unmodifiable(_items);

  int get itemCount =>
      _items.fold(0, (total, item) => total + item.quantity);

  bool get isEmpty => _items.isEmpty;

  CustomerCartItem? itemForProduct(String productId) {
    for (final item in _items) {
      if (item.product.id == productId) {
        return item;
      }
    }

    return null;
  }

  bool containsProduct(String productId) =>
      itemForProduct(productId) != null;

  void addProduct(CustomerProduct product) {
    final existingItem = itemForProduct(product.id);

    if (existingItem != null) {
      existingItem.quantity += 1;
      notifyListeners();
      return;
    }

    _items.add(CustomerCartItem(product: product));
    notifyListeners();
  }

  void increaseQuantity(String productId) {
    final item = itemForProduct(productId);

    if (item == null) {
      return;
    }

    item.quantity += 1;
    notifyListeners();
  }

  void decreaseQuantity(String productId) {
    final item = itemForProduct(productId);

    if (item == null) {
      return;
    }

    if (item.quantity <= 1) {
      removeProduct(productId);
      return;
    }

    item.quantity -= 1;
    notifyListeners();
  }

  void removeProduct(String productId) {
    final originalLength = _items.length;

    _items.removeWhere((item) => item.product.id == productId);

    if (_items.length != originalLength) {
      notifyListeners();
    }
  }

  void clear() {
    if (_items.isEmpty) {
      return;
    }

    _items.clear();
    notifyListeners();
  }
}
