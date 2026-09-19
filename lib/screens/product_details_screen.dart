import 'package:flutter/material.dart';

import 'customer_product_availability_screen.dart';
import 'customer_store_screen.dart';
import 'customer_cart_screen.dart';
import '../models/customer_product.dart';
import '../services/customer_store_availability_service.dart';
import '../widgets/customer_product_cart_control.dart';

class ProductDetailsProduct {
  const ProductDetailsProduct({
    required this.id,
    required this.name,
    required this.image,
    required this.brand,
    required this.category,
    required this.productType,
    required this.quantityOrSize,
    required this.variant,
    required this.description,
    required this.price,
    required this.priceContext,
    required this.nearbyStores,
  });

  final String id;
  final String name;
  final List<String> image;
  final String brand;
  final String category;
  final String productType;
  final String quantityOrSize;
  final String variant;
  final String description;
  final double price;
  final String priceContext;
  final List<ProductStoreAvailability> nearbyStores;
}

class ProductStoreAvailability {
  const ProductStoreAvailability({
    required this.storeName,
    required this.distance,
    required this.availability,
    required this.price,
    this.isOpen = true,
    this.storeImage,
    this.distanceKm,
    this.businessLocationId,
  });

  final String storeName;
  final String distance;
  final String availability;
  final double price;
  final bool isOpen;

  /// Optional retailer-provided store image or logo URL.
  ///
  /// Null/empty means the UI should display its local placeholder.
  final String? storeImage;
  final double? distanceKm;
  final String? businessLocationId;
}
class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({
    super.key,
    required this.product,
    required this.customerProduct,
  });

  final ProductDetailsProduct product;
  final CustomerProduct customerProduct;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  static const _background = Color(0xFFF8F8F8);
  static const _surface = Colors.white;
  static const _text = Color(0xFF111111);
  static const _muted = Color(0xFF707070);
  static const _border = Color(0xFFE5E5E5);
  static const _green = Color(0xFF22A447);

  bool _isFavourite = false;
  bool _detailsExpanded = true;
  int _selectedImage = 0;
  List<ProductStoreAvailability>? _stores;

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
      });
    } catch (_) {
      // Keep the existing product data visible if store enrichment fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final images = product.image.isEmpty ? const <String>[] : product.image;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(context)),
                  SliverToBoxAdapter(
                    child: _buildGallery(images),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                      child: _buildProductSummary(product),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: _buildDetailsSection(product),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
                      child: _buildAvailabilitySection(product),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 120),
                  ),
                ],
              ),
            ),
            _buildReserveBar(context),
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
          Center(
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Colors.black,
                BlendMode.srcIn,
              ),
              child: Image.asset(
                'assets/images/aupnix_black.png',
                width: 145,
                height: 44,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) {
                  return const Text(
                    'AUPNIX',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            right: 10,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CustomerCartScreen(),
                      ),
                    );
                  },
                  tooltip: 'Cart',
                  icon: const Icon(
                    Icons.shopping_cart_outlined,
                    size: 22,
                    color: _text,
                  ),
                ),
                IconButton(
                  onPressed: _shareProduct,
                  tooltip: 'Share',
                  icon: const Icon(
                    Icons.ios_share_rounded,
                    size: 22,
                    color: _text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGallery(List<String> images) {
    if (images.isEmpty) {
      return _galleryPlaceholder();
    }

    return Column(
      children: [
        SizedBox(
          height: 320,
          child: PageView.builder(
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() {
                _selectedImage = index;
              });
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    color: const Color(0xFFF0F2F2),
                    width: double.infinity,
                    child: _buildImage(images[index]),
                  ),
                ),
              );
            },
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 58,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final selected = index == _selectedImage;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedImage = index;
                    });
                  },
                  child: Container(
                    width: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? _text : _border,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _buildImage(images[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _galleryPlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 320,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F2F2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Icon(
            Icons.shopping_bag_outlined,
            size: 64,
            color: Color(0xFF303A3D),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String source) {
    if (source.startsWith('http://') || source.startsWith('https://')) {
      return Image.network(
        source,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 48,
            color: _muted,
          ),
        ),
      );
    }

    return Image.asset(
      source,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const Center(
        child: Icon(
          Icons.shopping_bag_outlined,
          size: 56,
          color: Color(0xFF303A3D),
        ),
      ),
    );
  }

  Widget _buildProductSummary(ProductDetailsProduct product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                product.name,
                style: const TextStyle(
                  color: _text,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Material(
              color: _surface,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isFavourite = !_isFavourite;
                  });
                },
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    _isFavourite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: _isFavourite ? Colors.red : _text,
                    size: 25,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (product.brand.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            product.brand,
            style: const TextStyle(
              color: _muted,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${_formatPrice(product.price)}',
              style: const TextStyle(
                color: _text,
                fontSize: 27,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  product.priceContext,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _infoChip(product.category),
            _infoChip(product.productType),
            if (product.quantityOrSize.isNotEmpty)
              _infoChip(product.quantityOrSize),
            if (product.variant.isNotEmpty) _infoChip(product.variant),
          ],
        ),
        if (product.description.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            product.description,
            style: const TextStyle(
              color: _muted,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
        const SizedBox(height: 20),
        _buildAddToCartButton(),
        const SizedBox(height: 2),
      ],
    );
  }

  Widget _infoChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1F1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _text,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAddToCartButton() {
    return CustomerProductCartControl(
      product: widget.customerProduct,
    );
  }

  Widget _buildDetailsSection(ProductDetailsProduct product) {
    final attributes = <MapEntry<String, String>>[
      MapEntry('Brand', product.brand),
      MapEntry('Category', product.category),
      MapEntry('Product type', product.productType),
      MapEntry('Quantity / Size', product.quantityOrSize),
      MapEntry('Variant', product.variant),
      MapEntry('Product ID', product.id),
    ].where((entry) => entry.value.isNotEmpty).toList();

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _detailsExpanded = !_detailsExpanded;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Product Details',
                      style: TextStyle(
                        color: _text,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    _detailsExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: _text,
                  ),
                ],
              ),
            ),
          ),
          if (_detailsExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(height: 1, color: _border),
                  const SizedBox(height: 4),
                  for (var index = 0; index < attributes.length; index++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 112,
                            child: Text(
                              attributes[index].key,
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              attributes[index].value,
                              style: const TextStyle(
                                color: _text,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvailabilitySection(ProductDetailsProduct product) {
    final stores = _stores ?? product.nearbyStores;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nearby Availability',
          style: TextStyle(
            color: _text,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          stores.isEmpty
              ? 'No nearby stores are available in this preview.'
              : '${stores.length} store${stores.length == 1 ? '' : 's'} found nearby',
          style: const TextStyle(
            color: _muted,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 14),
        if (stores.isEmpty)
          _emptyAvailability()
        else
          ...stores.map(_buildStoreCard),
      ],
    );
  }

  Widget _emptyAvailability() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: const Text(
        'Store availability will appear here when participating retailers list this product.',
        style: TextStyle(
          color: _muted,
          fontSize: 13,
          height: 1.45,
        ),
      ),
    );
  }

  Widget _buildStoreCard(ProductStoreAvailability store) {
    final available = store.availability.toLowerCase() != 'out of stock';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.storeName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      store.distance,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '₹${_formatPrice(store.price)}',
                style: const TextStyle(
                  color: _text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
                size: 17,
                color: available ? _green : _muted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  available ? 'Available' : 'Out of stock',
                  style: TextStyle(
                    color: available ? _green : _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (store.isOpen) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: _green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                store.isOpen ? 'Open' : 'Closed',
                style: TextStyle(
                  color: store.isOpen ? _green : _muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton(
              onPressed: () => _viewStore(store),
              style: OutlinedButton.styleFrom(
                foregroundColor: _text,
                side: const BorderSide(color: _border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              child: const Text(
                'View Store',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReserveBar(BuildContext context) {
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
              onPressed: () => _reserveProduct(context),
              style: FilledButton.styleFrom(
                backgroundColor: _text,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Reserve Product',
                style: TextStyle(
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


  void _shareProduct() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share prepared for ${widget.product.name}.'),
        behavior: SnackBarBehavior.floating,
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

  void _reserveProduct(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomerProductAvailabilityScreen(
          product: widget.product,
        ),
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










