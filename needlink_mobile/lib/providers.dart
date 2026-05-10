import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart';

final supabaseProvider = Provider((ref) => Supabase.instance.client);

final authStateProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseProvider);
  return client.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  return Supabase.instance.client.auth.currentUser;
});

final profileProvider = FutureProvider<Profile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final data = await Supabase.instance.client
      .from('profiles')
      .select()
      .eq('id', user.id)
      .single();
  return Profile.fromJson(data);
});

final myNgoProvider = FutureProvider<Ngo?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final data = await Supabase.instance.client
      .from('ngos')
      .select()
      .eq('admin_id', user.id)
      .maybeSingle();
  return data != null ? Ngo.fromJson(data) : null;
});

final donationNeedsProvider = StreamProvider<List<DonationNeed>>((ref) {
  final client = Supabase.instance.client;
  return client
      .from('donation_needs')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map((rows) => rows.map(DonationNeed.fromJson).toList());
});

final myPledgesProvider = StreamProvider<List<Pledge>>((ref) async* {
  final user = ref.watch(currentUserProvider);
  if (user == null) { yield []; return; }

  final client = Supabase.instance.client;
  while (true) {
    final data = await client
        .from('pledges')
        .select('*, donation_need:donation_needs(*, ngo:ngos(*))')
        .eq('donor_id', user.id)
        .order('created_at', ascending: false);
    yield (data as List).map((e) => Pledge.fromJson(e)).toList();
    await Future.delayed(const Duration(seconds: 10));
  }
});
