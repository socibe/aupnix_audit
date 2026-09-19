import 'package:flutter/material.dart';

import '../models/customer_product.dart';
import '../screens/product_details_screen.dart';
import '../services/customer_product_catalog.dart';
import '../services/customer_store_availability_service.dart';
import 'customer_product_cart_control.dart';

class CustomerProductCard extends StatefulWidget {
  const CustomerProductCard({
    super.key,
    required this.product,
    this.isFavourite = false,
    this.onFavouriteTap,
    this.onTap,
  });

  final CustomerProduct product;
  final bool isFavourite;
  final VoidCallback? onFavouriteTap;
  final VoidCallback? onTap;

  @override
  State<CustomerProductCard> createState() => _CustomerProductCardState();
}

class _CustomerProductCardState extends State<CustomerProductCard> {
  ProductStoreAvailability? _nearestStore;

  CustomerProduct get _customerProduct {
    final product = CustomerProductCatalog.findByNameAndUnit(
      widget.product.name,
      widget.product.unit,
    );

    return product ?? widget.product;
  }

  @override
  void initState() {
    super.initState();
    _loadNearestStore();
  }

  Future<void> _loadNearestStore() async {
    final detailsProduct = ProductDetailsProduct(
      id: widget.product.id,
      name: widget.product.name,
      image: widget.product.image.isEmpty
          ? const <String>[]
          : <String>[widget.product.image],
      brand: 'AUPNIX',
      category: _customerProduct.category,
      productType: 'Product',
      quantityOrSize: _customerProduct.unit,
      variant: '',
      description:
          'Product information and nearby availability are shown in this preview.',
      price: _customerProduct.referencePrice,
      priceContext: _customerProduct.referencePriceLabel,
      nearbyStores: const <ProductStoreAvailability>[],
    );

    try {
      final nearestStore =
          await CustomerStoreAvailabilityService.instance
              .nearestAvailableStoreForProduct(detailsProduct);

      if (!mounted) {
        return;
      }

      setState(() {
        _nearestStore = nearestStore;
      });
    } catch (_) {
      // Keep the product card visible if store enrichment fails.
    }
  }

  Widget _buildImagePlaceholder() {
    switch (_customerProduct.category) {
      case 'Beverages':
        return const Icon(
          Icons.local_drink_outlined,
          size: 62,
          color: Color(0xFF707070),
        );
      case 'Fruits & Vegetables':
        return const Icon(
          Icons.eco_outlined,
          size: 62,
          color: Color(0xFF707070),
        );
      default:
        return const Icon(
          Icons.shopping_bag_outlined,
          size: 62,
          color: Color(0xFF707070),
        );
    }
  }

  ProductDetailsProduct _buildDetailsProduct() {
    return ProductDetailsProduct(
      id: widget.product.id,
      name: widget.product.name,
      image: widget.product.image.isEmpty
          ? const <String>[]
          : <String>[widget.product.image],
      brand: 'AUPNIX',
      category: _customerProduct.category,
      productType: 'Product',
      quantityOrSize: _customerProduct.unit,
      variant: '',
      description:
          'Product information and nearby availability are shown in this preview.',
      price: _customerProduct.referencePrice,
      priceContext: _customerProduct.referencePriceLabel,
      nearbyStores: _nearestStore == null
          ? const <ProductStoreAvailability>[]
          : <ProductStoreAvailability>[_nearestStore!],
    );
  }

  void _openProductDetails() {
    if (widget.onTap != null) {
      widget.onTap!();
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailsScreen(
          customerProduct: _customerProduct,
          product: _buildDetailsProduct(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _openProductDetails,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE5E5E5),
            ),
            boxShadow: const [
              BoxShadow(
                blurRadius: 7,
                offset: Offset(0, 2),
                color: Color(0x08000000),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 12,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(5, 6, 40, 3),
                        child: Center(
                          child: Transform.scale(
                            scale: 1.5,
                            child: widget.product.image.isEmpty
                                ? _buildImagePlaceholder()
                                : Image.asset(
                                    widget.product.image,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, _, _) {
                                      return _buildImagePlaceholder();
                                    },
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF111111),
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        height: 1.18,
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (_customerProduct.unit.isNotEmpty)
                      Text(
                        _customerProduct.unit,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF707070),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                      ),
                    const SizedBox(height: 3),
                    Text(
                      _customerProduct.formattedReferencePrice,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF111111),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Expanded(
                          child: Text(
                            'Available at',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFF707070),
                              fontSize: 10.2,
                              fontWeight: FontWeight.w400,
                              height: 1.2,
                            ),
                          ),
                        ),
                        if (_nearestStore != null) ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF22A447),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Open',
                            style: TextStyle(
                              color: Color(0xFF22A447),
                              fontSize: 10.2,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _nearestStore?.storeName ?? 'Finding nearest store...',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF111111),
                        fontSize: 10.3,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      height: 1,
                      color: const Color(0xFFE5E5E5),
                    ),
                    const SizedBox(height: 6),
                    CustomerProductCartControl(
                      product: _customerProduct,
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 3,
                right: 11,
                child: Transform.translate(
                  offset: const Offset(12, -4),
                  child: IconButton(
                    onPressed: widget.onFavouriteTap,
                    tooltip: widget.isFavourite
                        ? 'Remove from favourites'
                        : 'Add to favourites',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    icon: Transform.translate(
                      offset: const Offset(0, 0),
                      child: Icon(
                        widget.isFavourite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 23,
                        color: widget.isFavourite
                            ? Colors.red
                            : const Color(0xFF111111),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


