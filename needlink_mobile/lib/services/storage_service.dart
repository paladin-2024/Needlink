import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  StorageService._();

  static final _picker = ImagePicker();
  static final _client = Supabase.instance.client;

  /// Picks an image from the gallery, uploads it to [bucket] at [path],
  /// and returns the public URL. Returns null if the user cancels.
  static Future<String?> pickAndUpload({
    required String bucket,
    required String path,
    int imageQuality = 75,
    int maxWidth = 512,
  }) async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: imageQuality,
      maxWidth: maxWidth.toDouble(),
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    final ext = file.path.split('.').last.toLowerCase();
    final fullPath = '$path.$ext';

    await _client.storage.from(bucket).uploadBinary(
      fullPath,
      bytes,
      fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
    );

    return _client.storage.from(bucket).getPublicUrl(fullPath);
  }

  /// Uploads an avatar photo for [userId] and returns the public URL.
  static Future<String?> uploadAvatar(String userId) =>
      pickAndUpload(bucket: 'avatars', path: '$userId/avatar');

  /// Uploads an NGO logo for [ngoId] and returns the public URL.
  static Future<String?> uploadNgoLogo(String ngoId) =>
      pickAndUpload(bucket: 'logos', path: '$ngoId/logo', maxWidth: 512);

  /// Uploads delivery proof for [pledgeId] and returns the public URL.
  static Future<String?> uploadDeliveryProof(String pledgeId) =>
      pickAndUpload(bucket: 'delivery-proofs', path: '$pledgeId/proof', imageQuality: 80, maxWidth: 1024);
}
