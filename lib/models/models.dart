import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum UserRole { worker, client }

extension UserRoleCopy on UserRole {
  String get label => this == UserRole.worker ? 'Skilled Worker' : 'Client';

  String get description => this == UserRole.worker
      ? 'Showcase your skills, win jobs and grow your reputation.'
      : 'Discover trusted workers and hire the right skills fast.';
}

enum PricingType { hourly, daily, fixedQuote, negotiable }

enum JobUrgency { flexible, soon, urgent }

enum JobStatus { open, inProgress, completed, cancelled }

enum ApplicationStatus { pending, accepted, declined, withdrawn }

enum BookingStatus {
  requested,
  accepted,
  declined,
  inProgress,
  completed,
  cancelled
}

enum NotifType {
  jobMatch,
  application,
  applicationStatus,
  serviceRequest,
  booking,
  message,
  reviewReminder,
  quiz
}

/// Safe enum lookup by name with a fallback (handles outdated local data).
T enumFrom<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

extension PricingLabel on PricingType {
  String get label {
    switch (this) {
      case PricingType.hourly:
        return 'Per hour';
      case PricingType.daily:
        return 'Per day';
      case PricingType.fixedQuote:
        return 'Fixed quote';
      case PricingType.negotiable:
        return 'Negotiable';
    }
  }
}

extension UrgencyLabel on JobUrgency {
  String get label {
    switch (this) {
      case JobUrgency.flexible:
        return 'Flexible';
      case JobUrgency.soon:
        return 'Within a week';
      case JobUrgency.urgent:
        return 'Urgent';
    }
  }
}

extension JobStatusLabel on JobStatus {
  String get label {
    switch (this) {
      case JobStatus.open:
        return 'Open';
      case JobStatus.inProgress:
        return 'In progress';
      case JobStatus.completed:
        return 'Completed';
      case JobStatus.cancelled:
        return 'Cancelled';
    }
  }
}

extension ApplicationStatusLabel on ApplicationStatus {
  String get label {
    switch (this) {
      case ApplicationStatus.pending:
        return 'Pending';
      case ApplicationStatus.accepted:
        return 'Accepted';
      case ApplicationStatus.declined:
        return 'Declined';
      case ApplicationStatus.withdrawn:
        return 'Withdrawn';
    }
  }
}

extension BookingStatusLabel on BookingStatus {
  String get label {
    switch (this) {
      case BookingStatus.requested:
        return 'Requested';
      case BookingStatus.accepted:
        return 'Accepted';
      case BookingStatus.declined:
        return 'Declined';
      case BookingStatus.inProgress:
        return 'In progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }
}

extension NotifCategory on NotifType {
  /// Used by notification preferences: jobs, messages or reminders.
  String get category {
    switch (this) {
      case NotifType.message:
        return 'messages';
      case NotifType.reviewReminder:
      case NotifType.quiz:
        return 'reminders';
      default:
        return 'jobs';
    }
  }
}

DateTime parseDate(Object? v, [DateTime? fallback]) {
  if (v is String) {
    final d = DateTime.tryParse(v);
    if (d != null) return d;
  }
  return fallback ?? DateTime.now();
}

List<String> _strings(Object? v) =>
    (v as List? ?? const []).map((e) => e.toString()).toList();

double? _dbl(Object? v) => v is num ? v.toDouble() : null;

// ---------------------------------------------------------------------------
// Static definitions (not persisted)
// ---------------------------------------------------------------------------

class TradeCategory {
  final String id;
  final String name;
  final IconData icon;
  final List<String> popularServices;
  const TradeCategory(this.id, this.name, this.icon, this.popularServices);
}

class QuizQuestion {
  final String text;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  const QuizQuestion(this.text, this.options, this.correctIndex, this.explanation);
}

class Quiz {
  final String id;
  final String tradeId;
  final String title;
  final String intro;
  final String badgeId;
  final List<QuizQuestion> questions;
  const Quiz(this.id, this.tradeId, this.title, this.intro, this.badgeId, this.questions);
}

enum BadgeKind { quiz, profile, reviews }

class SkillBadge {
  final String id;
  final String name;
  final String howToEarn;
  final BadgeKind kind;
  final IconData icon;
  const SkillBadge(this.id, this.name, this.howToEarn, this.kind, this.icon);
}

class CertificationResource {
  final String title;
  final String description;
  final String? url; // null means "not configured yet"
  final bool verifiedOfficial;
  const CertificationResource(this.title, this.description, this.url,
      {this.verifiedOfficial = false});
}

// ---------------------------------------------------------------------------
// Persisted models
// ---------------------------------------------------------------------------

class AppUser {
  final String id;
  final String name;
  final String phone;
  final String email;
  final UserRole role;
  final bool isDemo;

  /// Salted SHA-256 of the account password. Empty for demo accounts, which
  /// never have a password. Passwords themselves are never stored.
  final String passwordHash;
  final String? photoPath;
  const AppUser({
    required this.id,
    required this.name,
    this.phone = '',
    this.email = '',
    required this.role,
    this.isDemo = false,
    this.passwordHash = '',
    this.photoPath,
  });

  String get fullName => name;

  String get firstName {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isEmpty || parts.first.isEmpty ? 'there' : parts.first;
  }

  String get initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  AppUser copyWith({
    String? name,
    String? phone,
    String? email,
    UserRole? role,
    String? passwordHash,
    String? photoPath,
  }) =>
      AppUser(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        role: role ?? this.role,
        isDemo: isDemo,
        passwordHash: passwordHash ?? this.passwordHash,
        photoPath: photoPath ?? this.photoPath,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'role': role.name,
        'isDemo': isDemo,
        'passwordHash': passwordHash,
        'photoPath': photoPath,
      };

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        phone: j['phone'] as String? ?? '',
        email: j['email'] as String? ?? '',
        role: enumFrom(UserRole.values, j['role'], UserRole.client),
        isDemo: j['isDemo'] as bool? ?? false,
        passwordHash: j['passwordHash'] as String? ?? '',
        photoPath: j['photoPath'] as String?,
      );
}

/// A skill the worker has declared. Always self-declared unless backed by a badge.
class Skill {
  final String name;
  final String level;
  const Skill(this.name, [this.level = 'Intermediate']);
  Map<String, dynamic> toJson() => {'n': name, 'l': level};
  factory Skill.fromJson(Map<String, dynamic> j) =>
      Skill(j['n'] as String? ?? '', j['l'] as String? ?? 'Intermediate');
}

class PortfolioItem {
  final String id;
  final String title;
  final String description;
  final String tradeId;
  final String completedOn; // yyyy-MM-dd
  final List<String> imagePaths;
  final String? videoRef;
  const PortfolioItem({
    required this.id,
    required this.title,
    this.description = '',
    required this.tradeId,
    this.completedOn = '',
    this.imagePaths = const [],
    this.videoRef,
  });

  PortfolioItem copyWith({
    String? title,
    String? description,
    String? tradeId,
    String? completedOn,
    List<String>? imagePaths,
    String? videoRef,
  }) =>
      PortfolioItem(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        tradeId: tradeId ?? this.tradeId,
        completedOn: completedOn ?? this.completedOn,
        imagePaths: imagePaths ?? this.imagePaths,
        videoRef: videoRef ?? this.videoRef,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'tradeId': tradeId,
        'completedOn': completedOn,
        'imagePaths': imagePaths,
        'videoRef': videoRef,
      };

  factory PortfolioItem.fromJson(Map<String, dynamic> j) => PortfolioItem(
        id: j['id'] as String,
        title: j['title'] as String? ?? 'Untitled project',
        description: j['description'] as String? ?? '',
        tradeId: j['tradeId'] as String? ?? 'plumbing',
        completedOn: j['completedOn'] as String? ?? '',
        imagePaths: _strings(j['imagePaths']),
        videoRef: j['videoRef'] as String?,
      );
}

class WorkerProfile {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String bio;
  final String? photoPath;
  final String tradeId;
  final List<Skill> skills;
  final int years;
  final String serviceDescription;
  final String skillLevel;
  final String province;
  final String town;
  final String neighbourhood;
  final int radiusKm;
  final bool willingToTravel;
  final List<String> days;
  final String hoursStart;
  final String hoursEnd;
  final double? startingPrice;
  final PricingType pricingType;
  final bool isAvailable;
  final List<PortfolioItem> portfolio;

  /// Historic demo aggregate. Live reviews saved on this device are added on top.
  final double baseRating;
  final int baseReviews;

  /// Work history confirmed through completed SkillBridge jobs (demo data only).
  final bool verifiedHistory;

  /// Genuinely verified external qualifications. Empty unless a real check exists.
  final List<String> externalCredentials;

  /// Badge ids earned through SkillBridge quizzes (seeded for demo workers).
  final List<String> quizBadgeIds;
  final bool isDemo;
  final int colorValue;

  const WorkerProfile({
    required this.id,
    this.name = '',
    this.phone = '',
    this.email = '',
    this.bio = '',
    this.photoPath,
    this.tradeId = 'plumbing',
    this.skills = const [],
    this.years = 0,
    this.serviceDescription = '',
    this.skillLevel = 'Intermediate',
    this.province = 'Lusaka',
    this.town = 'Lusaka',
    this.neighbourhood = '',
    this.radiusKm = 15,
    this.willingToTravel = false,
    this.days = const [],
    this.hoursStart = '08:00',
    this.hoursEnd = '17:00',
    this.startingPrice,
    this.pricingType = PricingType.negotiable,
    this.isAvailable = true,
    this.portfolio = const [],
    this.baseRating = 0,
    this.baseReviews = 0,
    this.verifiedHistory = false,
    this.externalCredentials = const [],
    this.quizBadgeIds = const [],
    this.isDemo = false,
    this.colorValue = 0xFFEAF0F6,
  });

  String get location =>
      neighbourhood.isEmpty ? town : '$town, $neighbourhood';

  /// Share of profile fields filled in (0 to 1).
  double get completion {
    final checks = <bool>[
      name.trim().isNotEmpty,
      photoPath != null,
      bio.trim().length >= 20,
      skills.isNotEmpty,
      years > 0,
      serviceDescription.trim().isNotEmpty,
      town.isNotEmpty,
      days.isNotEmpty,
      startingPrice != null,
      portfolio.isNotEmpty,
    ];
    return checks.where((c) => c).length / checks.length;
  }

  WorkerProfile copyWith({
    String? name,
    String? phone,
    String? email,
    String? bio,
    String? photoPath,
    String? tradeId,
    List<Skill>? skills,
    int? years,
    String? serviceDescription,
    String? skillLevel,
    String? province,
    String? town,
    String? neighbourhood,
    int? radiusKm,
    bool? willingToTravel,
    List<String>? days,
    String? hoursStart,
    String? hoursEnd,
    double? startingPrice,
    bool clearPrice = false,
    PricingType? pricingType,
    bool? isAvailable,
    List<PortfolioItem>? portfolio,
    List<String>? quizBadgeIds,
  }) =>
      WorkerProfile(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        bio: bio ?? this.bio,
        photoPath: photoPath ?? this.photoPath,
        tradeId: tradeId ?? this.tradeId,
        skills: skills ?? this.skills,
        years: years ?? this.years,
        serviceDescription: serviceDescription ?? this.serviceDescription,
        skillLevel: skillLevel ?? this.skillLevel,
        province: province ?? this.province,
        town: town ?? this.town,
        neighbourhood: neighbourhood ?? this.neighbourhood,
        radiusKm: radiusKm ?? this.radiusKm,
        willingToTravel: willingToTravel ?? this.willingToTravel,
        days: days ?? this.days,
        hoursStart: hoursStart ?? this.hoursStart,
        hoursEnd: hoursEnd ?? this.hoursEnd,
        startingPrice: clearPrice ? null : (startingPrice ?? this.startingPrice),
        pricingType: pricingType ?? this.pricingType,
        isAvailable: isAvailable ?? this.isAvailable,
        portfolio: portfolio ?? this.portfolio,
        baseRating: baseRating,
        baseReviews: baseReviews,
        verifiedHistory: verifiedHistory,
        externalCredentials: externalCredentials,
        quizBadgeIds: quizBadgeIds ?? this.quizBadgeIds,
        isDemo: isDemo,
        colorValue: colorValue,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'bio': bio,
        'photoPath': photoPath,
        'tradeId': tradeId,
        'skills': skills.map((s) => s.toJson()).toList(),
        'years': years,
        'serviceDescription': serviceDescription,
        'skillLevel': skillLevel,
        'province': province,
        'town': town,
        'neighbourhood': neighbourhood,
        'radiusKm': radiusKm,
        'willingToTravel': willingToTravel,
        'days': days,
        'hoursStart': hoursStart,
        'hoursEnd': hoursEnd,
        'startingPrice': startingPrice,
        'pricingType': pricingType.name,
        'isAvailable': isAvailable,
        'portfolio': portfolio.map((p) => p.toJson()).toList(),
        'baseRating': baseRating,
        'baseReviews': baseReviews,
        'verifiedHistory': verifiedHistory,
        'externalCredentials': externalCredentials,
        'quizBadgeIds': quizBadgeIds,
        'isDemo': isDemo,
        'colorValue': colorValue,
      };

  factory WorkerProfile.fromJson(Map<String, dynamic> j) => WorkerProfile(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        phone: j['phone'] as String? ?? '',
        email: j['email'] as String? ?? '',
        bio: j['bio'] as String? ?? '',
        photoPath: j['photoPath'] as String?,
        tradeId: j['tradeId'] as String? ?? 'plumbing',
        skills: (j['skills'] as List? ?? const [])
            .map((e) => Skill.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        years: (j['years'] as num?)?.toInt() ?? 0,
        serviceDescription: j['serviceDescription'] as String? ?? '',
        skillLevel: j['skillLevel'] as String? ?? 'Intermediate',
        province: j['province'] as String? ?? 'Lusaka',
        town: j['town'] as String? ?? 'Lusaka',
        neighbourhood: j['neighbourhood'] as String? ?? '',
        radiusKm: (j['radiusKm'] as num?)?.toInt() ?? 15,
        willingToTravel: j['willingToTravel'] as bool? ?? false,
        days: _strings(j['days']),
        hoursStart: j['hoursStart'] as String? ?? '08:00',
        hoursEnd: j['hoursEnd'] as String? ?? '17:00',
        startingPrice: _dbl(j['startingPrice']),
        pricingType:
            enumFrom(PricingType.values, j['pricingType'], PricingType.negotiable),
        isAvailable: j['isAvailable'] as bool? ?? true,
        portfolio: (j['portfolio'] as List? ?? const [])
            .map((e) =>
                PortfolioItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        baseRating: _dbl(j['baseRating']) ?? 0,
        baseReviews: (j['baseReviews'] as num?)?.toInt() ?? 0,
        verifiedHistory: j['verifiedHistory'] as bool? ?? false,
        externalCredentials: _strings(j['externalCredentials']),
        quizBadgeIds: _strings(j['quizBadgeIds']),
        isDemo: j['isDemo'] as bool? ?? false,
        colorValue: (j['colorValue'] as num?)?.toInt() ?? 0xFFEAF0F6,
      );
}

class Review {
  final String id;
  final String workerId;
  final String clientId;
  final String clientName;
  final int rating;
  final String text;
  final List<String> tags;
  final DateTime createdAt;
  final String contextId; // job or booking id this review belongs to
  final String contextLabel;
  final bool isDemo;
  const Review({
    required this.id,
    required this.workerId,
    required this.clientId,
    required this.clientName,
    required this.rating,
    required this.text,
    this.tags = const [],
    required this.createdAt,
    required this.contextId,
    this.contextLabel = '',
    this.isDemo = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'workerId': workerId,
        'clientId': clientId,
        'clientName': clientName,
        'rating': rating,
        'text': text,
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
        'contextId': contextId,
        'contextLabel': contextLabel,
        'isDemo': isDemo,
      };

  factory Review.fromJson(Map<String, dynamic> j) => Review(
        id: j['id'] as String,
        workerId: j['workerId'] as String? ?? '',
        clientId: j['clientId'] as String? ?? '',
        clientName: j['clientName'] as String? ?? 'Client',
        rating: ((j['rating'] as num?)?.toInt() ?? 5).clamp(1, 5),
        text: j['text'] as String? ?? '',
        tags: _strings(j['tags']),
        createdAt: parseDate(j['createdAt']),
        contextId: j['contextId'] as String? ?? '',
        contextLabel: j['contextLabel'] as String? ?? '',
        isDemo: j['isDemo'] as bool? ?? false,
      );
}

class Job {
  final String id;
  final String title;
  final String tradeId;
  final String description;
  final String province;
  final String town;
  final String neighbourhood;
  final String completeBy; // yyyy-MM-dd or empty
  final JobUrgency urgency;
  final double? budgetMin;
  final double? budgetMax;
  final PricingType pricingPref;
  final List<String> photoPaths;
  final String contactMethod;
  final String clientId;
  final String clientName;
  final DateTime postedAt;
  final JobStatus status;
  final bool isDemo;
  const Job({
    required this.id,
    required this.title,
    required this.tradeId,
    this.description = '',
    this.province = 'Lusaka',
    this.town = 'Lusaka',
    this.neighbourhood = '',
    this.completeBy = '',
    this.urgency = JobUrgency.flexible,
    this.budgetMin,
    this.budgetMax,
    this.pricingPref = PricingType.negotiable,
    this.photoPaths = const [],
    this.contactMethod = 'In-app message',
    required this.clientId,
    required this.clientName,
    required this.postedAt,
    this.status = JobStatus.open,
    this.isDemo = false,
  });

  String get location => neighbourhood.isEmpty ? town : '$town, $neighbourhood';

  Job copyWith({JobStatus? status}) => Job(
        id: id,
        title: title,
        tradeId: tradeId,
        description: description,
        province: province,
        town: town,
        neighbourhood: neighbourhood,
        completeBy: completeBy,
        urgency: urgency,
        budgetMin: budgetMin,
        budgetMax: budgetMax,
        pricingPref: pricingPref,
        photoPaths: photoPaths,
        contactMethod: contactMethod,
        clientId: clientId,
        clientName: clientName,
        postedAt: postedAt,
        status: status ?? this.status,
        isDemo: isDemo,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'tradeId': tradeId,
        'description': description,
        'province': province,
        'town': town,
        'neighbourhood': neighbourhood,
        'completeBy': completeBy,
        'urgency': urgency.name,
        'budgetMin': budgetMin,
        'budgetMax': budgetMax,
        'pricingPref': pricingPref.name,
        'photoPaths': photoPaths,
        'contactMethod': contactMethod,
        'clientId': clientId,
        'clientName': clientName,
        'postedAt': postedAt.toIso8601String(),
        'status': status.name,
        'isDemo': isDemo,
      };

  factory Job.fromJson(Map<String, dynamic> j) => Job(
        id: j['id'] as String,
        title: j['title'] as String? ?? 'Untitled job',
        tradeId: j['tradeId'] as String? ?? 'plumbing',
        description: j['description'] as String? ?? '',
        province: j['province'] as String? ?? 'Lusaka',
        town: j['town'] as String? ?? 'Lusaka',
        neighbourhood: j['neighbourhood'] as String? ?? '',
        completeBy: j['completeBy'] as String? ?? '',
        urgency: enumFrom(JobUrgency.values, j['urgency'], JobUrgency.flexible),
        budgetMin: _dbl(j['budgetMin']),
        budgetMax: _dbl(j['budgetMax']),
        pricingPref:
            enumFrom(PricingType.values, j['pricingPref'], PricingType.negotiable),
        photoPaths: _strings(j['photoPaths']),
        contactMethod: j['contactMethod'] as String? ?? 'In-app message',
        clientId: j['clientId'] as String? ?? '',
        clientName: j['clientName'] as String? ?? 'Client',
        postedAt: parseDate(j['postedAt']),
        status: enumFrom(JobStatus.values, j['status'], JobStatus.open),
        isDemo: j['isDemo'] as bool? ?? false,
      );
}

class JobApplication {
  final String id;
  final String jobId;
  final String workerId;
  final ApplicationStatus status;
  final String message;
  final DateTime appliedAt;
  const JobApplication({
    required this.id,
    required this.jobId,
    required this.workerId,
    this.status = ApplicationStatus.pending,
    this.message = '',
    required this.appliedAt,
  });

  JobApplication copyWith({ApplicationStatus? status}) => JobApplication(
        id: id,
        jobId: jobId,
        workerId: workerId,
        status: status ?? this.status,
        message: message,
        appliedAt: appliedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'jobId': jobId,
        'workerId': workerId,
        'status': status.name,
        'message': message,
        'appliedAt': appliedAt.toIso8601String(),
      };

  factory JobApplication.fromJson(Map<String, dynamic> j) => JobApplication(
        id: j['id'] as String,
        jobId: j['jobId'] as String? ?? '',
        workerId: j['workerId'] as String? ?? '',
        status: enumFrom(
            ApplicationStatus.values, j['status'], ApplicationStatus.pending),
        message: j['message'] as String? ?? '',
        appliedAt: parseDate(j['appliedAt']),
      );
}

/// The form payload a client submits. It becomes a [Booking] once saved.
class ServiceRequest {
  final String workerId;
  final String service;
  final String description;
  final DateTime preferredDate;
  final String preferredTime;
  final String location;
  final double? budget;
  final String notes;
  const ServiceRequest({
    required this.workerId,
    required this.service,
    required this.description,
    required this.preferredDate,
    required this.preferredTime,
    required this.location,
    this.budget,
    this.notes = '',
  });
}

class Booking {
  final String id;
  final String workerId;
  final String clientId;
  final String clientName;
  final String service;
  final String description;
  final DateTime preferredDate;
  final String preferredTime;
  final String location;
  final double? budget;
  final String notes;
  final BookingStatus status;
  final DateTime createdAt;
  final bool isDemo;
  const Booking({
    required this.id,
    required this.workerId,
    required this.clientId,
    required this.clientName,
    required this.service,
    this.description = '',
    required this.preferredDate,
    this.preferredTime = '09:00',
    this.location = '',
    this.budget,
    this.notes = '',
    this.status = BookingStatus.requested,
    required this.createdAt,
    this.isDemo = false,
  });

  Booking copyWith({BookingStatus? status}) => Booking(
        id: id,
        workerId: workerId,
        clientId: clientId,
        clientName: clientName,
        service: service,
        description: description,
        preferredDate: preferredDate,
        preferredTime: preferredTime,
        location: location,
        budget: budget,
        notes: notes,
        status: status ?? this.status,
        createdAt: createdAt,
        isDemo: isDemo,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'workerId': workerId,
        'clientId': clientId,
        'clientName': clientName,
        'service': service,
        'description': description,
        'preferredDate': preferredDate.toIso8601String(),
        'preferredTime': preferredTime,
        'location': location,
        'budget': budget,
        'notes': notes,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'isDemo': isDemo,
      };

  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
        id: j['id'] as String,
        workerId: j['workerId'] as String? ?? '',
        clientId: j['clientId'] as String? ?? '',
        clientName: j['clientName'] as String? ?? 'Client',
        service: j['service'] as String? ?? 'Service',
        description: j['description'] as String? ?? '',
        preferredDate: parseDate(j['preferredDate']),
        preferredTime: j['preferredTime'] as String? ?? '09:00',
        location: j['location'] as String? ?? '',
        budget: _dbl(j['budget']),
        notes: j['notes'] as String? ?? '',
        status: enumFrom(BookingStatus.values, j['status'], BookingStatus.requested),
        createdAt: parseDate(j['createdAt']),
        isDemo: j['isDemo'] as bool? ?? false,
      );
}

class Message {
  final String id;
  final bool fromWorker;
  final String text;
  final DateTime at;
  const Message(
      {required this.id,
      required this.fromWorker,
      required this.text,
      required this.at});
  Map<String, dynamic> toJson() =>
      {'id': id, 'fromWorker': fromWorker, 'text': text, 'at': at.toIso8601String()};
  factory Message.fromJson(Map<String, dynamic> j) => Message(
        id: j['id'] as String,
        fromWorker: j['fromWorker'] as bool? ?? false,
        text: j['text'] as String? ?? '',
        at: parseDate(j['at']),
      );
}

/// A local-only conversation between one worker and one client.
class Conversation {
  final String id;
  final String workerId;
  final String clientId;
  final String clientName;
  final List<Message> messages;
  final int unreadForWorker;
  final int unreadForClient;
  const Conversation({
    required this.id,
    required this.workerId,
    required this.clientId,
    required this.clientName,
    this.messages = const [],
    this.unreadForWorker = 0,
    this.unreadForClient = 0,
  });

  Message? get last => messages.isEmpty ? null : messages.last;

  Conversation copyWith({
    List<Message>? messages,
    int? unreadForWorker,
    int? unreadForClient,
  }) =>
      Conversation(
        id: id,
        workerId: workerId,
        clientId: clientId,
        clientName: clientName,
        messages: messages ?? this.messages,
        unreadForWorker: unreadForWorker ?? this.unreadForWorker,
        unreadForClient: unreadForClient ?? this.unreadForClient,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'workerId': workerId,
        'clientId': clientId,
        'clientName': clientName,
        'messages': messages.map((m) => m.toJson()).toList(),
        'unreadForWorker': unreadForWorker,
        'unreadForClient': unreadForClient,
      };

  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
        id: j['id'] as String,
        workerId: j['workerId'] as String? ?? '',
        clientId: j['clientId'] as String? ?? '',
        clientName: j['clientName'] as String? ?? 'Client',
        messages: (j['messages'] as List? ?? const [])
            .map((e) => Message.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        unreadForWorker: (j['unreadForWorker'] as num?)?.toInt() ?? 0,
        unreadForClient: (j['unreadForClient'] as num?)?.toInt() ?? 0,
      );
}

class NotificationItem {
  final String id;
  final UserRole forRole;
  final NotifType type;
  final String title;
  final String body;
  final DateTime at;
  final bool read;
  final String? route; // optional in-app path to open
  const NotificationItem({
    required this.id,
    required this.forRole,
    required this.type,
    required this.title,
    required this.body,
    required this.at,
    this.read = false,
    this.route,
  });

  NotificationItem copyWith({bool? read}) => NotificationItem(
        id: id,
        forRole: forRole,
        type: type,
        title: title,
        body: body,
        at: at,
        read: read ?? this.read,
        route: route,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'forRole': forRole.name,
        'type': type.name,
        'title': title,
        'body': body,
        'at': at.toIso8601String(),
        'read': read,
        'route': route,
      };

  factory NotificationItem.fromJson(Map<String, dynamic> j) => NotificationItem(
        id: j['id'] as String,
        forRole: enumFrom(UserRole.values, j['forRole'], UserRole.client),
        type: enumFrom(NotifType.values, j['type'], NotifType.message),
        title: j['title'] as String? ?? '',
        body: j['body'] as String? ?? '',
        at: parseDate(j['at']),
        read: j['read'] as bool? ?? false,
        route: j['route'] as String?,
      );
}

class QuizAttempt {
  final String id;
  final String quizId;
  final String workerId;
  final int score;
  final int total;
  final List<int> answers;
  final DateTime at;
  const QuizAttempt({
    required this.id,
    required this.quizId,
    required this.workerId,
    required this.score,
    required this.total,
    required this.answers,
    required this.at,
  });

  double get percent => total == 0 ? 0 : score / total;

  Map<String, dynamic> toJson() => {
        'id': id,
        'quizId': quizId,
        'workerId': workerId,
        'score': score,
        'total': total,
        'answers': answers,
        'at': at.toIso8601String(),
      };

  factory QuizAttempt.fromJson(Map<String, dynamic> j) => QuizAttempt(
        id: j['id'] as String,
        quizId: j['quizId'] as String? ?? '',
        workerId: j['workerId'] as String? ?? '',
        score: (j['score'] as num?)?.toInt() ?? 0,
        total: (j['total'] as num?)?.toInt() ?? 0,
        answers: (j['answers'] as List? ?? const [])
            .map((e) => (e as num).toInt())
            .toList(),
        at: parseDate(j['at']),
      );
}

class UserSettings {
  final bool notifyJobs;
  final bool notifyMessages;
  final bool notifyReminders;
  const UserSettings({
    this.notifyJobs = true,
    this.notifyMessages = true,
    this.notifyReminders = true,
  });

  UserSettings copyWith({bool? notifyJobs, bool? notifyMessages, bool? notifyReminders}) =>
      UserSettings(
        notifyJobs: notifyJobs ?? this.notifyJobs,
        notifyMessages: notifyMessages ?? this.notifyMessages,
        notifyReminders: notifyReminders ?? this.notifyReminders,
      );

  Map<String, dynamic> toJson() => {
        'notifyJobs': notifyJobs,
        'notifyMessages': notifyMessages,
        'notifyReminders': notifyReminders,
      };

  factory UserSettings.fromJson(Map<String, dynamic> j) => UserSettings(
        notifyJobs: j['notifyJobs'] as bool? ?? true,
        notifyMessages: j['notifyMessages'] as bool? ?? true,
        notifyReminders: j['notifyReminders'] as bool? ?? true,
      );
}
