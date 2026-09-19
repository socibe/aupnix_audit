import 'package:flutter/foundation.dart';
import 'dart:math';

import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/business_image.dart';
import '../repositories/business_image_repository.dart';

class BusinessImageService {
  BusinessImageService._();

  static final BusinessImageService instance =
      BusinessImageService._();

  static const bucketName = 'business-images';
  static const maxOriginalBytes = 10 * 1024 * 1024;

  final ImagePicker _picker = ImagePicker();

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<XFile?> pickImage() {
    return _picker.pickImage(
      source: ImageSource.gallery,
    );
  }

  Future<Uint8List> processProfileImage(XFile file) async {
    return _process(
      file,
      targetWidth: 800,
      targetHeight: 800,
    );
  }

  Future<Uint8List> processBannerImage(XFile file) async {
    return _process(
      file,
      targetWidth: 1600,
      targetHeight: 533,
    );
  }

  Future<BusinessImage> uploadAndPersist({
    required String businessId,
    required String imageRole,
    required Uint8List processedBytes,
  }) async {
    if (imageRole != BusinessImage.profileRole &&
        imageRole != BusinessImage.bannerRole) {
      throw ArgumentError.value(
        imageRole,
        'imageRole',
        'Must be profile or banner.',
      );
    }

    final repository = BusinessImageRepository.instance;

    final previous = await repository.getBusinessImage(
      businessId: businessId,
      imageRole: imageRole,
    );

    final objectId = _objectId();
    final storageKey =
        'businesses/$businessId/$imageRole/$objectId.jpg';

    try {
      await _supabase.storage.from(bucketName).uploadBinary(
        storageKey,
        processedBytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: false,
        ),
      );
    } catch (_) {
      rethrow;
    }

    try {
      final persisted = await repository.upsertBusinessImage(
        businessId: businessId,
        storageKey: storageKey,
        imageRole: imageRole,
        altText: imageRole == BusinessImage.profileRole
            ? 'Store profile picture'
            : 'Store banner',
      );

      if (previous != null &&
          previous.storageKey != storageKey) {
        try {
          await deleteStorageObject(previous.storageKey);
        } catch (cleanupError, cleanupStack) {
          debugPrint(
            'AUPNIX_BUSINESS_IMAGE_OLD_OBJECT_CLEANUP_ERROR: '
            '$cleanupError',
          );
          debugPrint(
            'AUPNIX_BUSINESS_IMAGE_OLD_OBJECT_CLEANUP_STACK: '
            '$cleanupStack',
          );
        }
      }

      return persisted;
    } catch (_) {
      try {
        await deleteStorageObject(storageKey);
      } catch (cleanupError, cleanupStack) {
        debugPrint(
          'AUPNIX_BUSINESS_IMAGE_ORPHAN_CLEANUP_ERROR: '
          '$cleanupError',
        );
        debugPrint(
          'AUPNIX_BUSINESS_IMAGE_ORPHAN_CLEANUP_STACK: '
          '$cleanupStack',
        );
      }

      rethrow;
    }
  }

  Future<void> deleteStorageObject(String storageKey) async {
    await _supabase.storage.from(bucketName).remove([storageKey]);
  }
  Future<Uint8List> downloadImage(String storageKey) {
    return _supabase.storage.from(bucketName).download(storageKey);
  }

  String getPublicUrl(String storageKey) {
    return _supabase.storage
        .from(bucketName)
        .getPublicUrl(storageKey);
  }

  Future<Uint8List> _process(
    XFile file, {
    required int targetWidth,
    required int targetHeight,
  }) async {
    final bytes = await file.readAsBytes();

    if (bytes.length > maxOriginalBytes) {
      throw const FormatException(
        'The selected image is larger than 10 MB.',
      );
    }

    final decoded = img.decodeImage(bytes);

    if (decoded == null) {
      throw const FormatException(
        'The selected file is not a supported JPEG or PNG image.',
      );
    }

    final sourceRatio = decoded.width / decoded.height;

    final targetRatio = targetWidth / targetHeight;

    late img.Image cropped;

    if ((sourceRatio - targetRatio).abs() < 0.01) {
      cropped = decoded;
    } else if (sourceRatio > targetRatio) {
      final cropWidth = (decoded.height * targetRatio).round();
      final x = ((decoded.width - cropWidth) / 2).round();

      cropped = img.copyCrop(
        decoded,
        x: x,
        y: 0,
        width: cropWidth,
        height: decoded.height,
      );
    } else {
      final cropHeight = (decoded.width / targetRatio).round();
      final y = ((decoded.height - cropHeight) / 2).round();

      cropped = img.copyCrop(
        decoded,
        x: 0,
        y: y,
        width: decoded.width,
        height: cropHeight,
      );
    }

    final resized = img.copyResize(
      cropped,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.average,
    );

    return Uint8List.fromList(
      img.encodeJpg(
        resized,
        quality: 83,
      ),
    );
  }

  String _objectId() {
    final random = Random.secure();
    final timestamp = DateTime.now().microsecondsSinceEpoch;

    return '$timestamp-${random.nextInt(1 << 32).toRadixString(16)}';
  }
}



