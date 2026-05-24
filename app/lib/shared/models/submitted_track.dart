/// Rappresenta una pista inviata da un organizzatore in attesa di revisione
/// (approval_status = draft | pending | rejected).
/// Letta dalla tabella `tracks` via la policy "organizer reads own".
class SubmittedTrack {
  const SubmittedTrack({
    required this.id,
    required this.slug,
    required this.name,
    required this.city,
    required this.shortDescription,
    required this.approvalStatus,
    this.description = '',
    this.address = '',
    this.country = 'Italy',
    this.imageUrl,
    this.contactEmail = '',
    this.phone = '',
    this.website = '',
    this.organizationName = '',
    this.submittedAt,
    this.reviewNotes,
  });

  final String id;
  final String slug;
  final String name;
  final String city;
  final String shortDescription;
  final String description;
  final String address;
  final String country;
  final String approvalStatus;
  final String? imageUrl;
  final String contactEmail;
  final String phone;
  /// Corrisponde a external_map_url nel DB.
  final String website;
  final String organizationName;
  final DateTime? submittedAt;
  final String? reviewNotes;

  bool get isPending => approvalStatus == 'pending';
  bool get isDraft => approvalStatus == 'draft';
  bool get isRejected => approvalStatus == 'rejected';

  SubmittedTrack copyWith({
    String? id,
    String? slug,
    String? name,
    String? city,
    String? shortDescription,
    String? description,
    String? address,
    String? country,
    String? approvalStatus,
    String? imageUrl,
    String? contactEmail,
    String? phone,
    String? website,
    String? organizationName,
    DateTime? submittedAt,
    String? reviewNotes,
  }) {
    return SubmittedTrack(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      name: name ?? this.name,
      city: city ?? this.city,
      shortDescription: shortDescription ?? this.shortDescription,
      description: description ?? this.description,
      address: address ?? this.address,
      country: country ?? this.country,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      imageUrl: imageUrl ?? this.imageUrl,
      contactEmail: contactEmail ?? this.contactEmail,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      organizationName: organizationName ?? this.organizationName,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewNotes: reviewNotes ?? this.reviewNotes,
    );
  }

  factory SubmittedTrack.fromMap(Map<String, dynamic> map) {
    return SubmittedTrack(
      id: map['id'] as String? ?? '',
      slug: map['slug'] as String? ?? '',
      name: map['name'] as String? ?? '',
      city: map['city'] as String? ?? '',
      shortDescription: map['short_description'] as String? ?? '',
      description: map['description'] as String? ?? '',
      address: map['address'] as String? ?? '',
      country: map['country'] as String? ?? 'Italy',
      approvalStatus: map['approval_status'] as String? ?? 'draft',
      imageUrl: map['image_url'] as String?,
      contactEmail: map['contact_email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      website: map['external_map_url'] as String? ?? '',
      organizationName: map['organization_name'] as String? ?? '',
      submittedAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'] as String),
      reviewNotes: map['review_notes'] as String?,
    );
  }

  /// Payload per INSERT (nuovo invio). Slug e submitted_by vengono inclusi.
  Map<String, dynamic> toInsertMap({required String submittedBy}) {
    return {
      'slug': slug,
      'name': name,
      'city': city,
      'country': country,
      'short_description': shortDescription,
      'description': description,
      'address': address,
      'image_url': imageUrl,
      'contact_email': contactEmail,
      'phone': phone,
      'external_map_url': website,
      'organization_name': organizationName,
      'approval_status': approvalStatus,
      'is_public': false,
      'submitted_by': submittedBy,
    };
  }

  /// Payload per UPDATE (modifica bozza/pending).
  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'city': city,
      'short_description': shortDescription,
      'description': description,
      'address': address,
      'image_url': imageUrl,
      'contact_email': contactEmail,
      'phone': phone,
      'external_map_url': website,
      'organization_name': organizationName,
      'approval_status': approvalStatus,
    };
  }
}
