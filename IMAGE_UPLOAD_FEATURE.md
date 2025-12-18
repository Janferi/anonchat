# Fitur Upload Gambar di Chat

## 📋 Ringkasan
Fitur upload gambar telah ditambahkan ke private chat. User dapat mengirim gambar melalui gallery atau camera, dan gambar akan otomatis dikompres sebelum diupload.

## ✨ Fitur yang Ditambahkan

### 1. **Image Picker & Compression**
- Pilih gambar dari gallery atau ambil foto dari camera
- Otomatis resize gambar maksimal 1920x1920 pixel
- Kompresi gambar dengan quality 70% dan ukuran minimal 800x800 pixel
- Mengurangi ukuran file untuk menghemat bandwidth dan storage

### 2. **Upload ke Supabase Storage**
- Gambar disimpan di Supabase Storage bucket `chat-images`
- Struktur folder: `{userId}/{uniqueId}.{ext}`
- Public URL dikembalikan untuk disimpan di database

### 3. **Tampilan Chat**
- Gambar ditampilkan dalam bubble chat dengan ukuran 200x200 pixel
- Loading indicator saat gambar sedang dimuat
- Error placeholder jika gambar gagal dimuat
- Klik gambar untuk melihat fullscreen dengan zoom (InteractiveViewer)

### 4. **UI/UX**
- Tombol **+** di input chat untuk membuka pilihan upload
- Bottom sheet dengan opsi "Choose from Gallery" dan "Take a Photo"
- Loading spinner pada tombol + saat upload berlangsung
- Snackbar notification untuk status upload (success/error)

## 📁 File yang Ditambahkan/Diubah

### File Baru:
1. **`lib/services/image_service.dart`**
   - Service untuk handle image picking, compression, dan upload
   - Methods:
     - `pickImage()` - Pick dari gallery/camera
     - `compressImage()` - Kompres gambar
     - `uploadImage()` - Upload ke Supabase Storage
     - `pickCompressAndUpload()` - All-in-one method
     - `deleteImage()` - Hapus gambar dari storage

2. **`supabase_storage_setup.sql`**
   - SQL script untuk setup storage bucket dan policies
   - Harus dijalankan di Supabase Dashboard

3. **`IMAGE_UPLOAD_FEATURE.md`**
   - Dokumentasi lengkap fitur ini

### File yang Diubah:
1. **`pubspec.yaml`**
   - Tambah dependencies: `flutter_image_compress`, `path_provider`

2. **`lib/screens/private/private_chat_detail_screen.dart`**
   - Tambah import `image_picker` dan `image_service`
   - Tambah state `_isUploadingImage`
   - Tambah method `_buildImageMessage()` untuk tampilkan gambar
   - Tambah method `_showFullImage()` untuk fullscreen view
   - Tambah method `_showImagePickerOptions()` untuk pilihan upload
   - Tambah method `_pickAndSendImage()` untuk proses upload
   - Update tombol + dengan fungsi upload

3. **`lib/providers/private_chat_provider.dart`**
   - Tambah parameter `messageType` di method `sendMessage()`

4. **`lib/services/chat_service.dart`**
   - Sudah support `messageType` parameter ✅

5. **`lib/models/chat_message.dart`**
   - Sudah support field `messageType` ✅

## 🚀 Cara Setup

### 1. Setup Supabase Storage Bucket
Jalankan SQL script di Supabase Dashboard (SQL Editor):

```sql
-- Buka file supabase_storage_setup.sql dan jalankan isinya
```

Atau manual di Supabase Dashboard:
1. Buka **Storage** → Create bucket `chat-images`
2. Set bucket sebagai **Public**
3. Setup policies di **Policies** tab

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Permissions (Android)
Tambahkan di `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

### 4. Permissions (iOS)
Tambahkan di `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to take photos for chat</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need photo library access to send images in chat</string>
```

## 💡 Cara Menggunakan

1. **Buka Private Chat** dengan user lain
2. **Klik tombol +** di sebelah input message
3. **Pilih opsi**:
   - "Choose from Gallery" - Pilih gambar dari galeri
   - "Take a Photo" - Ambil foto dengan camera
4. **Tunggu upload** - Loading indicator akan muncul
5. **Gambar terkirim** - Muncul di chat bubble
6. **Klik gambar** untuk lihat fullscreen dengan zoom

## 🔒 Keamanan

- **Storage Policies**: User hanya bisa upload ke folder mereka sendiri (`{userId}/`)
- **Public Read**: Semua user bisa melihat gambar (untuk keperluan chat)
- **Delete Policy**: User hanya bisa hapus gambar mereka sendiri
- **Compression**: Gambar otomatis dikompres untuk mencegah file terlalu besar

## 📊 Spesifikasi Teknis

### Ukuran Gambar:
- **Max dimension saat pick**: 1920x1920 pixel
- **Min dimension setelah compress**: 800x800 pixel
- **Quality**: 70%
- **Thumbnail di chat**: 200x200 pixel

### Format:
- Support: JPG, PNG
- Output compression: JPG

### Storage:
- **Bucket**: `chat-images` (public)
- **Path**: `{userId}/{uuid}.{ext}`
- **Cache Control**: 3600 seconds (1 hour)

## 🐛 Troubleshooting

### Gambar tidak muncul?
- Cek Supabase Storage bucket sudah dibuat dan public
- Cek policies sudah di-setup dengan benar
- Cek internet connection

### Upload gagal?
- Cek permissions di AndroidManifest.xml / Info.plist
- Cek Supabase Storage quota
- Cek log error di console

### Gambar terlalu besar?
- Service sudah otomatis kompres gambar
- Jika masih besar, adjust parameter di `image_service.dart`:
  - Kurangi `quality` (default 70)
  - Kurangi `minWidth/minHeight` (default 800)

## 📝 TODO / Future Improvements

- [ ] Support video messages
- [ ] Multiple image selection
- [ ] Image editor (crop, filter, text)
- [ ] Progress bar untuk upload besar
- [ ] Cache gambar locally
- [ ] Delete gambar dari chat
- [ ] Image preview sebelum send
- [ ] Support GIF

## 📞 Support

Jika ada pertanyaan atau issue, silakan hubungi developer team.
