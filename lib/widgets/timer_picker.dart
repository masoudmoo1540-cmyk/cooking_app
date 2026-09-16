import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
class TimerPickerController {
  int hours = 0;
  int minutes = 0;
  int seconds = 0;
  
  void reset() {
    hours = 0;
    minutes = 0;
    seconds = 0;
  }
  
  int getTotalSeconds() {
    return hours * 3600 + minutes * 60 + seconds;
  }
}

class TimerPicker extends StatefulWidget {
  final TimerPickerController controller;
  
  const TimerPicker({
    super.key,
    required this.controller,
  });

  @override
  State<TimerPicker> createState() => _TimerPickerState();
}

class _TimerPickerState extends State<TimerPicker> {
  late int _hours;
  late int _minutes;
  late int _seconds;
  
  @override
  void initState() {
    super.initState();
    _hours = widget.controller.hours;
    _minutes = widget.controller.minutes;
    _seconds = widget.controller.seconds;
  }
  
  void _updateController() {
    widget.controller.hours = _hours;
    widget.controller.minutes = _minutes;
    widget.controller.seconds = _seconds;
  }
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final colors = themeProvider.getColors();
    final primaryColor = colors['primary'] as Color;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ساعت
          _buildTimePicker(
            value: _hours,
            onChanged: (value) {
              setState(() {
                _hours = value;
                _updateController();
              });
            },
            maxValue: 23,
            label: 'ساعت',
            icon: Icons.access_time,
          ),
          const Text(':', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          // دقیقه
          _buildTimePicker(
            value: _minutes,
            onChanged: (value) {
              setState(() {
                _minutes = value;
                _updateController();
              });
            },
            maxValue: 59,
            label: 'دقیقه',
            icon: Icons.timer,
          ),
          const Text(':', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          // ثانیه
          _buildTimePicker(
            value: _seconds,
            onChanged: (value) {
              setState(() {
                _seconds = value;
                _updateController();
              });
            },
            maxValue: 59,
            label: 'ثانیه',
            icon: Icons.timer_off,
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimePicker({
    required int value,
    required ValueChanged<int> onChanged,
    required int maxValue,
    required String label,
    required IconData icon,
  }) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: Colors.grey[600]),
              const SizedBox(height: 4),
              DropdownButton<int>(
                value: value,
                underline: const SizedBox(),
                items: List.generate(maxValue + 1, (i) => i).map((int v) {
                  return DropdownMenuItem<int>(
                    value: v,
                    child: Text(
                      v.toString().padLeft(2, '0'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) onChanged(newValue);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}