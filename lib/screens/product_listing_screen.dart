import 'package:flutter/material.dart';

import '../models/customer_product.dart';
import '../services/customer_product_catalog.dart';
import '../widgets/customer_product_card.dart';

class ProductListingScreen extends StatelessWidget {
  const ProductListingScreen({
    super.key,
    required this.query,
    this.initialCategory,
  });

  final String query;
  final String? initialCategory;

  static const _background = Color(0xFFFFFFFF);
  static const _text = Color(0xFF111111);
  static const _mutedText = Color(0xFF707070);

  List<CustomerProduct> _matchingProducts() {
    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return List<CustomerProduct>.of(CustomerProductCatalog.products);
    }

    final products = CustomerProductCatalog.products;

    final exactMatches = <CustomerProduct>[];
    final nameMatches = <CustomerProduct>[];
    final categoryMatches = <CustomerProduct>[];
    final unitMatches = <CustomerProduct>[];

    for (final product in products) {
      final name = product.name.toLowerCase();
      final category = product.category.toLowerCase();
      final unit = product.unit.toLowerCase();

      if (name == normalizedQuery) {
        exactMatches.add(product);
      } else if (name.startsWith(normalizedQuery)) {
        nameMatches.add(product);
      } else if (name.contains(normalizedQuery)) {
        nameMatches.add(product);
      } else if (category.contains(normalizedQuery)) {
        categoryMatches.add(product);
      } else if (unit.contains(normalizedQuery)) {
        unitMatches.add(product);
      }
    }

    if (exactMatches.isNotEmpty) {
      return exactMatches;
    }

    if (nameMatches.isNotEmpty) {
      return nameMatches;
    }

    if (categoryMatches.isNotEmpty) {
      return categoryMatches;
    }

    return unitMatches;
  }

  @override
  Widget build(BuildContext context) {
    final products = _matchingProducts();
    final displayedQuery = query.trim();

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: _text,
          ),
        ),
        title: const Text(
          'Products',
          style: TextStyle(
            color: _text,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: products.isEmpty
            ? _EmptyListing(query: displayedQuery)
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (displayedQuery.isNotEmpty)
                            Text(
                              'Results for "$displayedQuery"',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _text,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          else
                            const Text(
                              'All Products',
                              style: TextStyle(
                                color: _text,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          const SizedBox(height: 5),
                          Text(
                            '${products.length} ${products.length == 1 ? 'product' : 'products'}',
                            style: const TextStyle(
                              color: _mutedText,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = products[index];

                          return CustomerProductCard(
                            product: product,
                          );
                        },
                        childCount: products.length,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 13,
                        childAspectRatio: 0.69,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _EmptyListing extends StatelessWidget {
  const _EmptyListing({
    required this.query,
  });

  final String query;

  static const _text = Color(0xFF111111);
  static const _mutedText = Color(0xFF707070);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 54,
              color: Color(0xFFD5D5D5),
            ),
            const SizedBox(height: 18),
            const Text(
              'No products found',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _text,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              query.isEmpty
                  ? 'Try searching for another product.'
                  : 'We could not find a product matching "$query".',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _mutedText,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
