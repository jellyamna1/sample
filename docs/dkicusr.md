# DKICUSR - Penjelasan Program CRUD Nasabah

Source: `qrpglesrc/dkicusr.rpgle` (member `AMNA1/QRPGLESRC(DKICUSR)`)

`DKICUSR` adalah **program utama aplikasi CRUD nasabah Bank DKI**. Program ini menampilkan layar,
membaca input user, lalu **menambah / mengubah / menampilkan / menghapus** data di file `DKICUSP`.

Analogi: seperti **kasir di loket bank**. Ia menunjukkan daftar nasabah, menunggu Anda memilih,
mengerjakan permintaan Anda, lalu kembali menunjukkan daftar yang sudah diperbarui.

Program ini dipanggil lewat CL `DKICUSC`:

```
CALL AMNA1/DKICUSC
```

---

## 1. Bagian Persiapan (baris 1-73)

### Header (baris 1-17)
Komentar berisi nama program, fungsi, file yang dipakai, dan riwayat perubahan (modification log).
Seperti "kartu identitas" program.

### Pengaturan program - `ctl-opt` (baris 19)
- Setiap dipanggil, program berjalan di "ruang" sendiri (`actgrp(*new)`).
- Pesan error menunjuk ke nomor baris source (`option(*srcstmt)`), jadi mudah di-debug.

### File yang dipakai (baris 26-28)

| File | Jenis | Fungsi |
|---|---|---|
| `DKICUSP` | PF (tabel) | Data nasabah. Bisa dibaca, ditambah, diubah, dihapus |
| `DKICUSL1` | LF (index) | Data nasabah diurutkan per No Telepon, hanya dibaca. Dipakai untuk cek No Telepon ganda dengan cepat. Field-nya diberi awalan `L1_` supaya tidak tertukar dengan field `DKICUSP` |
| `DKICUSD` | DSPF (layar) | Layar daftar dan layar detail. `DKISFL` = daftar baris nasabah (subfile), `wRrn` = nomor barisnya |

### Indikator layar - `dspInd` (baris 33)
"Saklar" on/off yang menghubungkan program dengan layar. Masing-masing diberi nama supaya mudah dibaca:

| Nama | Indikator | Arti |
|---|---|---|
| `exit` | 03 | User menekan F3 (keluar) |
| `refresh` | 05 | User menekan F5 (muat ulang) |
| `add` | 06 | User menekan F6 (tambah) |
| `cancel` | 12 | User menekan F12 (kembali) |
| `sflDsp`, `sflDspCtl`, `sflClr`, `sflEnd` | 31-34 | Mengatur tampil / kosongkan daftar (subfile) |
| `protect` | 40 | Field di layar detail dikunci (tidak bisa diketik) |
| `confirmDel` | 41 | Tampilkan tulisan konfirmasi hapus |
| `errNama`, `errAlamat`, `errTlp` | 50-52 | Field disorot karena isinya salah |

### Konstanta (baris 52 dst.)
Nilai tetap yang diberi nama, supaya tidak ada "angka ajaib" di code:

| Konstanta | Nilai | Arti |
|---|---|---|
| `MODE_ADD` / `MODE_CHG` / `MODE_DSP` / `MODE_DLT` | `A` / `C` / `D` / `X` | Mode layar detail: tambah / ubah / tampil / hapus |
| `OPT_CHG` / `OPT_DLT` / `OPT_DSP` | `2` / `4` / `5` | Opsi yang diketik user di layar daftar |
| `ST_DUPKEY` | `01021` | Kode error: ID sudah dipakai |
| `ST_LOCKED` | `01218` | Kode error: data sedang dipakai user lain |
| `MAX_RETRY` | `3` | Maksimal percobaan ulang saat ID bentrok |
| `TLP_CHARS` | `0123456789+-() ` | Karakter yang boleh di No Telepon |
| `DIGITS` | `0123456789` | Karakter angka, untuk menghitung digit No Telepon |
| `TLP_MIN_DIGIT` | `10` | Minimal jumlah digit angka No Telepon |

---

## 2. Alur Utama (baris 78-99)

```
1. Isi daftar nasabah dari tabel            -> loadSubfile()
2. Ulangi sampai user tekan F3:
     tampilkan layar daftar, tunggu input    -> exfmt DKICTL
     F5    -> muat ulang daftar
     F6    -> buka layar Tambah
     Enter -> proses opsi 2 / 4 / 5 yang diketik
3. Selesai, tutup program                   -> *inlr = *on
```

---

## 3. Procedure (fungsi-fungsi kecil)

| Procedure | Baris | Tugasnya (sederhana) |
|---|---|---|
| `loadSubfile` | 104 | Kosongkan daftar di layar, lalu baca semua nasabah dari tabel (urut ID) dan masukkan satu per satu ke daftar. Kalau kosong, tampilkan "Belum ada data nasabah" |
| `processOptions` | 139 | Cek baris mana yang diisi opsi oleh user (2 / 4 / 5), lalu buka layar detail sesuai opsinya |
| `showDetail` | 165 | Tampilkan layar detail satu nasabah. Untuk Tampil dan Hapus field dikunci. Setelah user tekan Enter, panggil fungsi simpan / ubah / hapus |
| `validInput` | 240 | Periksa input: Nama dan Alamat wajib diisi, No Telepon dicek oleh `checkPhone`. Kalau salah, field disorot dan pesan error tampil |
| `checkPhone` | 270 | Validasi No Telepon: wajib diisi, hanya angka dan `+ - ( )`, minimal 10 digit angka, dan belum dipakai nasabah lain |
| `countDigits` | 297 | Hitung jumlah angka 0-9 di No Telepon (`+ - ( )` dan spasi tidak dihitung) |
| `phoneOwner` | 319 | Cari di `DKICUSL1` apakah No Telepon sudah dipakai nasabah lain. Saat Ubah, nasabah yang sedang diubah tidak dihitung |
| `addCustomer` | 342 | Simpan nasabah baru. ID dibuat otomatis (ID terbesar + 1). Kalau ID bentrok karena dua user menambah bersamaan, coba lagi sampai 3 kali |
| `updateCustomer` | 371 | Kunci record nasabah, lalu ubah Nama, Alamat, Telepon |
| `deleteCustomer` | 399 | Kunci record nasabah, lalu hapus |
| `nextId` | 424 | Cari ID nasabah terbesar di tabel, kembalikan ID + 1 |
| `lockMessage` | 439 | Buat pesan error yang ramah, misalnya "Data sedang dipakai user lain, coba lagi." |

---

## 4. Validasi Input (Tambah & Ubah)

| Field | Aturan | Pesan kalau salah |
|---|---|---|
| Nama | Wajib diisi | "Nama wajib diisi." |
| Alamat | Wajib diisi | "Alamat wajib diisi." |
| No Telepon | Wajib diisi, hanya angka `0-9`, spasi, dan `+ - ( )` | "No telepon wajib diisi, hanya angka dan + - ( )." |
| No Telepon | Minimal 10 digit angka | "No telepon minimal 10 digit angka." |
| No Telepon | Tidak boleh sama dengan nasabah lain | "No telepon sudah dipakai nasabah ID n." |

Kalau salah, data tidak disimpan, field yang salah disorot dan kursor pindah ke field itu.
Pengecekan No Telepon ganda membandingkan teks persis, jadi `0812-3456-7890` dan `081234567890`
dianggap berbeda.

---

## 5. Praktik yang Dipakai

- **`read(n)` / `chain(n)`**: saat hanya melihat data, record **tidak dikunci**. User lain tetap
  bisa mengubah data walaupun Anda sedang membuka layar.
- **Record dikunci tepat sebelum diubah / dihapus** dengan `chain(e)`. Kalau sedang dipakai orang
  lain, program tidak crash tapi menampilkan pesan.
- **Indikator bernama** (`dspInd.sflDsp`), bukan `*IN31` dan sejenisnya, jadi code mudah dibaca.
- **Konstanta** untuk mode, opsi, dan kode status, bukan angka langsung di logika.
- **Satu procedure untuk satu tugas**, jadi kalau ada bug lebih mudah dicari bagiannya.

---

## 6. Object Terkait

| Object | Tipe | Source |
|---|---|---|
| `DKICUSC` | PGM (CLLE) - entry point | `qclsrc/dkicusc.clle` |
| `DKICUSR` | PGM (RPGLE) - program ini | `qrpglesrc/dkicusr.rpgle` |
| `DKICUSD` | DSPF - layar | `qddssrc/dkicusd.dspf` |
| `DKICUSP` | PF - data nasabah | `qddssrc/dkicusp.pf` |
| `DKICUSL1` | LF - nasabah per No Telepon | `qddssrc/dkicusl1.lf` |

Diagram alur: lihat `docs/uml/dki-crud-activity.puml`, `docs/uml/dki-crud-detail-activity.puml`,
dan `docs/uml/dki-crud-sequence.puml`.
