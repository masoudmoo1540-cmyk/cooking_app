import 'package:flutter/material.dart';
import '../services/permission_service.dart';

/// صفحه‌ای که فقط بار اول اجرای اپ نشون داده می‌شه و مجوزهای لازم برای
/// اجرای تایمر در پس‌زمینه رو از کاربر می‌گیره — دقیقاً مثل روشن کردن
/// بلوتوث از توی خود اپ (کاربر رو مستقیم می‌بره سراغ تنظیم مربوطه).
class PermissionSetupView extends StatefulWidget {
  final VoidCallback onFinished;
  const PermissionSetupView({super.key, required this.onFinished});

  @override
  State<PermissionSetupView> createState() => _PermissionSetupViewState();
}

class _PermissionSetupViewState extends State<PermissionSetupView>
    with WidgetsBindingObserver {
  bool _batteryDone = false;
  bool _alarmDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // وقتی کاربر از تنظیمات برمی‌گرده به اپ، وضعیت رو دوباره چک کن
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshStatus();
    }
  }

  Future<void> _refreshStatus() async {
    final battery = await PermissionService.isBatteryOptimizationIgnored();
    final alarm = await PermissionService.isExactAlarmGranted();
    if (!mounted) return;
    setState(() {
      _batteryDone = battery;
      _alarmDone = alarm;
    });
  }

  Future<void> _handleBattery() async {
    await PermissionService.requestIgnoreBatteryOptimization();
    await _refreshStatus();
  }

  Future<void> _handleAlarm() async {
    await PermissionService.requestExactAlarm();
    await PermissionService.requestNotificationPermission();
    await _refreshStatus();
  }

  Future<void> _handleAutoStart() async {
    await PermissionService.openXiaomiAutoStartSettings();
  }

  Future<void> _finish() async {
    await PermissionService.markSetupDone();
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              const Icon(Icons.timer, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                'برای اینکه تایمر و نوتیفیکیشن حتی وقتی اپ رو کامل می‌بندی '
                'درست کار کنن، ۲ تنظیم سریع لازمه:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 28),
              _buildStepCard(
                icon: Icons.battery_charging_full,
                title: '۱. غیرفعال کردن بهینه‌سازی باتری',
                subtitle: 'اجازه بده اپ حتی با صفحه خاموش فعال بمونه',
                done: _batteryDone,
                onTap: _handleBattery,
              ),
              const SizedBox(height: 14),
              _buildStepCard(
                icon: Icons.alarm,
                title: '۲. مجوز زنگ دقیق و نوتیفیکیشن',
                subtitle: 'برای اینکه تایمر دقیقاً سر وقت زنگ بزنه',
                done: _alarmDone,
                onTap: _handleAlarm,
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _handleAutoStart,
                icon: const Icon(Icons.rocket_launch),
                label: const Text(
                  'اگه گوشی شیائومی داری، اینم بزن (Autostart)',
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _finish,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('ادامه به اپ', style: TextStyle(fontSize: 16)),
              ),
              TextButton(
                onPressed: _finish,
                child: const Text('رد کردن (بعداً از تنظیمات هم می‌شه فعال کرد)'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool done,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: done ? Colors.green : Colors.orange, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: done
            ? const Icon(Icons.check_circle, color: Colors.green)
            : ElevatedButton(onPressed: onTap, child: const Text('فعال کن')),
      ),
    );
  }
}
