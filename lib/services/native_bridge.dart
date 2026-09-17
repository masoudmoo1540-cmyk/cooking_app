import 'package:flutter/services.dart';

/// پل ارتباطی با کد بومی اندروید (MainActivity.kt) برای تبدیل مسیر فایل
/// به یه content:// URI که سیستم اندروید (بدون نیاز به اجرای اپ) بتونه بخونتش.
/// این برای پخش خودکار صدای دلخواه کاربر روی نوتیفیکیشن، حتی وقتی اپ کاملاً
/// بسته/کشته شده، لازمه.
class NativeBridge {
  static const MethodChannel _channel =
      MethodChannel('app.custom_sound/file_provider');

  /// مسیر فایل داخلی اپ (مثلاً .../custom_sounds/custom_123.mp3) رو به یه
  /// content:// URI قابل دسترس برای سیستم تبدیل می‌کنه.
  /// اگه چیزی اشتباه بشه (مثلاً هنوز FileProvider توی اندروید ست نشده)، null برمی‌گردونه.
  static Future<String?> getContentUriForFile(String filePath) async {
    try {
      final uri = await _channel.invokeMethod<String>(
        'getUriForFile',
        {'path': filePath},
      );
      return uri;
    } catch (e) {
      return null;
    }
  }
}
