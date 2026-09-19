import 'package:flutter/material.dart';

import 'customer_cart_screen.dart';
import 'product_details_screen.dart';

class CustomerStoreScreen extends StatefulWidget {
  const CustomerStoreScreen({
    super.key,
    required this.product,
    required this.store,
  });

  final ProductDetailsProduct product;
  final ProductStoreAvailability store;

  @override
  State<CustomerStoreScreen> createState() => _CustomerStoreScreenState();
}

class _CustomerStoreScreenState extends State<CustomerStoreScreen> {
  static const _background = Color(0xFFF8F8F8);
  static const _surface = Colors.white;
  static const _text = Color(0xFF111111);
  static const _muted = Color(0xFF707070);
  static const _border = Color(0xFFE5E5E5);
  static const _openGreen = Color(0xFF168A45);
  static const _statusRed = Color(0xFFD93025);

  bool _isFavourite = false;

  @override
  Widget build(BuildContext context) {
    final store = widget.store;

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
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStoreHero(store),
                          const SizedBox(height: 20),
                          _buildOperatingStatus(store),
                          const SizedBox(height: 20),
                          _buildStoreInformation(store),
                          const SizedBox(height: 20),
                          _buildSelectedProduct(),
                          const SizedBox(height: 20),
                          _buildActions(store),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    const double headerHeight = 64;
    const double touchTarget = 44;
    const double horizontalInset = 8;
    const double actionGap = 0;

    Widget actionButton({
      required IconData icon,
      required double iconSize,
      required String tooltip,
      required VoidCallback onPressed,
    }) {
      return SizedBox(
        width: touchTarget,
        height: touchTarget,
        child: IconButton(
          onPressed: onPressed,
          tooltip: tooltip,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: touchTarget,
            minHeight: touchTarget,
          ),
          icon: Icon(
            icon,
            size: iconSize,
            color: _text,
          ),
        ),
      );
    }

    return SizedBox(
      height: headerHeight,
      child: Stack(
        children: [
          Positioned(
            left: horizontalInset,
            top: (headerHeight - touchTarget) / 2,
            width: touchTarget,
            height: touchTarget,
            child: actionButton(
              icon: Icons.arrow_back_ios_new_rounded,
              iconSize: 21,
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),

          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Transform.translate(
                  offset: const Offset(-24, 0),
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                      Colors.black,
                      BlendMode.srcIn,
                    ),
                    child: Image.asset(
                      'assets/images/aupnix_black.png',
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
              ),
            ),
          ),

          Positioned(
            right: horizontalInset,
            top: (headerHeight - touchTarget) / 2,
            height: touchTarget,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                actionButton(
                  icon: Icons.notifications_none_rounded,
                  iconSize: 24,
                  tooltip: 'Notifications',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Notifications will be available in a future screen.',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                SizedBox(width: actionGap),
                actionButton(
                  icon: Icons.shopping_cart_outlined,
                  iconSize: 22,
                  tooltip: 'Cart',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CustomerCartScreen(),
                      ),
                    );
                  },
                ),
                SizedBox(width: actionGap),
                actionButton(
                  icon: Icons.person_outline_rounded,
                  iconSize: 22,
                  tooltip: 'Profile',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Profile will be available in a future customer profile screen.',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreHero(ProductStoreAvailability store) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildStoreImage(store),
          const SizedBox(width: 14),
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
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      Icons.near_me_outlined,
                      size: 16,
                      color: _muted,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        store.distance,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildFavouriteButton(),
        ],
      ),
    );
  }

  Widget _buildFavouriteButton() {
    return Material(
      color: _background,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          setState(() {
            _isFavourite = !_isFavourite;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isFavourite
                    ? 'Store added to favourites.'
                    : 'Store removed from favourites.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            _isFavourite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            size: 21,
            color: _isFavourite ? Colors.red : _text,
          ),
        ),
      ),
    );
  }

  Widget _buildOperatingStatus(ProductStoreAvailability store) {
    final statusColor = store.isOpen ? _openGreen : _statusRed;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              store.isOpen ? 'Open Now' : 'Closed Now',
              style: TextStyle(
                color: statusColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            store.availability,
            style: const TextStyle(
              color: _muted,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreInformation(ProductStoreAvailability store) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Store Information',
          style: TextStyle(
            color: _text,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Column(
            children: [
              _infoRow(
                Icons.storefront_outlined,
                'Store',
                store.storeName,
              ),
              const SizedBox(height: 14),
              _infoRow(
                Icons.location_on_outlined,
                'Distance',
                store.distance,
              ),
              const SizedBox(height: 14),
              _infoRow(
                Icons.location_city_outlined,
                'Address',
                'Store address will be available from the store profile.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: _text,
        ),
        const SizedBox(width: 11),
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
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: _text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedProduct() {
    final product = widget.product;
    final image = product.image.isEmpty ? null : product.image.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selected Product',
          style: TextStyle(
            color: _text,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: image == null
                    ? const Icon(
                        Icons.shopping_bag_outlined,
                        size: 31,
                        color: Color(0xFF303A3D),
                      )
                    : _buildProductImage(image),
              ),
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
                        fontSize: 14.5,
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
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                    if (product.variant.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        product.variant,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    const SizedBox(height: 7),
                    Text(
                      '₹${_formatPrice(widget.store.price)}',
                      style: const TextStyle(
                        color: _text,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions(ProductStoreAvailability store) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Directions to ${store.storeName} will be available in a future maps integration.',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(
                Icons.directions_outlined,
                size: 19,
              ),
              label: const Text(
                'Get Directions',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _text,
                side: const BorderSide(color: _border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${store.storeName} profile will be available in Screen 16.',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(
                Icons.storefront_outlined,
                size: 19,
              ),
              label: const Text(
                'View Profile',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _text,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStoreImage(ProductStoreAvailability store) {
    final source = store.storeImage?.trim();

    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: source == null || source.isEmpty
          ? const Icon(
              Icons.storefront_outlined,
              size: 34,
              color: Color(0xFF303A3D),
            )
          : source.startsWith('http://') ||
                  source.startsWith('https://')
              ? Image.network(
                  source,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.storefront_outlined,
                    size: 34,
                    color: Color(0xFF303A3D),
                  ),
                )
              : Image.asset(
                  source,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.storefront_outlined,
                    size: 34,
                    color: Color(0xFF303A3D),
                  ),
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
          size: 31,
          color: Color(0xFF303A3D),
        ),
      );
    }

    return Image.asset(
      source,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const Icon(
        Icons.shopping_bag_outlined,
        size: 31,
        color: Color(0xFF303A3D),
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







