import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mts_garut/features/admin/master_data/widgets/mapel_kelas_picker.dart';
import 'package:mts_garut/shared/models/guru_mapel_kelas_model.dart';

void main() {
  const mapelList = [
    {'id': 1, 'nama': 'Matematika'},
    {'id': 2, 'nama': 'Bahasa Indonesia'},
  ];
  const kelasList = [
    {'id': 1, 'nama': 'X IPA 1'},
    {'id': 2, 'nama': 'X IPA 2'},
  ];

  testWidgets('mapel lama tidak hilang saat menambah mapel baru', (tester) async {
    List<GuruMapelKelas> assignments = [];
    final collected = <List<GuruMapelKelas>>[];

    Widget build() => MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return MapelKelasPicker(
                  mapelList: mapelList,
                  kelasList: kelasList,
                  assignments: assignments,
                  onChanged: (value) {
                    collected.add(value);
                    setState(() => assignments = value);
                  },
                );
              },
            ),
          ),
        );

    // Fase 1: form dibuka (assignments masih kosong saat load).
    await tester.pumpWidget(build());
    await tester.pump();

    // Fase 2: data aset yang sudah tersimpan dimuat dari server (mapel 1).
    assignments = const [
      GuruMapelKelas(guruId: 1, mataPelajaranId: 1, kelasId: 1),
    ];
    await tester.pumpWidget(build());
    await tester.pump();

    // Mapel 1 harus tampil.
    expect(find.text('Matematika'), findsOneWidget);

    // Fase 3: tambah mapel baru.
    await tester.tap(find.text('Tambah Mapel'));
    await tester.pump();

    // Fase 4: pilih mapel 2 pada baris baru.
    final dropdowns = find.byType(DropdownButtonFormField<int>);
    expect(dropdowns, findsNWidgets(2));
    final dropdown2 = tester.widget<DropdownButtonFormField<int>>(dropdowns.at(1));
    dropdown2.onChanged!(2);
    await tester.pump();

    // Kedua mapel harus tetap tampil.
    expect(find.text('Matematika'), findsOneWidget);
    expect(find.text('Bahasa Indonesia'), findsOneWidget);

    // Fase 5: pilih kelas untuk baris mapel 2, lalu hasil assignment mencakup keduanya.
    final chips = find.byType(FilterChip);
    // baris 1 (mapel 1) punya 2 chip kelas, baris 2 (mapel 2) punya 2 chip kelas.
    final chipX2 = tester.widgetList<FilterChip>(chips).toList()[2];
    chipX2.onSelected!(true);
    await tester.pump();

    final last = collected.last;
    final mapelIds = last.map((a) => a.mataPelajaranId).toSet();
    expect(mapelIds, containsAll([1, 2]));
  });

  testWidgets('data server yang tiba belakangan di-merge, mapel lama tidak hilang',
      (tester) async {
    List<GuruMapelKelas> assignments = [];
    final collected = <List<GuruMapelKelas>>[];

    Widget build() => MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return MapelKelasPicker(
                  mapelList: mapelList,
                  kelasList: kelasList,
                  assignments: assignments,
                  onChanged: (value) {
                    collected.add(value);
                    setState(() => assignments = value);
                  },
                );
              },
            ),
          ),
        );

    // Buka form (masih loading, assignments kosong).
    await tester.pumpWidget(build());
    await tester.pump();

    // User langsung menambah mapel 2 sebelum data server tiba.
    await tester.tap(find.text('Tap untuk menambah mata pelajaran'));
    await tester.pump();
    final dropdowns1 = find.byType(DropdownButtonFormField<int>);
    final d1 = tester.widget<DropdownButtonFormField<int>>(dropdowns1.first);
    d1.onChanged!(2);
    await tester.pump();

    // Data server (mapel 1) tiba belakangan -> harus di-merge, bukan menimpa.
    assignments = const [
      GuruMapelKelas(guruId: 1, mataPelajaranId: 1, kelasId: 1),
    ];
    await tester.pumpWidget(build());
    await tester.pump();

    expect(find.text('Matematika'), findsOneWidget);
    expect(find.text('Bahasa Indonesia'), findsOneWidget);

    final dropdowns = find.byType(DropdownButtonFormField<int>);
    expect(dropdowns, findsNWidgets(2));
  });

  test('fromJson menerima bentuk respons backend (tanpa guru_id)', () {
    final row = GuruMapelKelas.fromJson(const {
      'id': 10,
      'mata_pelajaran_id': 1,
      'mapel_nama': 'Matematika',
      'kelas_id': 2,
      'kelas_nama': 'X IPA 2',
    });
    expect(row.id, 10);
    expect(row.guruId, isNull);
    expect(row.mataPelajaranId, 1);
    expect(row.kelasId, 2);
    expect(row.mapelNama, 'Matematika');
    expect(row.kelasNama, 'X IPA 2');
  });
}