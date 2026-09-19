enum CustomerProductPricingType {
  fixedMrp,
  fluctuatingAverage,
}

class CustomerProduct {
  const CustomerProduct({
    required this.id,
    required this.name,
    required this.unit,
    required this.image,
    required this.category,
    required this.pricingType,
    this.mrp,
    this.averageNearbyPrice,
  });

  final String id;
  final String name;
  final String unit;
  final String image;
  final String category;

  /// Fixed/MRP products use [mrp] as their customer-facing reference price.
  ///
  /// Fluctuating products use [averageNearbyPrice], which represents the
  /// calculated average of currently valid nearby retailer prices.
  final CustomerProductPricingType pricingType;
  final double? mrp;
  final double? averageNearbyPrice;

  bool get isFluctuating =>
      pricingType == CustomerProductPricingType.fluctuatingAverage;

  bool get isFixedMrp =>
      pricingType == CustomerProductPricingType.fixedMrp;

  double get referencePrice {
    if (isFluctuating) {
      return averageNearbyPrice ?? 0;
    }

    return mrp ?? 0;
  }

  String get referencePriceLabel {
    if (isFluctuating) {
      return 'Avg. Nearby Price';
    }

    return 'MRP';
  }

  String get formattedReferencePrice {
    final value = referencePrice;

    if (value == value.roundToDouble()) {
      return '₹${value.toInt()}';
    }

    return '₹${value.toStringAsFixed(2)}';
  }
}
