import 'package:flutter/material.dart';

import '../models/customer_product.dart';
import '../services/customer_cart_service.dart';

class CustomerCartScreen extends StatelessWidget {
  const CustomerCartScreen({super.key});

  static const _background = Color(0xFFF8FAFA);
  static const _text = Color(0xFF182124);
  static const _secondaryText = Color(0xFF687276);
  static const _border = Color(0xFFE7ECEC);

  CustomerCartService get _cart => CustomerCartService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Cart',
          style: TextStyle(
            color: _text,
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: _text,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: AnimatedBuilder(
        animation: _cart,
        builder: (context, _) {
          if (_cart.isEmpty) {
            return _buildEmptyState(context);
          }

          return _buildCart(context);
        },
      ),
    );
  }

  Widget _buildCart(BuildContext context) {
    final cart = _cart;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Text(
          '${cart.items.length} ${cart.items.length == 1 ? 'product' : 'products'}',
          style: const TextStyle(
            color: _secondaryText,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        ...cart.items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _CartItemCard(
              item: item,
              onDecrease: () {
                cart.decreaseQuantity(item.product.id);
              },
              onIncrease: () {
                cart.increaseQuantity(item.product.id);
              },
              onRemove: () {
                cart.removeProduct(item.product.id);
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildSummary(cart),
      ],
    );
  }

  Widget _buildSummary(CustomerCartService cart) {
    final total = cart.items.fold<double>(
      0,
      (sum, item) => sum + item.referenceTotalPrice,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 17, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Cart total',
                  style: TextStyle(
                    color: _text,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                _formatPrice(total),
                style: const TextStyle(
                  color: _text,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Requested products and quantities',
              style: TextStyle(
                color: _secondaryText,
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _border),
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 34,
                color: _secondaryText,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Your cart is empty',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _text,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add products from your product cards to review them here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _secondaryText,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            OutlinedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: _text,
                side: const BorderSide(color: Color(0xFFD8E0E0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 11,
                ),
              ),
              child: const Text(
                'Continue Browsing',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatPrice(double value) {
    if (value == value.roundToDouble()) {
      return '\u20B9${value.toInt()}';
    }

    return '\u20B9${value.toStringAsFixed(2)}';
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.onDecrease,
    required this.onIncrease,
    required this.onRemove,
  });

  final CustomerCartItem item;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onRemove;

  static const _text = Color(0xFF182124);
  static const _secondaryText = Color(0xFF687276);
  static const _border = Color(0xFFE7ECEC);

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    final unit = product.unit.trim();

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImage(product),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    unit,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _secondaryText,
                      fontSize: 11.5,
                    ),
                  ),
                ],
                const SizedBox(height: 7),
                Text(
                  product.formattedReferencePrice,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.referencePriceLabel,
                  style: const TextStyle(
                    color: _secondaryText,
                    fontSize: 10.5,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Subtotal: ${_formatPrice(item.referenceTotalPrice)}',
                  style: const TextStyle(
                    color: _text,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    _QuantityButton(
                      icon: Icons.remove_rounded,
                      onTap: onDecrease,
                    ),
                    SizedBox(
                      width: 36,
                      child: Text(
                        '${item.quantity}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _text,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _QuantityButton(
                      icon: Icons.add_rounded,
                      onTap: onIncrease,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: onRemove,
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Remove',
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: _secondaryText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(CustomerProduct product) {
    final imagePath = product.image.trim();

    if (imagePath.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          imagePath,
          width: 82,
          height: 82,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _imagePlaceholder();
          },
        ),
      );
    }

    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.image_outlined,
        size: 28,
        color: Color(0xFFAAB3B5),
      ),
    );
  }

  static String _formatPrice(double value) {
    if (value == value.roundToDouble()) {
      return '\u20B9${value.toInt()}';
    }

    return '\u20B9${value.toStringAsFixed(2)}';
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: Material(
        color: const Color(0xFFF8FAFA),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Icon(
            icon,
            size: 17,
            color: const Color(0xFF182124),
          ),
        ),
      ),
    );
  }
}

