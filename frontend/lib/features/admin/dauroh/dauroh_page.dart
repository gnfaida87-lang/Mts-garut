import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'program/program_list_page.dart';
import 'musyrifah/musyrifah_list_page.dart';
import 'jadwal/jadwal_list_page.dart';
import 'qr/qr_dauroh_page.dart';
import 'monitoring/absensi_monitoring_page.dart';
import 'monitoring/nilai_monitoring_page.dart';

enum DaurohTab {
  program(label: 'Program Kegiatan', icon: Icons.book_outlined),
  musyrifah(label: 'Musyrifah', icon: Icons.people_outline),
  jadwal(label: 'Atur Jadwal', icon: Icons.calendar_month_outlined),
  qr(label: 'QR Code', icon: Icons.qr_code),
  monitoringAbsensi(label: 'Monitoring Absensi', icon: Icons.checklist_outlined),
  monitoringNilai(label: 'Monitoring Nilai', icon: Icons.grading_outlined);

  final String label;
  final IconData icon;
  const DaurohTab({required this.label, required this.icon});
}

class DaurohPage extends StatefulWidget {
  const DaurohPage({super.key});

  @override
  State<DaurohPage> createState() => _DaurohPageState();
}

class _DaurohPageState extends State<DaurohPage> {
  DaurohTab _selectedTab = DaurohTab.program;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Modul at-Ta\'wid',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.grey800)),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              _buildSidebar(),
              const VerticalDivider(width: 1),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: AppTheme.grey50,
        border: Border(right: BorderSide(color: AppTheme.grey200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Menu at-Ta\'wid',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.grey500,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 8),
              itemCount: DaurohTab.values.length,
              itemBuilder: (_, i) {
                final tab = DaurohTab.values[i];
                final isActive = _selectedTab == tab;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.primary.withValues(alpha: 0.1)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: Icon(
                      tab.icon,
                      size: 20,
                      color: isActive ? AppTheme.primary : AppTheme.grey500,
                    ),
                    title: Text(
                      tab.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.w600 : null,
                        color: isActive ? null : AppTheme.grey600,
                      ),
                    ),
                    selected: isActive,
                    onTap: () => setState(() => _selectedTab = tab),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedTab) {
      case DaurohTab.program:
        return const ProgramListPage();
      case DaurohTab.musyrifah:
        return const MusyrifahListPage();
      case DaurohTab.jadwal:
        return const JadwalListPage();
      case DaurohTab.qr:
        return const QrDaurohPage();
      case DaurohTab.monitoringAbsensi:
        return const AbsensiMonitoringPage();
      case DaurohTab.monitoringNilai:
        return const NilaiMonitoringPage();
    }
  }
}
