import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/meal_suggestion_service.dart';
import '../../widgets/background_image.dart';

class NotificationSettingsView extends StatefulWidget {
  const NotificationSettingsView({super.key});

  @override
  State<NotificationSettingsView> createState() =>
      _NotificationSettingsViewState();
}

class _NotificationSettingsViewState extends State<NotificationSettingsView> {
  bool _enabled = false;
  TimeOfDay? _time1;
  TimeOfDay? _time2;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await MealSuggestionService.isEnabled();
    final times = await MealSuggestionService.getSavedTimes();
    
    setState(() {
      _enabled = enabled;
      _time1 = times['time1'];
      _time2 = times['time2'];
      _loading = false;
    });
  }

  Future<void> _pickTime(int which) async {
    final initial = which == 1
        ? (_time1 ?? const TimeOfDay(hour: 11, minute: 0))
        : (_time2 ?? const TimeOfDay(hour: 17, minute: 0));
    
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: which == 1 ? 'ساعت اول' : 'ساعت دوم',
      cancelText: 'لغو',
      confirmText: 'تایید',
    );
    
    if (picked != null) {
      setState(() {
        if (which == 1) {
          _time1 = picked;
        } else {
          _time2 = picked;
        }
      });
    }
  }

  Future<void> _saveAndEnable() async {
    if (_time1 == null || _time2 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً هر دو ساعت رو انتخاب کن')),
      );
      return;
    }

    final success = await MealSuggestionService.enableSuggestions(
      time1: _time1!,
      time2: _time2!,
    );

    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('اول باید حداقل یه غذا اضافه کنی!'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _enabled = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ پیشنهاد غذا فعال شد'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _disable() async {
    await MealSuggestionService.disableSuggestions();
    setState(() {
      _enabled = false;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ پیشنهاد غذا غیرفعال شد'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  String _formatTime(TimeOfDay? t) {
    if (t == null) return 'انتخاب نشده';
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.getColors();
    final primaryColor = colors['primary'] as Color;
    final textColor = colors['text_color'] as Color;
    final cardBg = colors['card_bg'] as Color;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return BackgroundImage(
      fallbackColor: colors['bgcolor'] as Color,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('پیشنهاد غذا'),
          centerTitle: true,
          backgroundColor: primaryColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 2,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.notifications_active, size: 40, color: primaryColor),
                      const SizedBox(height: 10),
                      Text(
                        'پیشنهاد غذاهای روزانه',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'دو ساعت در روز انتخاب کن. سر هر ساعت، برنامه ازت می‌پرسه که کدوم غذا رو بپزی. حتی اگه برنامه بسته باشه، این نوتیفیکیشن کار می‌کنه.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              _buildTimeCard(
                title: '⏰ ساعت اول',
                time: _time1,
                onTap: () => _pickTime(1),
                cardBg: cardBg,
                textColor: textColor,
                primaryColor: primaryColor,
              ),
              const SizedBox(height: 12),

              _buildTimeCard(
                title: '⏰ ساعت دوم',
                time: _time2,
                onTap: () => _pickTime(2),
                cardBg: cardBg,
                textColor: textColor,
                primaryColor: primaryColor,
              ),
              const SizedBox(height: 20),

              if (!_enabled)
                ElevatedButton.icon(
                  onPressed: _saveAndEnable,
                  icon: const Icon(Icons.check),
                  label: const Text('فعال کن'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                )
              else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'پیشنهاد غذا فعاله',
                          style: TextStyle(color: textColor),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _disable,
                  icon: const Icon(Icons.close),
                  label: const Text('غیرفعال کن'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    minimumSize: const Size(0, 50),
                  ),
                ),
              ],
              const SizedBox(height: 12),

              TextButton.icon(
                onPressed: () async {
                  await MealSuggestionService.sendTestNotification();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('نوتیفیکیشن تست فرستاده شد')),
                    );
                  }
                },
                icon: const Icon(Icons.send),
                label: const Text('ارسال نوتیفیکیشن تست'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeCard({
    required String title,
    required TimeOfDay? time,
    required VoidCallback onTap,
    required Color cardBg,
    required Color textColor,
    required Color primaryColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: time != null ? primaryColor : Colors.grey[300]!,
            width: time != null ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 16, color: textColor),
              ),
            ),
            Text(
              _formatTime(time),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: time != null ? primaryColor : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}