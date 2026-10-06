# MacAndFiles

<img src="../../Resources/Icon/AppIcon-master.png" width="128" alt="MacAndFiles app icon">

[English](../../README.md) · [한국어](README.ko.md) · [简体中文](README.zh-Hans.md) · [繁體中文](README.zh-Hant.md) · [Español](README.es.md) · [Português](README.pt-BR.md) · [日本語](README.ja.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Русский](README.ru.md) · [हिन्दी](README.hi.md) · [Bahasa Indonesia](README.id.md) · [العربية](README.ar.md)

Aplikasi SwiftUI native untuk transfer file USB antara Android dan Mac Apple Silicon. UI minimal bergaya Finder, warna aksen sistem, pencarian native, dan Liquid Glass. Dipasang terpisah dari Google Android File Transfer.

## Persyaratan dan pemasangan

Memerlukan **Apple Silicon / arm64 dan macOS 14.0 atau lebih baru**. Diverifikasi pada macOS 27.2 dan Galaxy Z Fold7; macOS 28, Intel, dan perangkat lain belum diverifikasi. Jalankan `dist/MacAndFiles.app` setelah build atau ekstrak ZIP dan pindahkan aplikasi ke Applications. libmtp/libusb disertakan; Homebrew dan Android Studio tidak diperlukan untuk menjalankan. Build pengembangan bertanda tangan ad-hoc, tanpa Developer ID atau notarization.

## Hubungkan dan gunakan

Hubungkan dengan kabel data USB, buka kunci Android, dan pilih “Transfer File / Android Auto”. Tutup Android File Transfer, Agent-nya, dan aplikasi MTP lain. Cari perangkat, pilih, lalu hubungkan. Debugging USB atau ADB tidak diperlukan. Klik ganda folder; ⌘D menyimpan ke Mac, ⌘U mengirim ke Android; file Finder juga bisa diseret. ⌘↑ naik, ⌘⇧N membuat folder, ⌘R menyegarkan. ⌘F hanya mencari nama di folder saat ini; hapus atau Esc mengembalikan daftar. Item tersembunyi oleh pencarian tidak lagi dipilih. Lainnya memuat bantuan, putus koneksi, dan diagnostik. Periksa nama file sebelum membagikan log.

## Bahasa

Mengikuti bahasa pilihan macOS dan bahasa per aplikasi di Pengaturan Sistem → Umum → Bahasa & Wilayah. Jalankan ulang setelah perubahan. Ada 13 bahasa; bahasa lain memakai Inggris. Tanggal, ukuran, dan persentase mengikuti wilayah. Nama file dan perangkat tetap; diagnostik pustaka mungkin tetap berbahasa Inggris.

## Perilaku transfer

Nama yang sudah ada menghentikan operasi tanpa menimpa. Unduhan ditulis ke file sementara dan diperiksa ukurannya sebelum nama akhir; unggahan memeriksa ukuran dari Android. Pembatalan atau kegagalan mempertahankan yang selesai dan mungkin menyisakan file parsial di Android. Folder disalin rekursif hingga kedalaman 128; tautan simbolis dan file khusus ditolak. Progres mencakup file dan byte seluruh operasi. Hanya konten MTP yang dapat diakses; hapus, ganti nama, dan pemasangan volume Finder belum tersedia.

## Build dan verifikasi

Memerlukan Swift 6.2+, SDK macOS 26+, libmtp 1.1.23, dan libusb 1.0.30. Skrip memeriksa versi dan SHA-256 sumber serta menyertakan pustaka dinamis dan sumbernya. Arsip sumber mengecualikan build dan diagnostik pribadi. Perintah berikut hanya diagnostik baca-saja, bukan CLI file umum atau MCP. `--verify-transfer` menulis file uji UUID: putuskan GUI, gunakan hanya perangkat uji yang diizinkan, dan periksa sisa file.

```sh
brew install pkg-config
scripts/test.sh
scripts/test-localization.sh
scripts/test-cli.sh
scripts/test-progress.sh
scripts/build-app.sh
scripts/package-source.sh
```

```sh
"dist/MacAndFiles.app/Contents/MacOS/MacAndFiles" --diagnose
"dist/MacAndFiles.app/Contents/MacOS/MacAndFiles" --probe
```

## Lisensi dan kontribusi

Kode, skrip, dokumentasi: **MIT**. Robot Android: **CC BY 3.0**. libmtp/libusb: **LGPL-2.1-or-later**. Pertahankan lisensi dan pemberitahuan. Android adalah merek Google LLC; ini bukan aplikasi resmi. MacAndFiles adalah nama pengembangan; tinjau merek dan notarization sebelum publikasi. README Inggris adalah referensi teknis lengkap. Baca AGENT.md untuk berkontribusi. Alur ini belum menerbitkan ke GitHub.

[English reference](../../README.md) · [Validation](../../VALIDATION.md) · [LICENSE](../../LICENSE) · [Third-party notices](../../THIRD_PARTY_NOTICES.md) · [AGENT.md](../../AGENT.md) · [Release guide](../RELEASING.md) · [Localization guide](../LOCALIZATION.md)

## Terminal dan agen

Setelah memasang aplikasi, pasang `maf` dengan `scripts/install-cli.sh`. Dapatkan ID melalui `maf devices` dan `maf storages --device "ID"`. Lihat `maf help` dan [panduan CLI](../CLI.md) untuk daftar berkas, unggah, unduh, dan membuat folder. Hasil berupa JSON; kegagalan mengembalikan kode kesalahan dan status keluar bukan nol. Putuskan perangkat di GUI sebelum memakai CLI.

```sh
maf help
maf devices
maf storages --device "DEVICE_ID"
maf ls --device "DEVICE_ID" --storage 65537 --path /Download
```

## 1.0.0 (9)

Dibangun untuk macOS 14+. Diuji pada macOS 27.2; versi lama masih perlu validasi perangkat nyata. Liquid Glass di macOS 26+.

Lihat total file, file selesai, kemajuan keseluruhan, kecepatan rata-rata dan perkiraan waktu tersisa. File selesai tetap aman saat transfer berhenti.

Pasang maf melalui Lainnya → Terminal dan agen. Tambahkan ~/.local/bin ke PATH bila perlu. Putuskan GUI sebelum operasi file CLI.

maf memakai mesin yang sama: hasil JSON, kode kesalahan stabil dan status sesi USB yang jelas untuk skrip dan agen.

[MacAndFiles](https://macandfiles.pages.dev/id/) · [CLI](../CLI.md) · [Release](../RELEASING.md)
