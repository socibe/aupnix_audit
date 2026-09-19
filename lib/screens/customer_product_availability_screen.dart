import 'package:flutter/material.dart';

import 'product_details_screen.dart';
import 'customer_store_screen.dart';

import '../services/customer_store_availability_service.dart';
class CustomerProductAvailabilityScreen extends StatefulWidget {
  const CustomerProductAvailabilityScreen({
    super.key,
    required this.product,
    this.initiallySelectedStore,
  });

  final ProductDetailsProduct product;
  final ProductStoreAvailability? initiallySelectedStore;

  @override
  State<CustomerProductAvailabilityScreen> createState() =>
      _CustomerProductAvailabilityScreenState();
}

class _CustomerProductAvailabilityScreenState
    extends State<CustomerProductAvailabilityScreen> {
  static const _background = Color(0xFFF8F8F8);
  static const _surface = Colors.white;
  static const _text = Color(0xFF111111);
  static const _muted = Color(0xFF707070);
  static const _border = Color(0xFFE5E5E5);
  static const _green = Color(0xFF059791);
  static const _openGreen = Color(0xFF168A45);
  static const _statusRed = Color(0xFFD93025);

  List<ProductStoreAvailability> _stores = const [];
  String? _selectedStoreName;


  @override
  void initState() {
    super.initState();
    _loadStoreAvailability();
  }

  Future<void> _loadStoreAvailability() async {
    try {
      final stores =
          await CustomerStoreAvailabilityService.instance.buildForProduct(
        widget.product,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _stores = stores;

        final initialStore = widget.initiallySelectedStore;
        if (initialStore != null &&
            stores.any((store) => store.storeName == initialStore.storeName)) {
          _selectedStoreName = initialStore.storeName;
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _stores = List<ProductStoreAvailability>.from(
          widget.product.nearbyStores,
        );

        final initialStore = widget.initiallySelectedStore;
        if (initialStore != null) {
          _selectedStoreName = initialStore.storeName;
        }
      });
    }
  }


  List<ProductStoreAvailability> get _displayedStores {
    return List<ProductStoreAvailability>.from(_stores);
  }


  bool _isAvailable(ProductStoreAvailability store) {
    return store.availability.toLowerCase() != 'out of stock';
  }



  @override
  Widget build(BuildContext context) {
    final stores = _displayedStores;
    final availableCount = _stores.where(_isAvailable).length;
    final lowestPrice = _stores.isEmpty
        ? null
        : _stores
            .map((store) => store.price)
            .reduce((a, b) => a < b ? a : b);
    final nearestStore = _stores.isEmpty ? null : _stores.first;
    return Scaffold(
      backgroundColor: _background,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProductSummary(),
                          const SizedBox(height: 22),
                          _buildAvailabilitySummary(
                            availableCount: availableCount,
                            lowestPrice: lowestPrice,
                            nearestStore: nearestStore,
                          ),
                          const SizedBox(height: 22),
                          _buildStoreList(stores),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildContinueBar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 12,
            child: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: 'Back',
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 21,
                color: _text,
              ),
            ),
          ),
          const Center(
            child: Text(
              'Select Store',
              style: TextStyle(
                color: _text,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSummary() {
    final product = widget.product;
    final image = product.image.isEmpty ? null : product.image.first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F2),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: image == null
                ? const Icon(
                    Icons.shopping_bag_outlined,
                    size: 34,
                    color: Color(0xFF303A3D),
                  )
                : _buildProductImage(image),
          ),
          const SizedBox(width: 14),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                if (product.quantityOrSize.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    product.quantityOrSize,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (product.variant.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    product.variant,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${_formatPrice(product.price)}',
                      style: const TextStyle(
                        color: _text,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        product.priceContext,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 10.5,
                        ),
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

  Widget _buildProductImage(String source) {
    if (source.startsWith('http://') || source.startsWith('https://')) {
      return Image.network(
        source,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const Icon(
          Icons.shopping_bag_outlined,
          size: 34,
          color: Color(0xFF303A3D),
        ),
      );
    }

    return Image.asset(
      source,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const Icon(
        Icons.shopping_bag_outlined,
        size: 34,
        color: Color(0xFF303A3D),
      ),
    );
  }

  Widget _buildAvailabilitySummary({
    required int availableCount,
    required double? lowestPrice,
    required ProductStoreAvailability? nearestStore,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _stores.isEmpty
              ? 'No Stores'
              : 'Available At ${_stores.length} Stores',
          style: const TextStyle(
            color: _text,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _stores.isEmpty
              ? 'We could not find availability for this product.'
              : '$availableCount store${availableCount == 1 ? '' : 's'} currently show availability.',
          style: const TextStyle(
            color: _muted,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        if (_stores.isNotEmpty) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _summaryCard(
                  'Lowest Price',
                  lowestPrice == null
                      ? '—'
                      : '₹${_formatPrice(lowestPrice)}',
                  Icons.sell_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryCard(
                  'Nearest',
                  nearestStore?.distance ?? '—',
                  Icons.near_me_outlined,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _summaryCard(
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 19,
            color: _text,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildStoreList(List<ProductStoreAvailability> stores) {
    if (_stores.isEmpty) {
      return _emptyState(
        'No stores are available for this product yet.',
      );
    }

    if (stores.isEmpty) {
      return _emptyState(
        'No stores are currently available.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Stores',
                style: TextStyle(
                  color: _text,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${stores.length} result${stores.length == 1 ? '' : 's'}',
              style: const TextStyle(
                color: _muted,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...stores.map(_buildStoreCard),
      ],
    );
  }

  Widget _emptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.store_mall_directory_outlined,
            size: 38,
            color: _muted,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _muted,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreCard(ProductStoreAvailability store) {
    final selected = _selectedStoreName == store.storeName;
    final available = _isAvailable(store);
    final lowestPrice = _stores.isNotEmpty &&
        store.price ==
            _stores
                .map((item) => item.price)
                .reduce((a, b) => a < b ? a : b);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            setState(() {
              if (_selectedStoreName == store.storeName) {
                _selectedStoreName = null;
              } else {
                _selectedStoreName = store.storeName;
              }
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFFF3F4F4)
                  : _surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? _text : _border,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStoreImage(store),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  store.storeName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _text,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (lowestPrice) ...[
                                const SizedBox(width: 8),
                                _lowestPriceTag(),
                              ],
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            store.distance,
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _selectionIndicator(selected),
                  ],
                ),
                const SizedBox(height: 13),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      available
                          ? Icons.check_circle_outline_rounded
                          : Icons.remove_circle_outline_rounded,
                      size: 16,
                      color: available ? _openGreen : _statusRed,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        available ? 'Available' : 'Out of stock',
                        style: TextStyle(
                          color: available ? _openGreen : _statusRed,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                      ),
                    const SizedBox(width: 10),
                    _buildStoreOpenStatus(store.isOpen),
                  ],
                ),
                const SizedBox(height: 13),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        '₹${_formatPrice(store.price)}',
                        style: const TextStyle(
                          color: _text,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 38,
                      child: OutlinedButton(
                        onPressed: () => _viewStore(store),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _text,
                          side: const BorderSide(color: _border),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'View Store',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoreOpenStatus(bool isOpen) {
    final statusColor = isOpen ? _openGreen : _statusRed;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          isOpen ? 'Open' : 'Closed',
          style: TextStyle(
            color: statusColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
      ],
    );
  }
  Widget _buildStoreImage(ProductStoreAvailability store) {
    final source = store.storeImage?.trim();

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: source == null || source.isEmpty
          ? const Icon(
              Icons.storefront_outlined,
              size: 27,
              color: Color(0xFF303A3D),
            )
          : source.startsWith('http://') ||
                  source.startsWith('https://')
              ? Image.network(
                  source,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.storefront_outlined,
                    size: 27,
                    color: Color(0xFF303A3D),
                  ),
                )
              : Image.asset(
                  source,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.storefront_outlined,
                    size: 27,
                    color: Color(0xFF303A3D),
                  ),
                ),
    );
  }

  Widget _lowestPriceTag() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F4F3),
        borderRadius: BorderRadius.circular(7),
      ),
      child: const Text(
        'Lowest Price',
        style: TextStyle(
          color: _green,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }

  void _viewStore(ProductStoreAvailability store) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomerStoreScreen(
          product: widget.product,
          store: store,
        ),
      ),
    );
  }
  Widget _selectionIndicator(bool selected) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? _text : _surface,
        border: Border.all(
          color: selected ? _text : const Color(0xFFBDBDBD),
          width: 1.5,
        ),
      ),
      child: selected
          ? const Icon(
              Icons.check_rounded,
              size: 14,
              color: Colors.white,
            )
          : null,
    );
  }

  Widget _buildContinueBar() {
    final selectedStore = _selectedStoreName != null;

    return Material(
      color: _surface,
      elevation: 8,
      shadowColor: Colors.black12,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: selectedStore ? _continueToReservation : null,
              style: FilledButton.styleFrom(
                backgroundColor: _text,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFD5D5D5),
                disabledForegroundColor: const Color(0xFF8A8A8A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                selectedStore
                    ? 'Continue to Reservation'
                    : 'Select a Store to Continue',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _continueToReservation() {
    final storeName = _selectedStoreName;

    if (storeName == null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$storeName selected. Reservation flow will continue in Screen 14.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatPrice(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2);
  }
}










