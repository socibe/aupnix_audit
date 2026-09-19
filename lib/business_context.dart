class BusinessContext {
  BusinessContext._();

  static final BusinessContext instance = BusinessContext._();

  String? _businessId;

  String? get businessId => _businessId;

  bool get hasActiveBusiness => _businessId != null;

  void establish({
    required String businessId,
  }) {
    final normalizedBusinessId = businessId.trim();

    if (normalizedBusinessId.isEmpty) {
      throw ArgumentError.value(
        businessId,
        'businessId',
        'Business ID cannot be empty.',
      );
    }

    _businessId = normalizedBusinessId;
  }

  void clear() {
    _businessId = null;
  }
}
