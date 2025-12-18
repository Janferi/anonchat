# Hide Blocked Users from Chat List

## 📋 Fitur Baru: Sembunyikan Chat dengan User yang Diblokir

Setelah user memblokir user lain, chat room dengan user yang diblokir akan **otomatis disembunyikan** dari chat list.

## ✅ Implementasi

### File yang Diubah:
**`lib/services/chat_service.dart`** - Method `getChatRoomsWithUsers()`

### Perubahan:

#### **Sebelum:**
```dart
Future<List<Map<String, dynamic>>> getChatRoomsWithUsers(String userId) async {
  final rooms = await _supabase.chatRooms
      .select('*, messages(*)')
      .or('user1_id.eq.$userId,user2_id.eq.$userId')
      .order('last_message_at', ascending: false);

  final List<Map<String, dynamic>> roomsWithUsers = [];

  for (var room in rooms) {
    final roomData = ChatRoom.fromJson(room);
    final otherUserId = roomData.getOtherUserId(userId);

    // Get other user data
    final userData = await _supabase.users
        .select()
        .eq('id', otherUserId)
        .single();

    final otherUser = ChatUser.fromJson(userData);

    // ... rest of code ...

    roomsWithUsers.add({
      'room': roomData,
      'otherUser': otherUser,
      'lastMessage': lastMessage,
      'unreadCount': unreadCount,
    });
  }

  return roomsWithUsers;
}
```

**Masalah:** Chat room dengan user yang diblokir masih muncul di chat list.

---

#### **Setelah:**
```dart
Future<List<Map<String, dynamic>>> getChatRoomsWithUsers(String userId) async {
  final rooms = await _supabase.chatRooms
      .select('*, messages(*)')
      .or('user1_id.eq.$userId,user2_id.eq.$userId')
      .order('last_message_at', ascending: false);

  // ✅ Get list of blocked users by current user
  final blockedUsersData = await _supabase.userBlocks
      .select('blocked_id')
      .eq('blocker_id', userId);

  final blockedUserIds = blockedUsersData
      .map((block) => block['blocked_id'] as String)
      .toSet();

  final List<Map<String, dynamic>> roomsWithUsers = [];

  for (var room in rooms) {
    final roomData = ChatRoom.fromJson(room);
    final otherUserId = roomData.getOtherUserId(userId);

    // ✅ Skip if other user is blocked by current user
    if (blockedUserIds.contains(otherUserId)) {
      continue; // 🚫 Skip room ini!
    }

    // Get other user data (hanya untuk user yang TIDAK diblokir)
    final userData = await _supabase.users
        .select()
        .eq('id', otherUserId)
        .single();

    final otherUser = ChatUser.fromJson(userData);

    // ... rest of code ...

    roomsWithUsers.add({
      'room': roomData,
      'otherUser': otherUser,
      'lastMessage': lastMessage,
      'unreadCount': unreadCount,
    });
  }

  return roomsWithUsers;
}
```

**Perbaikan:**
1. ✅ **Fetch blocked users** - Ambil semua user yang diblokir oleh current user dari tabel `user_blocks`
2. ✅ **Filter chat rooms** - Skip chat room jika `otherUserId` ada di list blocked users
3. ✅ **Clean chat list** - Hanya tampilkan chat dengan user yang TIDAK diblokir

## 🔄 Alur Kerja

### Saat User Blokir User Lain:

```
1. User buka private chat dengan user lain
2. User klik menu (⋮) → Block User
3. Pilih reason (Harassment, Spam, dll)
4. Klik "Send Report"
5. ✅ Data tersimpan ke tabel user_blocks:
   - blocker_id: ID user yang memblokir
   - blocked_id: ID user yang diblokir
   - reason: Alasan blokir
6. ✅ User kembali ke chat list
7. ✅ Chat room dengan user yang diblokir HILANG dari list
```

### Saat Load Chat List:

```
1. App fetch chat rooms dari database
2. ✅ App fetch blocked users dari user_blocks table
3. ✅ Untuk setiap chat room:
   - Cek apakah otherUserId ada di blocked list
   - Jika YA → SKIP (tidak ditambahkan ke list)
   - Jika TIDAK → Tambahkan ke list
4. ✅ Tampilkan hanya chat dengan user yang TIDAK diblokir
```

## 🎯 Query Database

### Query untuk Get Blocked Users:
```sql
SELECT blocked_id
FROM user_blocks
WHERE blocker_id = 'current_user_id'
```

**Result:** List of user IDs yang diblokir oleh current user

### Query untuk Get Chat Rooms (dengan filter):
```sql
SELECT * FROM chat_rooms
WHERE user1_id = 'current_user_id' OR user2_id = 'current_user_id'
ORDER BY last_message_at DESC
```

**Processing:**
- Untuk setiap room, cek `otherUserId`
- Jika `otherUserId IN (blocked_user_ids)` → SKIP
- Jika tidak → Include dalam result

## 📱 User Experience

### Sebelum Blokir:
```
Chat List:
┌─────────────────────────┐
│ 👤 Alice          12:30 │
│ Last message...         │
├─────────────────────────┤
│ 👤 Bob            11:45 │  ← User yang akan diblokir
│ Last message...         │
├─────────────────────────┤
│ 👤 Charlie        10:20 │
│ Last message...         │
└─────────────────────────┘
```

### Setelah Blokir Bob:
```
Chat List:
┌─────────────────────────┐
│ 👤 Alice          12:30 │
│ Last message...         │
├─────────────────────────┤
│ 👤 Charlie        10:20 │  ← Bob HILANG dari list
│ Last message...         │
└─────────────────────────┘
```

### Di Blocked Users Screen:
```
Blocked Users:
┌─────────────────────────┐
│ 🚫 Bob            [Unblock] │
│ Reason: Spam              │
└─────────────────────────┘
```

## 🔓 Unblock User

### Alur Unblock:
```
1. User buka Settings → Blocked Users
2. User klik "Unblock" pada user yang ingin di-unblock
3. Konfirmasi unblock
4. ✅ Record dihapus dari tabel user_blocks
5. ✅ User buka Chat List
6. ✅ Chat room dengan user yang di-unblock MUNCUL kembali
```

## 🧪 Cara Test

### Test 1: Block User
```
1. Buka private chat dengan user A
2. Klik menu → Block User
3. Pilih reason → Send Report
4. ✅ Kembali ke chat list
5. ✅ Chat dengan user A TIDAK muncul
6. ✅ Buka Blocked Users screen
7. ✅ User A muncul di list blocked users
```

### Test 2: Unblock User
```
1. Buka Settings → Blocked Users
2. Klik "Unblock" pada user A
3. Konfirmasi unblock
4. ✅ Kembali ke chat list (pull to refresh atau reload)
5. ✅ Chat dengan user A MUNCUL kembali
```

### Test 3: Multiple Blocked Users
```
1. Block user A, B, dan C
2. ✅ Ketiga chat room HILANG dari chat list
3. ✅ Blocked Users screen menampilkan A, B, C
4. Unblock user B
5. ✅ Chat dengan B MUNCUL kembali
6. ✅ Chat dengan A dan C tetap HILANG
```

## 💡 Keuntungan Implementasi Ini

1. **Clean UI** - Chat list hanya menampilkan chat yang aktif dan relevan
2. **No Accidental Messages** - User tidak bisa salah klik chat dengan user yang diblokir
3. **Privacy & Safety** - User merasa lebih aman karena tidak melihat chat dengan user yang diblokir
4. **Reversible** - User bisa unblock kapan saja dan chat akan muncul kembali
5. **No Data Loss** - Chat history tetap tersimpan di database, hanya disembunyikan dari UI

## 📊 Database Impact

### Performance:
- **+1 Query** per chat list load: Fetch blocked users
- **Minimal Impact**: Blocked users query sangat cepat (indexed by blocker_id)
- **Filter di Code**: Filter dilakukan di application layer, bukan database

### Optimization (Optional):
Jika perlu optimasi lebih lanjut, bisa menggunakan JOIN query:

```sql
SELECT cr.*, m.*
FROM chat_rooms cr
LEFT JOIN messages m ON cr.id = m.chat_room_id
WHERE (cr.user1_id = 'current_user_id' OR cr.user2_id = 'current_user_id')
  AND NOT EXISTS (
    SELECT 1 FROM user_blocks ub
    WHERE ub.blocker_id = 'current_user_id'
      AND (ub.blocked_id = cr.user1_id OR ub.blocked_id = cr.user2_id)
  )
ORDER BY cr.last_message_at DESC
```

## 🎯 Kesimpulan

✅ **Problem:** Chat dengan user yang diblokir masih muncul di chat list
✅ **Solution:** Filter chat rooms untuk exclude blocked users
✅ **Result:** Chat list hanya menampilkan user yang TIDAK diblokir
✅ **Status:** IMPLEMENTED & READY TO TEST

**User sekarang punya kontrol penuh atas chat list mereka!** 🎉
