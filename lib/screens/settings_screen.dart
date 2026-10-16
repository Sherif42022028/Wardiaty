import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/app_settings.dart';
import '../providers/attendance_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/wardiaty_logo_widget.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _currencyController;
  late TextEditingController _hoursController;
  late TextEditingController _rateController;
  double _overtimeMultiplier = 1.5;

  @override
  void initState() {
    super.initState();
    final settings = context.read<AttendanceProvider>().settings;
    _nameController = TextEditingController(text: settings.userName);
    _currencyController = TextEditingController(text: settings.currency);
    _hoursController = TextEditingController(text: settings.standardHours.toStringAsFixed(0));
    _rateController = TextEditingController(text: settings.defaultDailyRate.toStringAsFixed(0));
    _overtimeMultiplier = settings.overtimeMultiplier;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currencyController.dispose();
    _hoursController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  void _saveAllSettings() {
    final provider = context.read<AttendanceProvider>();
    final newSettings = AppSettings(
      userName: _nameController.text.trim().isEmpty ? 'محمد' : _nameController.text.trim(),
      currency: _currencyController.text.trim().isEmpty ? 'ج.م' : _currencyController.text.trim(),
      standardHours: double.tryParse(_hoursController.text.trim()) ?? 12.0,
      defaultDailyRate: double.tryParse(_rateController.text.trim()) ?? 300.0,
      overtimeMultiplier: _overtimeMultiplier,
    );

    provider.updateSettings(newSettings);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        content: Text(
          'تم حفظ الإعدادات بنجاح!',
          style: TextStyle(fontFamily: AppTheme.fontFamily),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Settings Form Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.tune_rounded, color: AppColors.primary, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'إعدادات الوردية والحسابات',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // User Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'اسم الموظف / صاحب الحساب',
                        prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Currency
                    TextFormField(
                      controller: _currencyController,
                      decoration: const InputDecoration(
                        labelText: 'رمز العملة',
                        hintText: 'مثال: ج.م، ريال، د.إ...',
                        prefixIcon: Icon(Icons.attach_money_rounded, color: AppColors.accentDark),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Standard Shift Hours & Default Daily Rate
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _hoursController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'ساعات الوردية الأساسية',
                              suffixText: 'ساعة',
                              prefixIcon: Icon(Icons.timer_outlined, color: AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _rateController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'اليومية الافتراضية',
                              suffixText: provider.settings.currency,
                              prefixIcon: const Icon(Icons.payments_outlined, color: AppColors.primary),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Overtime Multiplier Selector
                    const Text(
                      'معامل احتساب الساعة الإضافية:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [1.0, 1.25, 1.5, 2.0].map((mult) {
                        final isSel = (_overtimeMultiplier - mult).abs() < 0.01;
                        return ChoiceChip(
                          selected: isSel,
                          label: Text('${mult}x'),
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.background,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : AppColors.textPrimary,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            fontFamily: AppTheme.fontFamily,
                          ),
                          onSelected: (_) {
                            setState(() {
                              _overtimeMultiplier = mult;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveAllSettings,
                        icon: const Icon(Icons.check_circle_outline_rounded),
                        label: const Text('حفظ التعديلات'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Backup & Restore Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.backup_table_rounded, color: AppColors.secondary, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'النسخ الاحتياطي والاسترجاع (أوفلاين)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'يمكنك حفظ نسخة كاملة من سجلاتك وإعداداتك كملف JSON واسترجاعها في أي وقت بدون إنترنت.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        // Export Backup
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _exportBackup(context, provider),
                            icon: const Icon(Icons.file_upload_outlined, size: 18),
                            label: const Text('تصدير نسخة'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Import Backup
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _importBackup(context, provider),
                            icon: const Icon(Icons.file_download_outlined, size: 18),
                            label: const Text('استرجاع نسخة'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Demo Data & Data Wipe Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.science_outlined, color: AppColors.accentDark, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'إدارة البيانات والتجربة السريعة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'يمكنك ملء شهر تجريبي بـ 7 أيام متنوعة (12س، إضافي، عجز، إجازات) لاختبار كشف الحساب والتقارير فوراً.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),

                    // Load Demo Month Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          await provider.loadDemoData();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: AppColors.secondary,
                                behavior: SnackBarBehavior.floating,
                                content: Text(
                                  'تم تحميل بيانات الشهر التجريبي بنجاح! تفقد شاشة تقرير الشهر.',
                                  style: TextStyle(fontFamily: AppTheme.fontFamily),
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.auto_fix_high_rounded),
                        label: const Text('تحميل بيانات شهر تجريبي (7 أيام متنوعة)'),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Clear All Records Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.crimson,
                          side: const BorderSide(color: AppColors.crimson),
                        ),
                        onPressed: () => _confirmClearData(context, provider),
                        icon: const Icon(Icons.delete_forever_rounded),
                        label: const Text('مسح جميع السجلات'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // About App Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Column(
                children: [
                  WardiatyLogoWidget(size: 60, showText: true, useImage: true),
                  SizedBox(height: 12),
                  Text(
                    'الإصدار 1.0.0 • تطبيق أوفلاين بالكامل 100%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'تطبيق الحضور والانصراف واليومية الشخصية بنظام 12 ساعة',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context, AttendanceProvider provider) async {
    final jsonStr = provider.exportBackupJson();
    final bytes = utf8.encode(jsonStr);

    final xFile = XFile.fromData(
      Uint8List.fromList(bytes),
      mimeType: 'application/json',
      name: 'wardiaty_backup_${DateTime.now().millisecondsSinceEpoch}.json',
    );

    // Also copy to clipboard as convenience
    await Clipboard.setData(ClipboardData(text: jsonStr));

    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          text: 'نسخة احتياطية من تطبيق ورديتي',
        ),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم نسخ نص النسخة الاحتياطية إلى الحافظة بنجاح!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _importBackup(BuildContext context, AttendanceProvider provider) async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'txt'],
      );

      if (files.isNotEmpty) {
        final jsonStr = await files.first.xFile.readAsString();
        final success = await provider.importBackupJson(jsonStr);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: success ? AppColors.success : AppColors.crimson,
              content: Text(
                success ? 'تم استرجاع النسخة الاحتياطية بنجاح!' : 'الملف غير صالح أو تالف',
                style: const TextStyle(fontFamily: AppTheme.fontFamily),
              ),
            ),
          );
        }
        return;
      }

    } catch (_) {
      // Fallback: paste dialog
    }

    if (!context.mounted) return;
    _showPasteJsonDialog(context, provider);
  }


  void _showPasteJsonDialog(BuildContext context, AttendanceProvider provider) {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('استرجاع نسخة احتياطية (لصق JSON)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'الصق كود الـ JSON للنسخة الاحتياطية في الحقل التالي:',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              maxLines: 6,
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(
                hintText: '{"app": "Wardiaty", ...}',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await provider.importBackupJson(textController.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: success ? AppColors.success : AppColors.crimson,
                    content: Text(
                      success ? 'تم استرجاع البيانات بنجاح!' : 'صيغة البيانات غير صحيحة',
                      style: const TextStyle(fontFamily: AppTheme.fontFamily),
                    ),
                  ),
                );
              }
            },
            child: const Text('استرجاع'),
          ),
        ],
      ),
    );
  }

  void _confirmClearData(BuildContext context, AttendanceProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.crimson),
            SizedBox(width: 8),
            Text('تأكيد مسح جميع السجلات؟', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text(
          'سيتم حذف جميع سجلات الحضور والانصراف والورديات نهائياً من ذاكرة الهاتف. لن تتمكن من استعادتها إلا إذا كان لديك نسخة احتياطية.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimson),
            onPressed: () async {
              await provider.clearAllData();
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.crimson,
                    content: Text('تم مسح جميع السجلات بنجاح.'),
                  ),
                );
              }
            },
            child: const Text('نعم، امسح كل السجلات'),
          ),
        ],
      ),
    );
  }
}
