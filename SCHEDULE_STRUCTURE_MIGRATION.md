# Migrasi Struktur Schedule Database

## Ringkasan Perubahan
Struktur database Firebase untuk `scheduleTime` telah diubah dari data yang disimpan di dalam struktur `modules` di koleksi `kelas` menjadi koleksi `schedules` yang terpisah.

## Struktur Lama
```
/kelas/{classId}
  ├── title
  ├── description
  ├── modules (array)
  │   └── [0]
  │       ├── name: "Modul 1"
  │       ├── fileUrl: "..."
  │       └── scheduleTime: "Senin, 20/06/2026 • 10:00"  ❌ Di sini
```

## Struktur Baru
```
/kelas/{classId}
  ├── title
  ├── description
  └── modules (array)
      └── [0]
          ├── name: "Modul 1"
          └── fileUrl: "..."

/schedules/{scheduleId}
  ├── classId: "kelas123"
  ├── moduleIndex: 0
  ├── moduleName: "Modul 1"
  ├── scheduleTime: "Senin, 20/06/2026 • 10:00" ✅ Di sini
  ├── createdAt: timestamp
  └── updatedAt: timestamp
```

## Keuntungan Struktur Baru
✅ **Scalable**: Mudah menambah multiple schedules per modul di masa depan
✅ **Terorganisir**: Data schedule terpisah dari struktur modul
✅ **Query Efisien**: Mudah query schedule berdasarkan classId atau moduleIndex
✅ **Update Ringan**: Tidak perlu update seluruh document kelas saat mengubah schedule
✅ **Maintainability**: Kode lebih terstruktur dan mudah di-maintain

## Fungsi Baru di FirestoreService

### `getSchedulesByClassId(String classId)`
Mengambil semua schedule untuk kelas tertentu dan mengembalikan Map dengan key=moduleIndex.

```dart
Map<int, Map<String, dynamic>> schedules = 
    await FirestoreService.getSchedulesByClassId(classId);
```

### `saveSchedule(String classId, int moduleIndex, String moduleName, String scheduleTime)`
Menyimpan atau mengupdate schedule untuk modul tertentu. Otomatis membuat dokumen baru atau update yang ada.

```dart
await FirestoreService.saveSchedule(
  classId: "kelas123",
  moduleIndex: 0,
  moduleName: "Modul 1",
  scheduleTime: "Senin, 20/06/2026 • 10:00",
);
```

### `deleteSchedule(String classId, int moduleIndex)`
Menghapus schedule untuk modul tertentu.

```dart
await FirestoreService.deleteSchedule(
  classId: "kelas123",
  moduleIndex: 0,
);
```

### `deleteAllSchedulesForClass(String classId)`
Menghapus semua schedule untuk kelas tertentu.

```dart
await FirestoreService.deleteAllSchedulesForClass(classId: "kelas123");
```

## Perubahan di MentorScheduleDetailPage

### State Variables
```dart
late Map<int, Map<String, dynamic>> _schedules = {}; // Schedules dari database
bool _isLoading = false; // Loading state saat fetch schedules
```

### initState
- Memanggil `_loadSchedules()` untuk mengambil semua schedule dari Firestore

### _loadSchedules()
- Fetch schedules dari koleksi `schedules` berdasarkan classId
- Update `_schedules` Map untuk ditampilkan di UI

### _editSchedule(int index)
- User memilih tanggal dan jam
- Langsung update UI local untuk feedback
- Call `_saveScheduleToFirestore()` untuk simpan ke database

### _removeSchedule(int index)
- Hapus schedule dari Map lokal
- Call `_deleteScheduleFromFirestore()` untuk hapus dari database

### _saveScheduleToFirestore(int moduleIndex, String scheduleTime)
- Memanggil `FirestoreService.saveSchedule()` untuk simpan ke koleksi `schedules`
- Menampilkan snackbar sukses atau error

### _deleteScheduleFromFirestore(int moduleIndex)
- Memanggil `FirestoreService.deleteSchedule()` untuk hapus dari koleksi `schedules`
- Menampilkan snackbar sukses atau error

### UI Rendering
- Mengambil schedule dari `_schedules[index]` bukan dari `_modules[index]['scheduleTime']`
- Loading indicator saat fetch schedules
- Saving indicator saat simpan/hapus schedule

## Flow Diagram

### Membuka Halaman Detail
```
1. Page dibuka → initState() dipanggil
2. initState() → _loadSchedules()
3. _loadSchedules() → FirestoreService.getSchedulesByClassId()
4. Ambil dari /schedules collection
5. Update _schedules Map
6. UI dirender dengan schedule yang sudah ada
```

### Edit Schedule
```
1. User tap "Edit Jadwal"
2. Pilih tanggal & jam
3. _editSchedule() dipanggil
4. Update UI local (_schedules[index])
5. Call _saveScheduleToFirestore()
6. FirestoreService.saveSchedule()
7. Cek apakah schedule sudah ada
8. Jika ada → update dokumen
9. Jika belum → buat dokumen baru
```

### Hapus Schedule
```
1. User tap "Hapus"
2. _removeSchedule() dipanggil
3. Hapus dari _schedules Map
4. Call _deleteScheduleFromFirestore()
5. FirestoreService.deleteSchedule()
6. Hapus dokumen dari /schedules
```

## Migration Path (Jika Ada Data Lama)

Jika sudah ada schedule yang disimpan di struktur lama (dalam modules), berikut script untuk migrasi:

```dart
Future<void> migrateOldSchedules() async {
  try {
    // Ambil semua kelas
    final classesSnapshot = await FirebaseFirestore.instance
        .collection('kelas')
        .get();
    
    for (final classDoc in classesSnapshot.docs) {
      final classData = classDoc.data();
      final modules = classData['modules'] as List? ?? [];
      
      // Iterasi setiap modul
      for (int i = 0; i < modules.length; i++) {
        final module = modules[i] as Map<String, dynamic>? ?? {};
        final scheduleTime = module['scheduleTime']?.toString() ?? '';
        
        // Jika ada scheduleTime lama, pindahkan ke koleksi baru
        if (scheduleTime.isNotEmpty) {
          await FirestoreService.saveSchedule(
            classDoc.id,
            i,
            module['name']?.toString() ?? 'Modul',
            scheduleTime,
          );
        }
      }
    }
    
    print('Migration completed!');
  } catch (e) {
    print('Migration error: $e');
  }
}
```

## Testing Checklist

- [ ] Buka halaman detail kelas
- [ ] Verifikasi semua schedule sudah terload
- [ ] Tambah schedule baru untuk modul pertama
- [ ] Verifikasi schedule muncul di UI
- [ ] Edit schedule tersebut
- [ ] Verifikasi perubahan muncul di UI dan Firestore
- [ ] Hapus schedule
- [ ] Verifikasi schedule hilang dari UI dan Firestore
- [ ] Buka halaman lain kemudian kembali ke detail kelas
- [ ] Verifikasi schedule masih ada (persist)

## Catatan Penting

1. **Backward Compatibility**: Struktur lama di `modules[].scheduleTime` tidak lagi digunakan. Data dari sini akan diabaikan.

2. **Performance**: Query menjadi lebih efisien karena schedule disimpan terpisah dalam koleksi khusus.

3. **Koleksi Indexes**: Untuk query optimal, pertimbangkan membuat composite index di Firestore untuk query `(classId, moduleIndex)`.

4. **Error Handling**: Semua operasi database memiliki error handling dengan snackbar feedback ke user.

## Files yang Diubah

1. **lib/services/firestore_service.dart**
   - Tambah: `getSchedulesByClassId()`
   - Tambah: `saveSchedule()`
   - Tambah: `deleteSchedule()`
   - Tambah: `deleteAllSchedulesForClass()`

2. **lib/pages/mentor_schedule_detail_page.dart**
   - Update: `_classData` dan `_modules` parsing
   - Tambah: `_schedules` Map
   - Tambah: `_isLoading` bool
   - Tambah: `_loadSchedules()`
   - Update: `_editSchedule()` - gunakan koleksi schedules
   - Update: `_removeSchedule()` - gunakan koleksi schedules
   - Tambah: `_saveScheduleToFirestore()`
   - Tambah: `_deleteScheduleFromFirestore()`
   - Hapus: `_saveSchedule()` (lama)
   - Update: UI rendering untuk ambil schedule dari `_schedules` Map
   - Update: Loading indicator saat fetch schedules
