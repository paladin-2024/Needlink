class Profile {
  final String id;
  final String fullName;
  final String role;
  final String? phone;
  final String createdAt;

  const Profile({required this.id, required this.fullName, required this.role, this.phone, required this.createdAt});

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
    id: j['id'], fullName: j['full_name'], role: j['role'],
    phone: j['phone'], createdAt: j['created_at'],
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
  final String createdAt;

  const Ngo({
    required this.id, required this.adminId, required this.name,
    required this.location, this.registrationNumber, required this.contactEmail,
    required this.verified, required this.createdAt,
  });

  factory Ngo.fromJson(Map<String, dynamic> j) => Ngo(
    id: j['id'], adminId: j['admin_id'], name: j['name'],
    location: j['location'], registrationNumber: j['registration_number'],
    contactEmail: j['contact_email'], verified: j['verified'] ?? false,
    createdAt: j['created_at'],
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
  final String createdAt;
  final Ngo? ngo;

  const DonationNeed({
    required this.id, required this.ngoId, required this.itemName,
    required this.category, required this.quantityNeeded, required this.quantityPledged,
    required this.urgency, required this.status, required this.deadline,
    this.description, required this.createdAt, this.ngo,
  });

  factory DonationNeed.fromJson(Map<String, dynamic> j) => DonationNeed(
    id: j['id'], ngoId: j['ngo_id'], itemName: j['item_name'],
    category: j['category'], quantityNeeded: j['quantity_needed'],
    quantityPledged: j['quantity_pledged'] ?? 0, urgency: j['urgency'],
    status: j['status'], deadline: j['deadline'],
    description: j['description'], createdAt: j['created_at'],
    ngo: j['ngo'] != null ? Ngo.fromJson(j['ngo']) : null,
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
  final String createdAt;
  final DonationNeed? donationNeed;
  final Profile? donor;

  const Pledge({
    required this.id, required this.needId, required this.donorId,
    required this.quantity, required this.deliveryDate, this.notes,
    required this.status, required this.createdAt, this.donationNeed, this.donor,
  });

  factory Pledge.fromJson(Map<String, dynamic> j) => Pledge(
    id: j['id'], needId: j['need_id'], donorId: j['donor_id'],
    quantity: j['quantity'], deliveryDate: j['delivery_date'],
    notes: j['notes'], status: j['status'], createdAt: j['created_at'],
    donationNeed: j['donation_need'] != null ? DonationNeed.fromJson(j['donation_need']) : null,
    donor: j['donor'] != null ? Profile.fromJson(j['donor']) : null,
  );
}
