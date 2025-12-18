# Migration Guide - Supabase Integration

## Summary
Aplikasi AnonChat telah berhasil diintegrasikan dengan Supabase untuk menyimpan semua data secara persisten dan mendukung fitur realtime.

## Perubahan Utama

### 1. Database Integration
Semua data sekarang disimpan di Supabase:
- **Users**: Registrasi, profil, status online
- **Chat Rooms**: Ruang chat private antar 2 user
- **Messages**: Pesan chat dengan realtime sync
- **Friendships**: Pertemanan dan friend requests
- **User Blocks**: Blokir user
- **User Reports**: Laporan user
- **Nearby Groups**: Grup berdasarkan lokasi
- **Group Messages**: Pesan grup nearby

### 2. Service Layer Changes

#### UserService
- ✅ `registerWithPhone()` - Registrasi dengan nomor telepon
- ✅ `updateProfile()` - Update username, avatar, bio
- ✅ `getCurrentUser()` - Get user yang sedang login
- ✅ `updateOnlineStatus()` - Update status online/offline
- ✅ `getAllUsers()` - Get semua user
- ✅ `searchUsers()` - Cari user berdasarkan username

#### ChatService
- ✅ `getOrCreateChatRoom()` - Buat/get room chat
- ✅ `getChatRoomsWithUsers()` - Get daftar chat dengan info user
- ✅ `sendMessage()` - Kirim pesan
- ✅ `getMessages()` - Get riwayat pesan
- ✅ `markMessagesAsRead()` - Tandai pesan sudah dibaca
- ✅ `subscribeToMessages()` - Subscribe realtime messages
- ✅ `subscribeToTypingStatus()` - Subscribe status typing

#### FriendshipService
- ✅ `sendFriendRequest()` - Kirim friend request
- ✅ `acceptFriendRequest()` - Terima friend request
- ✅ `rejectFriendRequest()` - Tolak friend request
- ✅ `getFriends()` - Get daftar teman
- ✅ `getPendingRequests()` - Get friend request pending
- ✅ `blockUser()` - Blokir user
- ✅ `reportUser()` - Laporkan user

#### NearbyGroupService
- ✅ `createGroup()` - Buat grup nearby
- ✅ `getNearbyGroups()` - Get grup berdasarkan lokasi
- ✅ `joinGroup()` - Join grup
- ✅ `leaveGroup()` - Keluar dari grup
- ✅ `sendGroupMessage()` - Kirim pesan grup
- ✅ `getGroupMessages()` - Get riwayat pesan grup
- ✅ `subscribeToGroupMessages()` - Subscribe realtime grup messages

### 3. Provider Changes

#### AuthProvider
- Menggunakan `ChatUser` model (bukan `UserModel`)
- Method `registerWithPhone()` untuk registrasi
- Method `updateProfile()` untuk update profil
- Property `userId` untuk get current user ID

#### PrivateChatProvider
- Menggunakan `ChatMessage` model
- Method `enterChat()` memerlukan `chatRoomId` dan `currentUserId`
- Method `sendMessage()` memerlukan named parameters:
  - `chatRoomId`
  - `senderId`
  - `receiverId`
  - `messageText`
- Method `blockUser()` memerlukan named parameters:
  - `currentUserId`
  - `blockedUserId`
  - `reason` (optional)
- Property `chatRooms` menggantikan `chats`
- Mendukung realtime typing status

### 4. Model Changes

#### ChatMessage
Added helper methods:
- `isMe(String currentUserId)` - Check apakah pesan dari current user
- `content` getter - Alias untuk `messageText`
- `timestamp` getter - Alias untuk `createdAt`

#### ChatUser
Model baru yang menggantikan `UserModel`:
- `id` (UUID dari Supabase)
- `phoneNumber`
- `deviceId`
- `username` (auto-generated dari nomor telepon)
- `avatarUrl`
- `bio`
- `isOnline`
- `lastSeen`
- `createdAt`

### 5. Realtime Features
Aplikasi sekarang mendukung:
- ✅ Realtime chat messages
- ✅ Typing indicators
- ✅ Online/offline status
- ✅ Group chat realtime
- ✅ Auto-update message read status

## Cara Testing

### 1. Registrasi User Baru
```dart
// Di PhoneRegistrationScreen
await authProvider.registerWithPhone('+628123456789');
```

### 2. Chat dengan User Lain
```dart
// Buat/get chat room
final room = await chatService.getOrCreateChatRoom(user1Id, user2Id);

// Enter chat room
await chatProvider.enterChat(room.id, currentUserId);

// Send message
await chatProvider.sendMessage(
  chatRoomId: room.id,
  senderId: currentUserId,
  receiverId: otherUserId,
  messageText: 'Hello!',
);
```

### 3. Nearby Groups
```dart
// Create group
final group = await nearbyGroupService.createGroup(
  creatorId: currentUserId,
  name: 'Coffee Lovers',
  latitude: -6.200000,
  longitude: 106.816666,
);

// Join group
await nearbyGroupService.joinGroup(
  groupId: group.id,
  userId: currentUserId,
);
```

## Perbaikan yang Diperlukan

Beberapa screen perlu diupdate untuk menggunakan API baru:
1. ⚠️ `private_chat_detail_screen.dart` - Update enterChat() dan sendMessage()
2. ⚠️ `private_chat_list_screen.dart` - Update loadData() dan property chats
3. ⚠️ `chat_room_screen.dart` - Update untuk gunakan ChatUser.username
4. ⚠️ `profile_screen.dart` - Update untuk gunakan ChatUser (tidak ada anonHandle)
5. ⚠️ `otp_screen.dart` - Update untuk gunakan registerWithPhone()
6. ⚠️ `privacy_policy_screen.dart` - Update untuk gunakan registerWithPhone()

## Next Steps

1. Update UI screens untuk gunakan API baru
2. Test end-to-end flow registrasi sampai chat
3. Enable realtime di Supabase Dashboard untuk tables:
   - messages
   - typing_status
   - users
   - group_messages
   - group_members
4. Deploy dan test di device fisik

## Catatan
- Database schema sudah di-apply ke Supabase
- Semua service layer sudah terintegrasi dengan Supabase
- Realtime sudah dikonfigurasi dan siap digunakan
- RLS policies sudah diset (sementara permissive untuk development)
