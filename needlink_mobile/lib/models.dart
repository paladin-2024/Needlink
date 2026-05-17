class Profile {
  final String id;
  final String fullName;
  final String role;
  final String? phone;
  final String? avatarUrl;
  final String createdAt;

  const Profile({required this.id, required this.fullName, required this.role, this.phone, this.avatarUrl, required this.createdAt});

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
    id: j['id'] as String,
    fullName: (j['full_name'] as String?) ?? '',
    role: (j['role'] as String?) ?? 'donor',
    phone: j['phone'] as String?,
    avatarUrl: j['avatar_url'] as String?,
    createdAt: (j['created_at'] as String?) ?? '',
  );
}

class Ngo {
  final String id;
  final String adminId;
  final String name;
  final String location;
  final String? registrationNumber;
  final String contactEmail;
  final bool verified;
  final String? logoUrl;
  final double? latitude;
  final double? longitude;
  final String createdAt;

  const Ngo({
    required this.id, required this.adminId, required this.name,
    required this.location, this.registrationNumber, required this.contactEmail,
    required this.verified, this.logoUrl, this.latitude, this.longitude,
    required this.createdAt,
  });

  factory Ngo.fromJson(Map<String, dynamic> j) => Ngo(
    id: j['id'] as String,
    adminId: (j['admin_id'] as String?) ?? '',
    name: (j['name'] as String?) ?? '',
    location: (j['location'] as String?) ?? '',
    registrationNumber: j['registration_number'] as String?,
    contactEmail: (j['contact_email'] as String?) ?? '',
    verified: (j['verified'] as bool?) ?? false,
    logoUrl: j['logo_url'] as String?,
    latitude: (j['latitude'] as num?)?.toDouble(),
    longitude: (j['longitude'] as num?)?.toDouble(),
    createdAt: (j['created_at'] as String?) ?? '',
  );
}

class DonationNeed {
  final String id;
  final String ngoId;
  final String itemName;
  final String category;
  final int quantityNeeded;
  final int quantityPledged;
  final String urgency;
  final String status;
  final String deadline;
  final String? description;
  final bool isFeatured;
  final String createdAt;
  final Ngo? ngo;

  const DonationNeed({
    required this.id, required this.ngoId, required this.itemName,
    required this.category, required this.quantityNeeded, required this.quantityPledged,
    required this.urgency, required this.status, required this.deadline,
    this.description, this.isFeatured = false, required this.createdAt, this.ngo,
  });

  factory DonationNeed.fromJson(Map<String, dynamic> j) => DonationNeed(
    id: j['id'] as String,
    ngoId: (j['ngo_id'] as String?) ?? '',
    itemName: (j['item_name'] as String?) ?? '',
    category: (j['category'] as String?) ?? 'supplies',
    quantityNeeded: (j['quantity_needed'] as int?) ?? 0,
    quantityPledged: (j['quantity_pledged'] as int?) ?? 0,
    urgency: (j['urgency'] as String?) ?? 'normal',
    status: (j['status'] as String?) ?? 'open',
    deadline: (j['deadline'] as String?) ?? '',
    description: j['description'] as String?,
    isFeatured: (j['is_featured'] as bool?) ?? false,
    createdAt: (j['created_at'] as String?) ?? '',
    ngo: j['ngo'] != null ? Ngo.fromJson(j['ngo'] as Map<String, dynamic>) : null,
  );

  double get progress => quantityNeeded > 0 ? (quantityPledged / quantityNeeded).clamp(0.0, 1.0) : 0;
  int get remaining => (quantityNeeded - quantityPledged).clamp(0, quantityNeeded);
  bool get isUrgent => urgency == 'urgent';
  bool get isOpen => status == 'open';
}

class Pledge {
  final String id;
  final String needId;
  final String donorId;
  final int quantity;
  final String deliveryDate;
  final String? notes;
  final String status;
  final String? deliveryProofUrl;
  final String createdAt;
  final DonationNeed? donationNeed;
  final Profile? donor;

  const Pledge({
    required this.id, required this.needId, required this.donorId,
    required this.quantity, required this.deliveryDate, this.notes,
    required this.status, this.deliveryProofUrl, required this.createdAt,
    this.donationNeed, this.donor,
  });

  factory Pledge.fromJson(Map<String, dynamic> j) => Pledge(
    id: j['id'] as String,
    needId: (j['need_id'] as String?) ?? '',
    donorId: (j['donor_id'] as String?) ?? '',
    quantity: (j['quantity'] as int?) ?? 0,
    deliveryDate: (j['delivery_date'] as String?) ?? '',
    notes: j['notes'] as String?,
    status: (j['status'] as String?) ?? 'pending',
    deliveryProofUrl: j['delivery_proof_url'] as String?,
    createdAt: (j['created_at'] as String?) ?? '',
    donationNeed: j['donation_need'] != null ? DonationNeed.fromJson(j['donation_need'] as Map<String, dynamic>) : null,
    donor: j['donor'] != null ? Profile.fromJson(j['donor'] as Map<String, dynamic>) : null,
  );
}

class SavedNeed {
  final String id;
  final String donorId;
  final String needId;
  final DonationNeed? need;
  final String createdAt;

  const SavedNeed({
    required this.id, required this.donorId, required this.needId,
    this.need, required this.createdAt,
  });

  factory SavedNeed.fromJson(Map<String, dynamic> j) => SavedNeed(
    id: j['id'] as String,
    donorId: (j['donor_id'] as String?) ?? '',
    needId: (j['need_id'] as String?) ?? '',
    need: j['need'] != null ? DonationNeed.fromJson(j['need'] as Map<String, dynamic>) : null,
    createdAt: (j['created_at'] as String?) ?? '',
  );
}

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final bool read;
  final Map<String, dynamic>? data;
  final String createdAt;

  const AppNotification({
    required this.id, required this.userId, required this.title,
    required this.body, required this.type, required this.read,
    this.data, required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
    id: j['id'] as String,
    userId: (j['user_id'] as String?) ?? '',
    title: (j['title'] as String?) ?? '',
    body: (j['body'] as String?) ?? '',
    type: (j['type'] as String?) ?? 'system',
    read: (j['read'] as bool?) ?? false,
    data: j['data'] as Map<String, dynamic>?,
    createdAt: (j['created_at'] as String?) ?? '',
  );
}
