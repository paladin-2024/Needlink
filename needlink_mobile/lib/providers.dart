import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart';

final supabaseProvider = Provider((ref) => Supabase.instance.client);

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseProvider).auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateProvider);
  return Supabase.instance.client.auth.currentUser;
});

final profileProvider = FutureProvider<Profile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final data = await Supabase.instance.client
      .from('profiles').select().eq('id', user.id).single();
  return Profile.fromJson(data);
});

final myNgoProvider = FutureProvider<Ngo?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final data = await Supabase.instance.client
      .from('ngos').select().eq('admin_id', user.id).maybeSingle();
  return data != null ? Ngo.fromJson(data) : null;
});

// Includes NGO relation for donor home/discover cards
final donationNeedsProvider = FutureProvider<List<DonationNeed>>((ref) async {
  ref.keepAlive();
  final data = await Supabase.instance.client
      .from('donation_needs')
      .select('*, ngo:ngos(*)')
      .neq('status', 'closed')
      .order('is_featured', ascending: false)
      .order('created_at', ascending: false);
  return (data as List).map((e) => DonationNeed.fromJson(e as Map<String, dynamic>)).toList();
});

// NGO's own needs — reuses myNgoProvider to avoid a second round trip
final myNgoNeedsProvider = FutureProvider<List<DonationNeed>>((ref) async {
  ref.keepAlive();
  final ngo = await ref.watch(myNgoProvider.future);
  if (ngo == null) return [];
  final data = await Supabase.instance.client
      .from('donation_needs')
      .select('*, ngo:ngos(*)')
      .eq('ngo_id', ngo.id)
      .order('created_at', ascending: false);
  return (data as List).map((e) => DonationNeed.fromJson(e as Map<String, dynamic>)).toList();
});

// Pending pledges for NGO's needs — reuses myNgoProvider to avoid a second round trip
final myNgoPendingPledgesProvider = FutureProvider<List<Pledge>>((ref) async {
  ref.keepAlive();
  final ngo = await ref.watch(myNgoProvider.future);
  if (ngo == null) return [];
  final data = await Supabase.instance.client
      .from('pledges')
      .select('*, donation_need:donation_needs!inner(*, ngo_id), donor:profiles!donor_id(id, full_name, phone, avatar_url)')
      .eq('donation_need.ngo_id', ngo.id)
      .eq('status', 'pending')
      .order('created_at', ascending: false);
  return (data as List).map((e) => Pledge.fromJson(e as Map<String, dynamic>)).toList();
});

final myPledgesProvider = FutureProvider<List<Pledge>>((ref) async {
  ref.keepAlive();
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final data = await Supabase.instance.client
      .from('pledges')
      .select('*, donation_need:donation_needs(*, ngo:ngos(*))')
      .eq('donor_id', user.id)
      .order('created_at', ascending: false);
  return (data as List).map((e) => Pledge.fromJson(e as Map<String, dynamic>)).toList();
});

// Set of saved need IDs for the current donor — fast O(1) lookup in card widgets
final savedNeedIdsProvider = FutureProvider<Set<String>>((ref) async {
  ref.keepAlive();
  final user = ref.watch(currentUserProvider);
  if (user == null) return {};
  final data = await Supabase.instance.client
      .from('saved_needs')
      .select('need_id')
      .eq('donor_id', user.id);
  return (data as List).map((e) => e['need_id'] as String).toSet();
});

// Full saved needs with need+NGO join — for the Saved Needs screen
final savedNeedsProvider = FutureProvider<List<SavedNeed>>((ref) async {
  ref.keepAlive();
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final data = await Supabase.instance.client
      .from('saved_needs')
      .select('*, need:donation_needs(*, ngo:ngos(*))')
      .eq('donor_id', user.id)
      .order('created_at', ascending: false);
  return (data as List).map((e) => SavedNeed.fromJson(e as Map<String, dynamic>)).toList();
});

// Notifications for current user
final notificationsProvider = FutureProvider<List<AppNotification>>((ref) async {
  ref.keepAlive();
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final data = await Supabase.instance.client
      .from('notifications')
      .select()
      .eq('user_id', user.id)
      .order('created_at', ascending: false)
      .limit(50);
  return (data as List).map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).when(
    data: (list) => list.where((n) => !n.read).length,
    loading: () => 0,
    error: (_, _) => 0,
  );
});

// All NGOs for map view
final allNgosProvider = FutureProvider<List<Ngo>>((ref) async {
  ref.keepAlive();
  final data = await Supabase.instance.client
      .from('ngos')
      .select()
      .order('name');
  return (data as List).map((e) => Ngo.fromJson(e as Map<String, dynamic>)).toList();
});
