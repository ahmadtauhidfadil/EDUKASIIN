# 📋 GUIDE: Migrasi ScheduleTime ke Koleksi Schedules

## 🎯 Tujuan
Memindahkan semua `scheduleTime` dari struktur `modules` ke koleksi `schedules` yang lebih terstruktur dan scalable.

---

## 📊 Perubahan Struktur

### SEBELUM (Struktur Lama) ❌
```
/kelas
  ├── {classId}
      ├── title: "Kelas Bahasa Inggris"
      ├── description: "..."
      └── modules (array)
          └── [0]
              ├── name: "Modul 1"
              ├── fileUrl: "..."
              └── scheduleTime: "Senin, 20/06/2026 • 10:00"  ⚠️ Disini (Problem!)
```

### SESUDAH (Struktur Baru) ✅
```
/kelas
  ├── {classId}
      ├── title: "Kelas Bahasa Inggris"
      ├── description: "..."
      └── modules (array)
          └── [0]
              ├── name: "Modul 1"
              └── fileUrl: "..."

/schedules  📁 (Koleksi Baru)
  ├── {scheduleId}
      ├── classId: "kelas123"
      ├── moduleIndex: 0
      ├── moduleName: "Modul 1"
      ├── scheduleTime: "Senin, 20/06/2026 • 10:00"  ✅ Disini (Lebih Baik!)
      ├── createdAt: timestamp
      └── updatedAt: timestamp
```

---

## 🚀 Cara Menjalankan Migrasi

### Opsi 1: Migrasi Lengkap (RECOMMENDED) ⭐⭐⭐
Langkah paling aman yang melakukan verifikasi penuh:
```dart
await ScheduleMigrationUtil.runCompleteMigration(context: context);
```

**Apa yang dilakukan:**
1. ✅ Verifikasi data sebelum migrasi
2. ✅ Pindahkan semua scheduleTime ke koleksi schedules
3. ✅ Bersihkan (hapus) scheduleTime dari modules
4. ✅ Verifikasi hasil migrasi
5. ✅ Tampilkan statistik lengkap

**Keuntungan:**
- Aman dan terverifikasi
- Tidak ada data orphaned
- Sempurna untuk production

---

### Opsi 2: Hanya Migrasi (tanpa Cleanup)
Pindahkan data tanpa menghapus yang lama:
```dart
await ScheduleMigrationUtil.migrateOnly(context: context);
```

**Kapan digunakan:**
- Untuk testing sebelum cleanup
- Jika ingin keep backup struktur lama
- Untuk staged migration

**Output:**
- Schedules berhasil dibuat
- Data lama tetap ada di modules

---

### Opsi 3: Hanya Cleanup
Hapus scheduleTime yang sudah lama dari modules:
```dart
await ScheduleMigrationUtil.cleanupOnly(context: context);
```

**Kapan digunakan:**
- Setelah migrasi berhasil & terverifikasi
- Membersihkan data yang sudah tidak diperlukan

**Catatan Penting:** ⚠️
> Gunakan ini HANYA setelah memastikan semua scheduleTime sudah ada di koleksi schedules!

---

### Opsi 4: Verifikasi Saja
Cek status tanpa mengubah data:
```dart
await ScheduleMigrationUtil.verifyAndShow(context: context);
```

**Hasil:**
- Jumlah jadwal yang perlu dimigrasi
- Detail masing-masing jadwal
- Identifikasi kelas dan modul yang affected

---

## 🎮 User Interface: Halaman Migrasi

### Mengakses Halaman Migrasi
1. Navigasi ke halaman admin
2. Buka `ScheduleMigrationPage`

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const ScheduleMigrationPage()),
);
```

### Fitur di Halaman
- ✅ Verifikasi data sebelum migrasi
- ✅ Migrasi lengkap dengan 1 klik
- ✅ Advanced options untuk kontrol granular
- ✅ Progress indicators
- ✅ Error messages yang jelas
- ✅ Success summary

---

## 📈 Statistik Migrasi

Setiap proses migrasi akan menampilkan:

```
✅ Migration Result:
   • Schedules Created: 45
   • Schedules Skipped: 0
   • Classes Updated: 15
   • Modules Updated: 45
   • Errors: 0

✅ Final Verification:
   • Total Classes: 20
   • Orphaned Schedules: 0
```

---

## ⚙️ Fungsi-Fungsi di FirestoreService

### 1. Migrasi
```dart
/// Migrate scheduleTime from modules to schedules collection
Future<Map<String, dynamic>> migrateScheduleTimesToSchedulesCollection()
```
**Returns:**
- `schedulesCreated`: jumlah schedule baru dibuat
- `schedulesSkipped`: yang sudah ada (duplikat)
- `errors`: jumlah error
- `errorMessages`: detail error

---

### 2. Cleanup
```dart
/// Remove scheduleTime from all modules
Future<Map<String, dynamic>> removeScheduleTimeFromModules()
```
**Returns:**
- `classesUpdated`: jumlah kelas diupdate
- `modulesUpdated`: jumlah modul dibersihkan
- `errors`: jumlah error

---

### 3. Verifikasi
```dart
/// Check for orphaned scheduleTime in modules
Future<Map<String, dynamic>> verifyMigration()
```
**Returns:**
- `orphanedSchedules`: jumlah schedule lama masih ada
- `orphanedDetails`: list detail setiap schedule
- `classesWithOrphanedSchedules`: jumlah kelas affected

---

## 🔄 Workflow Lengkap

```
┌─────────────────────────────────┐
│ 1. Verifikasi Data Awal         │
│ (Check berapa banyak data)      │
└────────────────┬────────────────┘
                 │
                 ▼
┌─────────────────────────────────┐
│ 2. Migrasi Data                 │
│ (Pindahkan ke schedules)        │
└────────────────┬────────────────┘
                 │
                 ▼
┌─────────────────────────────────┐
│ 3. Cleanup Data Lama            │
│ (Hapus dari modules)            │
└────────────────┬────────────────┘
                 │
                 ▼
┌─────────────────────────────────┐
│ 4. Verifikasi Akhir             │
│ (Konfirmasi migrasi berhasil)   │
└────────────────┬────────────────┘
                 │
                 ▼
        ✅ SELESAI
```

---

## 🛡️ Precautions

### SEBELUM Menjalankan Migrasi:
1. **BACKUP DATABASE!** ⚠️
   - Export Firestore data
   - Buat snapshot
   
2. **Test di Staging** 🧪
   - Jangan langsung di production
   - Verifikasi terlebih dahulu
   
3. **Check Koneksi Internet** 🌐
   - Migrasi membutuhkan koneksi stabil
   - Hindari offline/VPN yang bermasalah

---

## 📋 Checklist Migrasi

- [ ] Backup Firestore database
- [ ] Test di development environment
- [ ] Jalankan verifikasi awal
- [ ] Jalankan migrasi lengkap
- [ ] Monitor progress
- [ ] Verifikasi hasil
- [ ] Update aplikasi untuk menggunakan struktur baru
- [ ] Test halaman detail jadwal
- [ ] Monitor production untuk errors
- [ ] Dokumentasi lengkap selesai

---

## 🐛 Troubleshooting

### Error: "Gagal memuat jadwal"
**Solusi:**
- Periksa koneksi internet
- Pastikan permission Firestore OK
- Jalankan verifikasi untuk cek status

### Error: "Orphaned schedules masih ada setelah cleanup"
**Solusi:**
- Jalankan cleanup lagi
- Cek logs untuk detail error
- Hubungi admin jika persist

### Data tidak muncul di halaman detail
**Solusi:**
- Refresh halaman (pull-to-refresh)
- Cek apakah migrasi berhasil
- Verifikasi schedule ada di Firestore

---

## 📝 Aplikasi yang Sudah Updated

### FirestoreService (firestore_service.dart)
- ✅ `migrateScheduleTimesToSchedulesCollection()`
- ✅ `removeScheduleTimeFromModules()`
- ✅ `verifyMigration()`
- ✅ `getSchedulesByClassId()`
- ✅ `saveSchedule()`
- ✅ `deleteSchedule()`

### MentorScheduleDetailPage (mentor_schedule_detail_page.dart)
- ✅ Load schedules dari koleksi baru
- ✅ Simpan/update schedule di koleksi baru
- ✅ Hapus schedule dari koleksi baru
- ✅ Loading indicator saat fetch

### Admin Page (schedule_migration_page.dart)
- ✅ UI untuk jalankan migrasi
- ✅ Multiple opsi (migrate, cleanup, verify)
- ✅ Progress tracking
- ✅ Error handling

### Migration Utility (schedule_migration_util.dart)
- ✅ Helper functions untuk migrasi
- ✅ Dialog management
- ✅ Progress reporting

---

## ✅ Setelah Migrasi Selesai

1. **Update UI jika diperlukan**
   - Halaman detail sudah updated ✓
   - Halaman edit sudah updated ✓

2. **Monitor Aplikasi**
   - Cek logs untuk errors
   - Verifikasi jadwal tampil dengan benar

3. **User Communication**
   - Inform users tentang improvement
   - Jadwal sekarang lebih reliable

4. **Remove Old Code** (optional)
   - Hapus logic yang ambil dari `modules[].scheduleTime`
   - Tapi bisa keep untuk backward compatibility

---

## 📞 Support

Jika ada masalah:
1. Cek Firestore console
2. Lihat browser console untuk errors
3. Jalankan verifikasi untuk diagnose
4. Hubungi admin dengan logs

---

**Last Updated:** 2026-06-19
**Version:** 1.0
**Status:** ✅ Ready for Production
