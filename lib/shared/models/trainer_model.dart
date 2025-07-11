class TrainerModel {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String bio;
  final List<String> specialties;
  final List<String> certifications;
  final double rating;
  final int reviewCount;
  final int experienceYears;
  final String? instagramHandle;
  final String? websiteUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  TrainerModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.bio,
    required this.specialties,
    required this.certifications,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.experienceYears = 0,
    this.instagramHandle,
    this.websiteUrl,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TrainerModel.fromJson(Map<String, dynamic> json) {
    return TrainerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      photoUrl: json['photoUrl'] as String?,
      bio: json['bio'] as String,
      specialties: List<String>.from(json['specialties'] ?? []),
      certifications: List<String>.from(json['certifications'] ?? []),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      experienceYears: json['experienceYears'] as int? ?? 0,
      instagramHandle: json['instagramHandle'] as String?,
      websiteUrl: json['websiteUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'bio': bio,
      'specialties': specialties,
      'certifications': certifications,
      'rating': rating,
      'reviewCount': reviewCount,
      'experienceYears': experienceYears,
      'instagramHandle': instagramHandle,
      'websiteUrl': websiteUrl,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  TrainerModel copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    String? bio,
    List<String>? specialties,
    List<String>? certifications,
    double? rating,
    int? reviewCount,
    int? experienceYears,
    String? instagramHandle,
    String? websiteUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TrainerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      specialties: specialties ?? this.specialties,
      certifications: certifications ?? this.certifications,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      experienceYears: experienceYears ?? this.experienceYears,
      instagramHandle: instagramHandle ?? this.instagramHandle,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class TrainerReview {
  final String id;
  final String trainerId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final double rating;
  final String comment;
  final DateTime createdAt;

  TrainerReview({
    required this.id,
    required this.trainerId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory TrainerReview.fromJson(Map<String, dynamic> json) {
    return TrainerReview(
      id: json['id'] as String,
      trainerId: json['trainerId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userPhotoUrl: json['userPhotoUrl'] as String?,
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trainerId': trainerId,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }
} 