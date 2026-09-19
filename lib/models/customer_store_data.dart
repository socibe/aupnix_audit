class CustomerStoreData {
  const CustomerStoreData({
    required this.businessId,
    required this.businessStatus,
    required this.displayName,
    this.description,
    this.contactPhone,
    this.contactEmail,
    required this.locationId,
    required this.locationStatus,
    required this.addressLine1,
    this.addressLine2,
    this.locality,
    required this.city,
    required this.state,
    required this.countryCode,
    this.postalCode,
    this.latitude,
    this.longitude,
    required this.isPrimary,
  });

  final String businessId;
  final String businessStatus;

  final String displayName;
  final String? description;
  final String? contactPhone;
  final String? contactEmail;

  final String locationId;
  final String locationStatus;

  final String addressLine1;
  final String? addressLine2;
  final String? locality;
  final String city;
  final String state;
  final String countryCode;
  final String? postalCode;

  final double? latitude;
  final double? longitude;

  final bool isPrimary;
}
