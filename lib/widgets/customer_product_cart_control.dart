import 'package:flutter/material.dart';

import '../models/customer_product.dart';
import '../services/customer_cart_service.dart';

class CustomerProductCartControl extends StatefulWidget {
  const CustomerProductCartControl({
    super.key,
    required this.product,
  });

  final CustomerProduct product;

  @override
  State<CustomerProductCartControl> createState() =>
      _CustomerProductCartControlState();
}

class _CustomerProductCartControlState
    extends State<CustomerProductCartControl> {
  CustomerCartService get _cart => CustomerCartService.instance;

  CustomerCartItem? get _cartItem =>
      _cart.itemForProduct(widget.product.id);

  @override
  Widget build(BuildContext context) {
    final item = _cartItem;

    if (item == null) {
      return SizedBox(
        height: 30,
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () {
            setState(() {
              _cart.addProduct(widget.product);
            });
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF182326),
            side: const BorderSide(color: Color(0xFFD8E0E0)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: const Text('Add to Cart'),
        ),
      );
    }

    return Container(
      height: 30,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD8E0E0)),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _cart.decreaseQuantity(widget.product.id);
                });
              },
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(8),
              ),
              child: const Center(
                child: Text(
                  '−',
                  style: TextStyle(
                    color: Color(0xFF182326),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
          Text(
            '${item.quantity}',
            style: const TextStyle(
              color: Color(0xFF182326),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _cart.increaseQuantity(widget.product.id);
                });
              },
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(8),
              ),
              child: const Center(
                child: Text(
                  '+',
                  style: TextStyle(
                    color: Color(0xFF182326),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

