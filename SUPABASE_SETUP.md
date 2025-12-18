# 🚀 Panduan Setup Supabase untuk AnonChat

## ✅ Langkah-langkah Setup

### 1. Import Database Schema ke Supabase

1. Buka dashboard Supabase di: https://supabase.com/dashboard
2. Login atau buat akun baru
3. Pilih project Anda (atau buat project baru)
4. Klik **SQL Editor** di menu sebelah kiri
5. Klik **New Query**
6. Copy seluruh isi file `supabase_schema.sql`
7. Paste ke SQL Editor
8. Klik **Run** atau tekan `Ctrl+Enter`
9. Tunggu hingga selesai (seharusnya muncul "Success. No rows returned")

### 2. Enable Realtime untuk Live Chat

Agar chat bisa realtime, aktifkan Realtime Replication:

1. Di dashboard Supabase, klik **Database** > **Replication**
2. Di bagian **Realtime**, aktifkan (toggle ON) untuk table berikut:
   - ✅ **messages**
   - ✅ **typing_status**
   - ✅ **users**
3. Klik **Save** jika diminta

### 3. Verifikasi Database

Pastikan semua table sudah terbuat:

1. Klik **Database** > **Tables**
2. Anda harus melihat 4 table:
   - ✅ `users`
   - ✅ `chat_rooms`
   - ✅ `messages`
   - ✅ `typing_status`

### 4. Test Koneksi Flutter

Jalankan aplikasi Flutter:

```bash
flutter run
```

Jika ada error koneksi, pastikan:
- Supabase URL dan Key sudah benar di `lib/config/supabase_config.dart`
- Internet aktif
- Database schema sudah di-import

---

## 📱 Cara Menggunakan Chat Supabase

### A. Registrasi User dengan Nomor Telepon

Gunakan screen registrasi yang sudah dibuat:

```dart
import 'package:anonchat/screens/phone_registration_screen.dart';

// Navigate ke registrasi
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const PhoneRegistrationScreen()),
);
```

Atau registrasi manual via code:

```dart
import 'package:anonchat/services/user_service.dart';

final userService = UserService();

// Register user dengan nomor telepon
final user = await userService.registerWithPhone('+6281234567890');
print('User ID: ${user.id}');
```

### B. Menampilkan Daftar User

Gunakan screen yang sudah dibuat:

```dart
import 'package:anonchat/screens/users_list_screen.dart';

// Navigate ke daftar user
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const UsersListScreen()),
);
```

### C. Membuka Chat Screen

Dari `UsersListScreen`, ketika user diklik, otomatis akan membuka chat screen:

```dart
// Sudah otomatis di UsersListScreen
// Klik user -> buka SupabaseChatScreen
```

### D. Edit Profil (Username & Avatar)

Di `UsersListScreen`, klik icon profil di AppBar untuk edit:

```dart
// Atau buka manual
import 'package:anonchat/screens/profile_edit_screen.dart';

final currentUser = await userService.getCurrentUser();
if (currentUser != null) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ProfileEditScreen(currentUser: currentUser),
    ),
  );
}
```

### E. Contoh Integrasi di Home Screen

Tambahkan button di `HomeScreen` untuk membuka registrasi atau daftar user:

```dart
// Jika belum login, buka registrasi
FloatingActionButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PhoneRegistrationScreen(),
      ),
    );
  },
  child: const Icon(Icons.login),
)

// Jika sudah login, buka daftar user
FloatingActionButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UsersListScreen(),
      ),
    );
  },
  child: const Icon(Icons.chat),
)
```

---

## 🔧 Struktur File yang Sudah Dibuat

```
lib/
├── config/
│   └── supabase_config.dart              # Konfigurasi URL & Key
├── models/
│   ├── chat_user.dart                    # Model user (phone_number, username, bio)
│   ├── chat_room.dart                    # Model room chat
│   └── chat_message.dart                 # Model pesan
├── services/
│   ├── supabase_service.dart             # Service utama Supabase
│   ├── user_service.dart                 # Manajemen user & registrasi
│   └── chat_service.dart                 # Manajemen chat & realtime
└── screens/
    ├── phone_registration_screen.dart    # Registrasi dengan nomor telepon
    ├── profile_edit_screen.dart          # Edit username, avatar, bio
    ├── users_list_screen.dart            # Daftar user untuk chat
    └── supabase_chat_screen.dart         # Screen chat realtime
```

---

## ⚡ Fitur-fitur yang Tersedia

### ✅ Yang Sudah Jalan:

1. **User Management**
   - ✅ Registrasi dengan nomor telepon
   - ✅ Username opsional (bisa diatur nanti)
   - ✅ Edit profil (username, avatar, bio)
   - ✅ Update status online/offline
   - ✅ Avatar bisa dipilih dari 20+ opsi

2. **Chat Realtime**
   - Kirim pesan realtime
   - Terima pesan realtime tanpa reload
   - Tampilan bubble chat (kiri/kanan)
   - Timestamp pada setiap pesan

3. **Read Receipts**
   - Centang 1 (✓) = terkirim
   - Centang 2 (✓✓) = sudah dibaca
   - Auto mark as read ketika buka chat

4. **Typing Indicator**
   - Muncul "User is typing..." saat lawan chat mengetik
   - Hilang otomatis saat berhenti mengetik

5. **User List**
   - Daftar semua user yang terdaftar
   - Status online/offline realtime
   - Avatar & username
   - Pull to refresh

---

## 🎯 Cara Testing

### Test dengan 2 Device:

1. **Device 1:**
   - Buka aplikasi
   - Buka `PhoneRegistrationScreen`
   - Register dengan nomor: **081234567890**
   - (Opsional) Edit profil, set username "User1"
   - Buka `UsersListScreen`

2. **Device 2:**
   - Buka aplikasi
   - Buka `PhoneRegistrationScreen`
   - Register dengan nomor: **081234567891**
   - (Opsional) Edit profil, set username "User2"
   - Buka `UsersListScreen`

3. **Device 1:**
   - Pilih "User2" dari list
   - Kirim pesan "Halo dari Device 1"

4. **Device 2:**
   - Pilih "User1" dari list
   - Harusnya langsung muncul pesan "Halo dari Device 1" ✅
   - Balas "Halo juga dari Device 2"

5. **Device 1:**
   - Pesan balasan langsung muncul tanpa reload ✅

### Test Typing Indicator:

1. Di chat screen, mulai ketik pesan
2. Di device lain, harusnya muncul "User is typing..."
3. Berhenti mengetik -> indikator hilang

---

## 🐛 Troubleshooting

### Error: "Supabase not initialized"
**Solusi:** Pastikan `SupabaseService.initialize()` dipanggil di `main.dart`

### Pesan tidak muncul realtime
**Solusi:**
1. Pastikan Realtime sudah di-enable di Supabase Dashboard
2. Cek koneksi internet
3. Restart aplikasi

### User tidak bisa register
**Solusi:**
1. Cek RLS (Row Level Security) di Supabase
2. Pastikan policy `Users can insert their own data` aktif

### "No users found"
**Solusi:**
- Buka aplikasi di 2 device berbeda dengan nomor telepon berbeda
- Atau manual insert user di Supabase SQL Editor:

```sql
INSERT INTO users (phone_number, username, avatar_url, is_online)
VALUES
  ('+6281234567890', 'Test User 1', 'https://i.pravatar.cc/150?img=1', true),
  ('+6281234567891', 'Test User 2', 'https://i.pravatar.cc/150?img=2', true);
```

---

## 📚 API Reference

### UserService

```dart
// Register with phone number
final user = await userService.registerWithPhone('+6281234567890');

// Get current user
final currentUser = await userService.getCurrentUser();

// Update profile (username, avatar, bio)
final updatedUser = await userService.updateProfile(
  userId: currentUser.id,
  username: 'New Username',
  avatarUrl: 'https://i.pravatar.cc/150?img=5',
  bio: 'My new bio',
);

// Get all users
final users = await userService.getAllUsers(excludeUserId: 'user-id');

// Update online status
await userService.updateOnlineStatus('user-id', true);

// Logout
await userService.logout();
```

### ChatService

```dart
final chatService = ChatService();

// Get or create chat room
final room = await chatService.getOrCreateChatRoom('user1-id', 'user2-id');

// Send message
await chatService.sendMessage(
  chatRoomId: room.id,
  senderId: currentUser.id,
  receiverId: otherUser.id,
  messageText: 'Hello!',
);

// Get messages
final messages = await chatService.getMessages(room.id);

// Subscribe to realtime messages
chatService.subscribeToMessages(room.id);
chatService.messagesStream.listen((messages) {
  // Update UI dengan messages baru
});

// Update typing status
await chatService.updateTypingStatus(
  chatRoomId: room.id,
  userId: currentUser.id,
  isTyping: true,
);
```

---

## 🎨 Customization

### Mengubah Warna Bubble Chat

Edit file `supabase_chat_screen.dart`:

```dart
// Line ~260
decoration: BoxDecoration(
  color: isMe ? Colors.blue : Colors.grey[300], // Ganti warna di sini
  borderRadius: BorderRadius.circular(20),
),
```

### Mengubah Avatar

Edit `user_service.dart`:

```dart
// Line ~80
'avatar_url': 'https://i.pravatar.cc/150?img=$avatarIndex',
// Ganti dengan URL avatar custom atau generator lain
```

---

## ✨ Next Steps (Opsional)

Fitur yang bisa ditambahkan:

1. **Image/File Sharing**
   - Upload ke Supabase Storage
   - Tampilkan gambar di chat bubble

2. **Group Chat**
   - Buat table `groups` dan `group_members`
   - Modifikasi chat_service untuk support group

3. **Push Notifications**
   - Integrasi Firebase Cloud Messaging
   - Trigger notification saat ada pesan baru

4. **Message Reactions**
   - Table `message_reactions`
   - Emoji reactions pada pesan

5. **Voice Messages**
   - Record audio dengan `record` package
   - Upload ke Supabase Storage

---

## 📞 Support

Jika ada masalah:

1. Cek Supabase Logs: Dashboard > Logs
2. Cek Flutter console untuk error messages
3. Pastikan semua dependencies ter-install: `flutter pub get`

---

**Selamat Chat-ing! 🎉**
