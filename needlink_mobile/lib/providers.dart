import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart';

final supabaseProvider = Provider((ref) => Supabase.instance.client);

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseProvider).auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  // Watch the auth stream so this re-derives on every sign-in/out event,
  // preventing stale user IDs being passed to profileProvider etc.
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
      .select('*, donation_need:donation_needs!inner(*, ngo_id), donor:profiles!donor_id(full_name, phone)')
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
