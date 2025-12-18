import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseClient? _client;

  SupabaseService._();

  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }
    return _client!;
  }

  static Future<void> initialize() async {
    if (_client != null) return;

    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
      realtimeClientOptions: const RealtimeClientOptions(
        eventsPerSecond: 10,
      ),
    );

    _client = Supabase.instance.client;
  }

  // Getter untuk table
  SupabaseQueryBuilder get users => client.from('users');
  SupabaseQueryBuilder get chatRooms => client.from('chat_rooms');
  SupabaseQueryBuilder get messages => client.from('messages');
  SupabaseQueryBuilder get typingStatus => client.from('typing_status');
  SupabaseQueryBuilder get friendships => client.from('friendships');
  SupabaseQueryBuilder get userBlocks => client.from('user_blocks');
  SupabaseQueryBuilder get userReports => client.from('user_reports');
  SupabaseQueryBuilder get nearbyGroups => client.from('nearby_groups');
  SupabaseQueryBuilder get groupMembers => client.from('group_members');
  SupabaseQueryBuilder get groupMessages => client.from('group_messages');

  // Realtime channel
  RealtimeChannel channel(String channelName) {
    return client.channel(channelName);
  }
}
