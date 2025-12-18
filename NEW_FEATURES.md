# 🎉 Fitur Baru AnonChat - Lengkap!

## 📋 Ringkasan Fitur Baru

Saya sudah menambahkan 4 fitur utama ke sistem AnonChat Anda:

1. ✅ **Auto-Generate Username** - Username otomatis dibuat saat registrasi
2. ✅ **Report & Block System** - Laporkan dan blokir user bermasalah
3. ✅ **Add Friend System** - Tambah teman pakai nomor/username
4. ✅ **Nearby Group Chat** - Grup chat berdasarkan lokasi GPS

---

## 1. 🎯 Auto-Generate Username

### Cara Kerja:
- Saat user registrasi dengan nomor telepon, username otomatis dibuat
- Format: `User{4_digit_terakhir_nomor}{random_3_digit}`
- Contoh: Nomor `+6281234567890` → Username `User7890423`
- User bisa ubah username kapan saja via ProfileEditScreen

### Database:
```sql
-- Trigger di database otomatis generate username
-- Lihat: supabase_schema.sql line 29-44
```

### Implementasi Flutter:
```dart
// Sudah otomatis saat registrasi
final user = await userService.registerWithPhone('+6281234567890');
print(user.username); // Output: User7890423 (auto-generated)

// User bisa ubah nanti
await userService.updateProfile(
  userId: user.id,
  username: 'CustomUsername',
);
```

---

## 2. 🚫 Report & Block System

### Database Tables:
- `user_blocks` - Menyimpan data blokir user
- `user_reports` - Menyimpan laporan user

### Fitur Block:

```dart
import 'package:anonchat/services/friendship_service.dart';

final friendshipService = FriendshipService();

// Block user
await friendshipService.blockUser(
  blockerId: currentUser.id,
  blockedId: targetUser.id,
  reason: 'Spam messages',
);

// Unblock user
await friendshipService.unblockUser(blockId);

// Get blocked users list
final blockedList = await friendshipService.getBlockedUsers(currentUser.id);
for (var item in blockedList) {
  final user = item['user'] as ChatUser;
  final block = item['block'] as UserBlock;
  print('Blocked: ${user.displayName}');
}
```

### Fitur Report:

```dart
// Report user
await friendshipService.reportUser(
  reporterId: currentUser.id,
  reportedId: targetUser.id,
  reason: 'Harassment',
  description: 'Mengirim pesan yang tidak pantas',
);
```

### Implementasi di Chat Screen:

Tambahkan menu options di chat screen:

```dart
// Di SupabaseChatScreen, tambah action button
actions: [
  PopupMenuButton(
    itemBuilder: (context) => [
      PopupMenuItem(
        child: Text('Block User'),
        onTap: () => _blockUser(),
      ),
      PopupMenuItem(
        child: Text('Report User'),
        onTap: () => _reportUser(),
      ),
    ],
  ),
],

Future<void> _blockUser() async {
  await friendshipService.blockUser(
    blockerId: _currentUser!.id,
    blockedId: widget.otherUser.id,
  );
  Navigator.pop(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('User diblokir')),
  );
}
```

### Filter Blocked Users:

```dart
// Di UserService, filter blocked users dari hasil
Future<List<ChatUser>> getAllUsersExcludingBlocked(String userId) async {
  // Get blocked user IDs
  final blocks = await SupabaseService.client
      .from('user_blocks')
      .select('blocked_id')
      .eq('blocker_id', userId);

  final blockedIds = blocks.map((b) => b['blocked_id'] as String).toList();

  // Get all users except blocked ones
  var query = _supabase.users.select().neq('id', userId);

  if (blockedIds.isNotEmpty) {
    query = query.not('id', 'in', '(${blockedIds.join(',')})');
  }

  final usersData = await query;
  return usersData.map((data) => ChatUser.fromJson(data)).toList();
}
```

---

## 3. 👥 Add Friend System

### Database Table:
- `friendships` - Menyimpan relasi pertemanan
- Status: `pending`, `accepted`, `rejected`

### Flow Add Friend:

```dart
import 'package:anonchat/services/friendship_service.dart';

final friendshipService = FriendshipService();

// 1. Kirim friend request by PHONE NUMBER
await friendshipService.sendFriendRequest(
  currentUserId: currentUser.id,
  phoneNumber: '+6281234567890',
);

// 2. Atau kirim friend request by USERNAME
await friendshipService.sendFriendRequest(
  currentUserId: currentUser.id,
  username: 'User7890423',
);

// 3. User lain menerima notifikasi pending request
final pending = await friendshipService.getPendingRequests(currentUser.id);
for (var item in pending) {
  final user = item['user'] as ChatUser;
  final friendship = item['friendship'] as Friendship;
  print('Friend request from: ${user.displayName}');
}

// 4. Accept friend request
await friendshipService.acceptFriendRequest(friendshipId);

// 5. Atau reject
await friendshipService.rejectFriendRequest(friendshipId);

// 6. Get daftar teman
final friends = await friendshipService.getFriends(currentUser.id);
for (var item in friends) {
  final user = item['user'] as ChatUser;
  print('Friend: ${user.displayName}');
}

// 7. Unfriend
await friendshipService.unfriend(friendshipId);
```

### Contoh Screen Add Friend:

```dart
class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final _controller = TextEditingController();
  final _friendshipService = FriendshipService();
  final _userService = UserService();

  Future<void> _sendRequest() async {
    final input = _controller.text.trim();
    if (input.isEmpty) return;

    try {
      final currentUser = await _userService.getCurrentUser();

      // Try as phone number first
      if (input.startsWith('08') || input.startsWith('+62')) {
        await _friendshipService.sendFriendRequest(
          currentUserId: currentUser!.id,
          phoneNumber: input.startsWith('08') ? '+62${input.substring(1)}' : input,
        );
      } else {
        // Try as username
        await _friendshipService.sendFriendRequest(
          currentUserId: currentUser!.id,
          username: input,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend request sent!')),
      );
      _controller.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Friend')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Phone Number or Username',
                hintText: '081234567890 or User7890',
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _sendRequest,
              child: Text('Send Friend Request'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 4. 📍 Nearby Group Chat (Location-Based)

### Cara Kerja:
- Buat grup chat dengan koordinat GPS (latitude, longitude)
- Set radius dalam meter (default: 1000m = 1km)
- User dalam radius bisa auto-join grup
- Realtime group chat

### Database Tables:
- `nearby_groups` - Data grup nearby
- `group_members` - Member grup
- `group_messages` - Pesan grup

### Create Group:

```dart
import 'package:anonchat/services/nearby_group_service.dart';
import 'package:geolocator/geolocator.dart';

final groupService = NearbyGroupService();

// Get current location
final position = await Geolocator.getCurrentPosition();

// Create nearby group
final group = await groupService.createGroup(
  creatorId: currentUser.id,
  name: 'Coffee Shop Meetup',
  description: 'Chat untuk yang lagi di kafe ini',
  latitude: position.latitude,
  longitude: position.longitude,
  radiusMeters: 500, // 500 meter radius
  maxMembers: 30,
);
```

### Find Nearby Groups:

```dart
// Get user's current location
final position = await Geolocator.getCurrentPosition();

// Find groups within 5km
final nearbyGroups = await groupService.getNearbyGroups(
  latitude: position.latitude,
  longitude: position.longitude,
  maxDistanceMeters: 5000, // 5km
);

// Display groups
for (var group in nearbyGroups) {
  print('${group.name} - ${group.radiusMeters}m radius');
}
```

### Join & Chat:

```dart
// Join group
await groupService.joinGroup(
  groupId: group.id,
  userId: currentUser.id,
);

// Send message
await groupService.sendGroupMessage(
  groupId: group.id,
  senderId: currentUser.id,
  messageText: 'Hello from nearby!',
);

// Subscribe to realtime messages
groupService.subscribeToGroupMessages(group.id);
groupService.groupMessagesStream.listen((messages) {
  // Update UI dengan messages baru
  setState(() {
    _messages = messages;
  });
});
```

### Leave Group:

```dart
await groupService.leaveGroup(
  groupId: group.id,
  userId: currentUser.id,
);
```

### Contoh Screen Nearby Groups:

```dart
class NearbyGroupsScreen extends StatefulWidget {
  const NearbyGroupsScreen({super.key});

  @override
  State<NearbyGroupsScreen> createState() => _NearbyGroupsScreenState();
}

class _NearbyGroupsScreenState extends State<NearbyGroupsScreen> {
  final _groupService = NearbyGroupService();
  List<NearbyGroup> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNearbyGroups();
  }

  Future<void> _loadNearbyGroups() async {
    try {
      final position = await Geolocator.getCurrentPosition();

      final groups = await _groupService.getNearbyGroups(
        latitude: position.latitude,
        longitude: position.longitude,
        maxDistanceMeters: 5000,
      );

      setState(() {
        _groups = groups;
        _isLoading = false;
      });
    } catch (e) {
      print('Error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nearby Groups'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _createGroup,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _groups.length,
              itemBuilder: (context, index) {
                final group = _groups[index];
                return ListTile(
                  title: Text(group.name),
                  subtitle: Text(group.description ?? 'No description'),
                  trailing: Text('${group.radiusMeters}m'),
                  onTap: () => _joinAndOpenGroup(group),
                );
              },
            ),
    );
  }

  Future<void> _createGroup() async {
    // Show dialog untuk create group
    // Implementation here...
  }

  Future<void> _joinAndOpenGroup(NearbyGroup group) async {
    final currentUser = await UserService().getCurrentUser();

    try {
      await _groupService.joinGroup(
        groupId: group.id,
        userId: currentUser!.id,
      );

      // Navigate to group chat screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GroupChatScreen(group: group),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
```

---

## 🗄️ Database Setup

### 1. Import Schema Baru

File `supabase_schema.sql` sudah diupdate dengan semua table baru. Import ulang:

1. Buka Supabase Dashboard > SQL Editor
2. Copy isi file `supabase_schema.sql`
3. Paste dan Run

### 2. Enable Realtime

Enable Realtime untuk table baru:
- ✅ `group_messages`
- ✅ `group_members`
- ✅ `nearby_groups`

Di Dashboard > Database > Replication > Enable untuk table di atas

---

## 📁 File Structure Baru

```
lib/
├── models/
│   ├── chat_user.dart              # Model user (sudah ada)
│   ├── nearby_group.dart           # 🆕 Model grup nearby + member + messages
│   └── friendship.dart             # 🆕 Model friendship, block, report
├── services/
│   ├── supabase_service.dart       # ✏️ Updated dengan table baru
│   ├── user_service.dart           # (sudah ada)
│   ├── friendship_service.dart     # 🆕 Service friend/block/report
│   └── nearby_group_service.dart   # 🆕 Service nearby groups
└── screens/
    ├── phone_registration_screen.dart
    ├── profile_edit_screen.dart
    ├── users_list_screen.dart
    └── supabase_chat_screen.dart
```

---

## 📚 Complete API Reference

### FriendshipService

```dart
// Send friend request
await friendshipService.sendFriendRequest(
  currentUserId: 'user-id',
  phoneNumber: '+6281234567890', // or username: 'User7890'
);

// Accept/Reject request
await friendshipService.acceptFriendRequest('friendship-id');
await friendshipService.rejectFriendRequest('friendship-id');

// Get friends & pending requests
final friends = await friendshipService.getFriends('user-id');
final pending = await friendshipService.getPendingRequests('user-id');

// Unfriend
await friendshipService.unfriend('friendship-id');

// Block/Unblock
await friendshipService.blockUser(
  blockerId: 'user-id',
  blockedId: 'target-user-id',
  reason: 'Spam',
);
await friendshipService.unblockUser('block-id');
final blockedList = await friendshipService.getBlockedUsers('user-id');

// Report
await friendshipService.reportUser(
  reporterId: 'user-id',
  reportedId: 'target-user-id',
  reason: 'Harassment',
  description: 'Detail...',
);
```

### NearbyGroupService

```dart
// Create group
final group = await groupService.createGroup(
  creatorId: 'user-id',
  name: 'Group Name',
  description: 'Description',
  latitude: -6.200000,
  longitude: 106.816666,
  radiusMeters: 1000,
  maxMembers: 50,
);

// Find nearby groups
final groups = await groupService.getNearbyGroups(
  latitude: -6.200000,
  longitude: 106.816666,
  maxDistanceMeters: 5000,
);

// Join/Leave group
await groupService.joinGroup(groupId: 'group-id', userId: 'user-id');
await groupService.leaveGroup(groupId: 'group-id', userId: 'user-id');

// Get members
final members = await groupService.getGroupMembers('group-id');

// Send message
await groupService.sendGroupMessage(
  groupId: 'group-id',
  senderId: 'user-id',
  messageText: 'Hello!',
);

// Get messages
final messages = await groupService.getGroupMessages('group-id');

// Subscribe realtime
groupService.subscribeToGroupMessages('group-id');
groupService.groupMessagesStream.listen((messages) {
  // Update UI
});

// Delete group (creator only)
await groupService.deleteGroup(groupId: 'group-id', userId: 'creator-id');
```

---

## 🎯 Rekomendasi Next Steps

1. **Buat UI Screens**:
   - `FriendsListScreen` - Daftar teman & pending requests
   - `AddFriendScreen` - Tambah teman by phone/username
   - `NearbyGroupsScreen` - Daftar grup nearby
   - `GroupChatScreen` - Chat dalam grup
   - `BlockedUsersScreen` - Manage blocked users

2. **Notifikasi**:
   - Friend request notification
   - Group message notification
   - Nearby group available notification

3. **Permission Handling**:
   - Location permission untuk nearby groups
   - Notification permission

4. **UX Improvements**:
   - Loading states
   - Error handling
   - Pull to refresh
   - Search functionality

---

## ✅ Checklist Implementation

- [x] Auto-generate username on registration
- [x] Database schema untuk block & report
- [x] Database schema untuk friendships
- [x] Database schema untuk nearby groups
- [x] Service layer untuk friendship
- [x] Service layer untuk nearby groups
- [x] Distance calculation function (Haversine)
- [ ] UI Screens untuk semua fitur baru
- [ ] Notification system
- [ ] Location permission handling

---

Semua fitur backend sudah siap! Tinggal buat UI screens sesuai kebutuhan. Setiap fitur bisa dikembangkan independent tanpa mengganggu fitur lain. 🚀
