import 'package:murmur3/murmur3.dart';

// class UrlHash {
//   /// Generates 32-bit integer `id` from string `url` by hash function.
//   static Future<int> hashUrlToInt(String url) async {
//     final BigInt hash128 = await murmur3f(url); // 128-bit hash
//     final int hash32 = hash128.toSigned(32).toInt(); // Convert to 32-bit int
//     return hash32.abs();
//   }
// }

extension StringExtension on String {
  Future<int> get hashUrl async {
    final BigInt hash128 = await murmur3f(this); // 128-bit hash
    final int hash32 = hash128.toSigned(32).toInt(); // Convert to 32-bit int
    return hash32.abs();
  }

  /// True for a fetchable http(s) URL. Tells real links and thumbnails apart
  /// from the synthetic schedule keys (image://, text://, manual://) and
  /// from plain text — Uri.tryParse accepts almost anything, hence the
  /// explicit scheme, host and whitespace checks.
  bool get isHttpUrl {
    final Uri? uri = Uri.tryParse(this);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty &&
        !contains(RegExp(r'\s'));
  }
}
