import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';

class BulkUploadConfig {
  final String title;
  final double dialogWidth;
  final String Function(Map<String, dynamic> row) primaryLabel;
  final String Function(Map<String, dynamic> row)? secondaryLabel;
  final String Function(Map<String, dynamic> row)? tertiaryLabel;
  final List<String> saveFields;
  final String bulkEndpoint;
  final VoidCallback onSaved;

  const BulkUploadConfig({
    required this.title,
    this.dialogWidth = 700,
    required this.primaryLabel,
    this.secondaryLabel,
    this.tertiaryLabel,
    required this.saveFields,
    required this.bulkEndpoint,
    required this.onSaved,
  });
}

class BulkUploadDialog extends StatelessWidget {
  final BulkUploadConfig config;
  final List<Map<String, dynamic>> rows;

  const BulkUploadDialog({
    super.key,
    required this.config,
    required this.rows,
  });

  static Future<void> show({
    required BuildContext context,
    required BulkUploadConfig config,
    required List<Map<String, dynamic>> rows,
  }) {
    return showDialog(
      context: context,
      builder: (_) => BulkUploadDialog(config: config, rows: rows),
    );
  }

  @override
  Widget build(BuildContext context) {
    final validCount = rows.where((r) => r['valid'] == true).length;
    final errorCount = rows.length - validCount;
    final hasErrors = errorCount > 0;

    return AlertDialog(
      title: Text('${config.title} (${rows.length} baris)'),
      content: SizedBox(
        width: config.dialogWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$validCount valid, $errorCount error',
                style: TextStyle(
                  color: hasErrors ? AppTheme.error : AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...rows.map((r) => _buildRow(r)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
        if (validCount > 0)
          FilledButton(
            onPressed: () => _onSave(context),
            child: Text('Simpan $validCount Data'),
          ),
      ],
    );
  }

  Widget _buildRow(Map<String, dynamic> r) {
    final isValid = r['valid'] == true;
    final isUpdate = r['is_update'] == true;
    final errors = r['errors'] is List ? (r['errors'] as List) : [];

    // Waya berbeda: biru untuk insert, oranye untuk update, merah untuk error
    Color bgColor;
    Color borderColor;
    if (!isValid) {
      bgColor = AppTheme.error.withValues(alpha: 0.05);
      borderColor = AppTheme.error.withValues(alpha: 0.2);
    } else if (isUpdate) {
      bgColor = Colors.orange.withValues(alpha: 0.05);
      borderColor = Colors.orange.withValues(alpha: 0.2);
    } else {
      bgColor = AppTheme.primary.withValues(alpha: 0.05);
      borderColor = AppTheme.primary.withValues(alpha: 0.2);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${r['row']}',
              style: const TextStyle(fontSize: 11, color: AppTheme.grey500),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.primaryLabel(r),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                if (config.secondaryLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    config.secondaryLabel!(r),
                    style: const TextStyle(fontSize: 12, color: AppTheme.grey600),
                  ),
                ],
                if (config.tertiaryLabel != null)
                  Text(
                    config.tertiaryLabel!(r),
                    style: const TextStyle(fontSize: 12, color: AppTheme.grey600),
                  ),
                if (errors.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      errors.join('; '),
                      style: const TextStyle(fontSize: 12, color: AppTheme.error),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const int _chunkSize = 50;

  Future<void> _onSave(BuildContext context) async {
    final hasValid = await ApiClient.hasValidSession();
    if (!hasValid) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi telah berakhir. Silakan login kembali.')),
      );
      Navigator.pop(context);
      ApiClient.onSessionExpired?.call();
      return;
    }

    final validRows = rows
        .where((r) => r['valid'] == true)
        .map((r) {
          final map = <String, dynamic>{};
          for (final field in config.saveFields) {
            map[field] = r[field] ?? '';
          }
          return map;
        })
        .toList();

    if (validRows.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data valid untuk disimpan.')),
      );
      return;
    }

    int totalInserted = 0;
    int totalUpdated = 0;
    final allErrors = <dynamic>[];
    bool hasAuthError = false;

    try {
      for (var i = 0; i < validRows.length; i += _chunkSize) {
        final chunk = validRows.sublist(
          i,
          i + _chunkSize > validRows.length ? validRows.length : i + _chunkSize,
        );

        final res = await ApiClient.post(config.bulkEndpoint, body: {'data': chunk})
            .timeout(const Duration(seconds: 120));
        final result = res['data'] as Map<String, dynamic>;
        totalInserted += (result['inserted'] as int?) ?? 0;
        totalUpdated += (result['updated'] as int?) ?? 0;
        allErrors.addAll((result['errors'] as List?) ?? []);
      }

      if (!context.mounted) return;

      Navigator.pop(context);

      final parts = <String>[];
      if (totalInserted > 0) parts.add('$totalInserted ditambahkan');
      if (totalUpdated > 0) parts.add('$totalUpdated diupdate');
      if (allErrors.isNotEmpty) parts.add('${allErrors.length} gagal');

      final msg = StringBuffer('Berhasil: ${parts.join(', ')}');
      if (allErrors.isNotEmpty) {
        final firstErrors = allErrors.take(3).map((e) {
          final row = e['row'] ?? '?';
          final err = e['error'] ?? 'Unknown error';
          return '  Row $row: $err';
        }).join('\n');
        msg.write('\n$firstErrors');
        if (allErrors.length > 3) msg.write('\n  ...dan ${allErrors.length - 3} lainnya');
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg.toString()),
        duration: const Duration(seconds: 5),
      ));
      config.onSaved();
    } on TimeoutException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Timeout: Server memproses terlalu lama (>120 detik). Coba dengan jumlah baris lebih sedikit.')),
      );
    } on ApiException catch (e) {
      if (e.statusCode == 401) hasAuthError = true;
      if (!context.mounted) return;
      if (hasAuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesi telah berakhir. Silakan login kembali.')),
        );
        Navigator.pop(context);
        ApiClient.onSessionExpired?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal simpan: $e')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal simpan: $e')),
      );
    }
  }
}
