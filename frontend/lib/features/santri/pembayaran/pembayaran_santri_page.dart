import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../services/santri_service.dart';
import '../../../shared/widgets/common_widgets.dart';

class PembayaranSantriPage extends StatefulWidget {
  const PembayaranSantriPage({super.key});

  @override
  State<PembayaranSantriPage> createState() => _PembayaranSantriPageState();
}

class _PembayaranSantriPageState extends State<PembayaranSantriPage> {
  final _service = SantriService();

  List<Map<String, dynamic>> _grouped = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final res = await _service.getPembayaran();
      final grouped = (res['grouped'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (mounted) {
        setState(() {
          _grouped = grouped;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case '*':
        return AppTheme.teal;
      case '**':
        return AppTheme.orange;
      case '***':
        return AppTheme.error;
default:
        return AppTheme.grey600;
      }
    }

  String _getStatusLabel(String status) {
    switch (status) {
      case '*':
        return 'Lunas';
      case '**':
        return 'Proses';
      case '***':
        return 'Belum Bayar';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              const Text('Idarat al-Madfu\'at',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.grey800)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => _load(refresh: true),
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading && _grouped.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error.isNotEmpty) {
      return _buildErrorState();
    }
    if (_grouped.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => _load(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _grouped.length,
        itemBuilder: (_, i) => _buildJenisCard(_grouped[i]),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
          const SizedBox(height: 16),
          Text('Gagal memuat data', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(_error, style: const TextStyle(color: AppTheme.grey600), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _load(refresh: true),
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          ),
        ]),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const EmptyState(
      icon: Icons.account_balance_wallet_outlined,
      message: 'Belum ada data pembayaran',
    );
  }

  Widget _buildJenisCard(Map<String, dynamic> jenis) {
    final periods = (jenis['periods'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final jenisNama = jenis['jenis_nama'] as String? ?? '-';
    final jenisKode = jenis['jenis_kode'] as String? ?? '';

    return Card(
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: AppTheme.grey200),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.receipt_long, size: 24, color: AppTheme.primary),
        ),
        title: Text(
          jenisNama,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Text(
          '${periods.length} periode',
          style: const TextStyle(fontSize: 12, color: AppTheme.grey600),
        ),
        trailing: Text(
          jenisKode,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primary),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          ...periods.map((p) => _buildPeriodRow(p)),
          if (periods.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('Belum ada periode', style: TextStyle(color: AppTheme.grey500)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPeriodRow(Map<String, dynamic> p) {
    final status = p['status'] as String? ?? '***';
    final label = p['label'] as String? ?? '-';
    final tanggalBayar = p['tanggal_bayar'] as String?;
    final catatan = p['catatan'] as String?;

    final color = _getStatusColor(status);
    final statusLabel = _getStatusLabel(status);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          // Period info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
                      ),
                    ),
                  ],
                ),
                if (catatan != null && catatan.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    catatan,
                    style: const TextStyle(fontSize: 11, color: AppTheme.grey600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // Date only
          if (tanggalBayar != null && tanggalBayar.isNotEmpty)
            Text(
              'Bayar: ${_formatDate(tanggalBayar)}',
              style: const TextStyle(fontSize: 10, color: AppTheme.grey500),
            ),
        ],
      ),
    );
  }
}