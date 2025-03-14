import 'package:murmur3/murmur3.dart';

class UrlHash {
  /// Generates 32-bit integer `id` from string `url` by hash function.
  static Future<int> hashUrlToInt(String url) async {
    final BigInt hash128 = await murmur3f(url); // 128-bit hash
    final int hash32 = hash128.toSigned(32).toInt(); // Convert to 32-bit int
    return hash32.abs();
  }
}
