import 'customer_cart_screen.dart';
import 'package:flutter/material.dart';

import '../models/customer_product.dart';
import '../services/customer_product_catalog.dart';
import '../widgets/customer_product_card.dart';
import '../widgets/scroll_aware_bottom_navigation.dart';

class ProductSearchScreen extends StatefulWidget {
  const ProductSearchScreen({
    super.key,
    this.autoFocus = true,
    this.initialCategory,
  });

  final bool autoFocus;
  final String? initialCategory;

  @override
  State<ProductSearchScreen> createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState extends State<ProductSearchScreen> {
  static const _background = Color(0xFFFFFFFF);
  static const _text = Color(0xFF111111);
  static const _secondaryText = Color(0xFF444444);
  static const _mutedText = Color(0xFF707070);
  static const _border = Color(0xFFE5E5E5);
  static const _divider = Color(0xFFEEEEEE);
  static const _searchBackground = Color(0xFFFAFAFA);

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final List<String> _recentSearches = [];
  final Set<String> _favouriteProducts = <String>{};

  List<CustomerProduct> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_updateSearchResults);

    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _searchFocusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_updateSearchResults);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _updateSearchResults() {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      if (_searchResults.isNotEmpty && mounted) {
        setState(() {
          _searchResults = [];
        });
      }
      return;
    }

    final normalizedQuery = query.toLowerCase();
    final nameMatches = <_RankedCustomerProduct>[];
    final fallbackMatches = <_RankedCustomerProduct>[];

    final products = CustomerProductCatalog.products;

    for (var index = 0; index < products.length; index++) {
      final product = products[index];

      final name = product.name.toLowerCase();
      final category = product.category.toLowerCase();
      final unit = product.unit.toLowerCase();

      var nameScore = 0;

      if (name == normalizedQuery) {
        nameScore = 1000;
      } else if (name.startsWith(normalizedQuery)) {
        nameScore = 800;
      } else if (name.contains(normalizedQuery)) {
        nameScore = 600;
      }

      if (nameScore > 0) {
        nameMatches.add(
          _RankedCustomerProduct(
            product: product,
            score: nameScore,
            index: index,
          ),
        );
        continue;
      }

      var fallbackScore = 0;

      if (category.contains(normalizedQuery)) {
        fallbackScore += 350;
      }

      if (unit.contains(normalizedQuery)) {
        fallbackScore += 100;
      }

      if (widget.initialCategory != null &&
          product.category.toLowerCase() ==
              widget.initialCategory!.toLowerCase()) {
        fallbackScore += 75;
      }

      if (fallbackScore > 0) {
        fallbackMatches.add(
          _RankedCustomerProduct(
            product: product,
            score: fallbackScore,
            index: index,
          ),
        );
      }
    }

    final ranked = nameMatches.isNotEmpty ? nameMatches : fallbackMatches;

    ranked.sort((a, b) {
      final scoreComparison = b.score.compareTo(a.score);

      if (scoreComparison != 0) {
        return scoreComparison;
      }

      return a.index.compareTo(b.index);
    });

    final results = ranked.map((item) => item.product).toList();

    if (mounted) {
      setState(() {
        _searchResults = results;
      });
    }
  }

  void _performSearch() {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      return;
    }

    setState(() {
      _recentSearches.removeWhere(
        (search) => search.toLowerCase() == query.toLowerCase(),
      );
      _recentSearches.insert(0, query);

      if (_recentSearches.length > 6) {
        _recentSearches.removeLast();
      }
    });

    _searchFocusNode.requestFocus();
  }

  void _selectSearch(String search) {
    _searchController.text = search;
    _searchController.selection = TextSelection.collapsed(
      offset: search.length,
    );
    _searchFocusNode.requestFocus();
  }

  void _removeRecentSearch(String search) {
    setState(() {
      _recentSearches.remove(search);
    });
  }

  void _toggleFavourite(CustomerProduct product) {
    setState(() {
      if (_favouriteProducts.contains(product.name)) {
        _favouriteProducts.remove(product.name);
      } else {
        _favouriteProducts.add(product.name);
      }
    });
  }

  List<CustomerProduct> get _displayedSearchResults =>
      List<CustomerProduct>.from(_searchResults);

  @override
  Widget build(BuildContext context) {
    final hasQuery = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: _background,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 92),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSearchField(),
                          if (_recentSearches.isNotEmpty && !hasQuery) ...[
                            const SizedBox(height: 28),
                            _buildRecentSearches(),
                          ],
                          if (!hasQuery) ...[
                            const SizedBox(height: 28),
                            _buildPopularSearches(),
                            const SizedBox(height: 30),
                            _buildDiscoveryPreview(),
                          ] else ...[
                            const SizedBox(height: 26),
                            _buildSearchResults(),
                          ],
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
              child: ScrollAwareBottomNavigation(
                child: _buildBottomNavigation(context),
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
    return AnimatedBuilder(
      animation: _searchController,
      builder: (context, _) {
        final hasText = _searchController.text.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 61,
              decoration: BoxDecoration(
                color: _searchBackground,
                borderRadius: BorderRadius.circular(31),
                border: Border.all(color: _border),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 10,
                    offset: Offset(0, 3),
                    color: Color(0x0B000000),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 20),
                  const Icon(
                    Icons.search_rounded,
                    size: 24,
                    color: _secondaryText,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) {
                        _performSearch();
                        _searchFocusNode.unfocus();
                      },
                      cursorColor: Colors.black,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Search For Products Or Stores',
                        hintStyle: TextStyle(
                          color: _mutedText,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                    ),
                  ),
                  if (hasText)
                    IconButton(
                      onPressed: () {
                        final hasNoResults =
                            _searchResults.isEmpty &&
                            _searchController.text.trim().isNotEmpty;

                        if (hasNoResults && Navigator.of(context).canPop()) {
                          _searchFocusNode.unfocus();
                          Navigator.of(context).pop();
                          return;
                        }

                        _searchController.clear();
                      },
                      splashRadius: 20,
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: _mutedText,
                      ),
                    )
                  else
                    const SizedBox(width: 12),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Searches',
          style: TextStyle(
            color: _text,
            fontSize: 19,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: _recentSearches.map((search) {
            return _SearchChip(
              label: search,
              icon: Icons.history_rounded,
              onTap: () => _selectSearch(search),
              onRemove: () => _removeRecentSearch(search),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPopularSearches() {
    const searches = [
      'Fresh Fruits',
      'Snacks',
      'Beverages',
      'Personal Care',
      'Household Essentials',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Popular Searches',
          style: TextStyle(
            color: _text,
            fontSize: 19,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 14),
        Column(
          children: searches.map((search) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 1),
              child: _PopularSearchRow(
                label: search,
                onTap: () => _selectSearch(search),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDiscoveryPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Discover Products & Stores',
          style: TextStyle(
            color: _text,
            fontSize: 19,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 14),
        const _DiscoveryCard(
          icon: Icons.shopping_bag_outlined,
          title: 'Products',
          subtitle: 'Find products available at nearby stores',
        ),
        const SizedBox(height: 10),
        const _DiscoveryCard(
          icon: Icons.storefront_outlined,
          title: 'Stores',
          subtitle: 'Explore stores carrying what you need',
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    final displayedResults = _displayedSearchResults;

    if (_searchResults.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Search Results',
            style: TextStyle(
              color: _text,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No products found for "${_searchController.text.trim()}"',
            style: const TextStyle(
              color: _mutedText,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${displayedResults.length} ${displayedResults.length == 1 ? 'result' : 'results'}',
          style: const TextStyle(
            color: _text,
            fontSize: 19,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        if (displayedResults.isEmpty) ...[
          const SizedBox(height: 8),
          const Text(
            'No products match the selected filters.',
            style: TextStyle(
              color: _mutedText,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ] else ...[
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayedResults.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 14,
              childAspectRatio: 0.61,
            ),
            itemBuilder: (context, index) {
              final product = displayedResults[index];

              return CustomerProductCard(
                product: product,
                isFavourite: _favouriteProducts.contains(product.name),
                onFavouriteTap: () => _toggleFavourite(product),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _divider)),
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
        child: SizedBox(
          height: 68,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BottomNavigationItem(
                icon: Icons.home_outlined,
                label: 'Home',
                onTap: () => Navigator.of(context).maybePop(),
              ),
              const _BottomNavigationItem(
                icon: Icons.search_rounded,
                label: 'Search',
                active: true,
              ),
              const _BottomNavigationItem(
                icon: Icons.event_note_outlined,
                label: 'Reservations',
              ),
              const _BottomNavigationItem(
                icon: Icons.favorite_border_rounded,
                label: 'Favourites',
              ),
              const _BottomNavigationItem(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankedCustomerProduct {
  const _RankedCustomerProduct({
    required this.product,
    required this.score,
    required this.index,
  });

  final CustomerProduct product;
  final int score;
  final int index;
}

class _SearchChip extends StatelessWidget {
  const _SearchChip({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.onRemove,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFAFAFA),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(13, 9, 8, 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E5E5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: const Color(0xFF707070)),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF444444),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 3),
              InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(14),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.close_rounded,
                    size: 15,
                    color: Color(0xFF707070),
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

class _PopularSearchRow extends StatelessWidget {
  const _PopularSearchRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFEEEEEE)),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.trending_up_rounded,
                size: 19,
                color: Color(0xFF707070),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF444444),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Color(0xFF999999),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscoveryCard extends StatelessWidget {
  const _DiscoveryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5E5)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            offset: Offset(0, 2),
            color: Color(0x08000000),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, size: 24, color: const Color(0xFF222222)),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF111111),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF707070),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavigationItem extends StatelessWidget {
  const _BottomNavigationItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = SizedBox(
      width: 64,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 23,
            color: active ? const Color(0xFF111111) : const Color(0xFF777777),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: active
                  ? const Color(0xFF111111)
                  : const Color(0xFF777777),
              fontSize: 10.5,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return child;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: child,
    );
  }
}






