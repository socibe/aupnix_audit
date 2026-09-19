import 'customer_cart_screen.dart';
import 'package:flutter/material.dart';

import '../models/customer_product.dart';
import '../services/customer_product_catalog.dart';
import '../widgets/customer_product_card.dart';
import '../widgets/scroll_aware_bottom_navigation.dart';

import 'customer_home_screen.dart';
import 'product_search_screen.dart';

class StaplesCategoryScreen extends StatefulWidget {
  const StaplesCategoryScreen({super.key});

  @override
  State<StaplesCategoryScreen> createState() => _StaplesCategoryScreenState();
}

class _StaplesCategoryScreenState extends State<StaplesCategoryScreen> {
  static const _text = Color(0xFF111111);
  static const _mutedText = Color(0xFF707070);
  static const _border = Color(0xFFE5E5E5);
  static const _navBlack = Color(0xFF000000);

  final TextEditingController _searchController = TextEditingController();
  final Set<String> _favouriteProducts = <String>{};

  List<CustomerProduct> get _products {
    return CustomerProductCatalog.products
        .where((product) => product.category == 'Staples')
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  List<CustomerProduct> get _filteredProducts {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      return _products;
    }

    return _products.where((product) {
      return product.name.toLowerCase().contains(query) ||
          product.unit.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  void _toggleFavourite(CustomerProduct product) {
    setState(() {
      if (_favouriteProducts.contains(product.id)) {
        _favouriteProducts.remove(product.id);
      } else {
        _favouriteProducts.add(product.id);
      }
    });
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = _filteredProducts;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                    sliver: SliverToBoxAdapter(child: _buildSearchField()),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                    sliver: SliverToBoxAdapter(
                      child: _buildCategoryIntroduction(),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
                    sliver: products.isEmpty
                        ? SliverToBoxAdapter(child: _buildEmptySearchState())
                        : SliverGrid(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final product = products[index];

                                return CustomerProductCard(
                                  product: product,
                                  isFavourite:
                                      _favouriteProducts.contains(product.id),
                                  onFavouriteTap: () =>
                                      _toggleFavourite(product),
                                );
                              },
                              childCount: products.length,
                            ),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 14,
                                  childAspectRatio: 0.61,
                            ),
                          ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 92)),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ScrollAwareBottomNavigation(
                child: _StaplesBottomNavigation(onHomeTap: _goHome),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
                      _navBlack,
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
                            color: _navBlack,
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
                  onPressed: () {},
                ),
                const SizedBox(width: actionGap),
                actionButton(
                  icon: Icons.shopping_cart_outlined,
                  iconSize: 24,
                  tooltip: 'Cart',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CustomerCartScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: actionGap),
                actionButton(
                  icon: Icons.person_outline_rounded,
                  iconSize: 25,
                  tooltip: 'Profile',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildSearchField() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            blurRadius: 5,
            offset: Offset(0, 1),
            color: Color(0x09000000),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        cursorColor: Colors.black,
        style: const TextStyle(
          color: _text,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 18, right: 8),
            child: Icon(
              Icons.search_rounded,
              size: 22,
              color: _mutedText,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 48,
          ),
          hintText: 'Search In Staples',
          hintStyle: const TextStyle(
            color: _mutedText,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  onPressed: _searchController.clear,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 19,
                    color: _mutedText,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildCategoryIntroduction() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 94,
          height: 94,
          decoration: BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black),
          ),
          padding: const EdgeInsets.all(10),
          child: Image.asset(
            'assets/images/Staples.png',
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) {
              return const Icon(
                Icons.shopping_basket_outlined,
                size: 56,
                color: _mutedText,
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Staples',
                style: TextStyle(
                  color: _text,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1.12,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Everyday essentials from your nearest stores',
                style: TextStyle(
                  color: _text,
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySearchState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 38),
      child: const Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 42,
            color: _mutedText,
          ),
          SizedBox(height: 12),
          Text(
            'No Staples products found',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _text,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Try a different product name or search term.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _mutedText,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _StaplesBottomNavigation extends StatelessWidget {
  const _StaplesBottomNavigation({required this.onHomeTap});

  final VoidCallback onHomeTap;

  static const _navBlack = Color(0xFF000000);
  static const _navInactive = Color(0xFF7B8588);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E5E5)),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: Offset(0, -3),
            color: Color(0x0A000000),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StaplesNavItem(
              icon: Icons.home_rounded,
              label: 'Home',
              isActive: false,
              onTap: onHomeTap,
            ),
            _StaplesNavItem(
              icon: Icons.search_rounded,
              label: 'Search',
              isActive: false,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const ProductSearchScreen(autoFocus: false),
                  ),
                );
              },
            ),
            const _StaplesNavItem(
              icon: Icons.event_note_outlined,
              label: 'Reservations',
              isActive: false,
            ),
            const _StaplesNavItem(
              icon: Icons.favorite_border_rounded,
              label: 'Favourites',
              isActive: false,
            ),
            const _StaplesNavItem(
              icon: Icons.person_outline_rounded,
              label: 'Profile',
              isActive: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _StaplesNavItem extends StatelessWidget {
  const _StaplesNavItem({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const navBlack = _StaplesBottomNavigation._navBlack;
    const navInactive = _StaplesBottomNavigation._navInactive;

    return SizedBox(
      width: 66,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 23,
              color: isActive ? navBlack : navInactive,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isActive ? navBlack : navInactive,
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}








