import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../core/constants/constants.dart';
import '../../models/models.dart';
import 'rules.dart';

// ---------------------------------------------------------------------------
// Search
// ---------------------------------------------------------------------------

enum SortMode { bestMatch, highestRated, mostExperienced, lowestPrice, nearestTown }

extension SortLabel on SortMode {
  String get label {
    switch (this) {
      case SortMode.bestMatch:
        return 'Best match';
      case SortMode.highestRated:
        return 'Highest rated';
      case SortMode.mostExperienced:
        return 'Most experienced';
      case SortMode.lowestPrice:
        return 'Lowest starting price';
      case SortMode.nearestTown:
        return 'Nearest town';
    }
  }
}

class SearchQuery {
  final String text;
  final String? tradeId;
  final String? town;
  final bool availableOnly;
  final double minRating;
  final bool verifiedOnly;
  final double? maxPrice;
  final SortMode sort;
  const SearchQuery({
    this.text = '',
    this.tradeId,
    this.town,
    this.availableOnly = false,
    this.minRating = 0,
    this.verifiedOnly = false,
    this.maxPrice,
    this.sort = SortMode.bestMatch,
  });

  SearchQuery copyWith({
    String? text,
    String? tradeId,
    bool clearTrade = false,
    String? town,
    bool clearTown = false,
    bool? availableOnly,
    double? minRating,
    bool? verifiedOnly,
    double? maxPrice,
    bool clearPrice = false,
    SortMode? sort,
  }) =>
      SearchQuery(
        text: text ?? this.text,
        tradeId: clearTrade ? null : (tradeId ?? this.tradeId),
        town: clearTown ? null : (town ?? this.town),
        availableOnly: availableOnly ?? this.availableOnly,
        minRating: minRating ?? this.minRating,
        verifiedOnly: verifiedOnly ?? this.verifiedOnly,
        maxPrice: clearPrice ? null : (maxPrice ?? this.maxPrice),
        sort: sort ?? this.sort,
      );

  int get activeFilterCount =>
      (tradeId != null ? 1 : 0) +
      (town != null ? 1 : 0) +
      (availableOnly ? 1 : 0) +
      (minRating > 0 ? 1 : 0) +
      (verifiedOnly ? 1 : 0) +
      (maxPrice != null ? 1 : 0);
}

typedef RatingLookup = RatingSummary Function(WorkerProfile w);

/// A future backend can provide real search results by implementing this.
abstract class WorkerSearchRepository {
  List<WorkerProfile> search(
    Iterable<WorkerProfile> all,
    SearchQuery q, {
    required RatingLookup rating,
  });
}

bool isVerified(WorkerProfile w) =>
    w.verifiedHistory || w.externalCredentials.isNotEmpty;

class LocalWorkerSearchRepository implements WorkerSearchRepository {
  const LocalWorkerSearchRepository();

  String _haystack(WorkerProfile w) => [
        w.name,
        tradeById(w.tradeId).name,
        ...w.skills.map((s) => s.name),
        w.town,
        w.neighbourhood,
        w.province,
        w.serviceDescription,
      ].join(' ').toLowerCase();

  int _relevance(WorkerProfile w, List<String> tokens) {
    if (tokens.isEmpty) return 0;
    var score = 0;
    final name = w.name.toLowerCase();
    final trade = tradeById(w.tradeId).name.toLowerCase();
    final skills = w.skills.map((s) => s.name.toLowerCase()).join(' ');
    final loc = '${w.town} ${w.neighbourhood}'.toLowerCase();
    for (final t in tokens) {
      if (name.contains(t)) score += 4;
      if (trade.contains(t)) score += 3;
      if (skills.contains(t)) score += 2;
      if (loc.contains(t)) score += 1;
    }
    return score;
  }

  @override
  List<WorkerProfile> search(
    Iterable<WorkerProfile> all,
    SearchQuery q, {
    required RatingLookup rating,
  }) {
    final tokens = q.text
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    final out = all.where((w) {
      if (w.name.trim().isEmpty) return false;
      if (q.tradeId != null && w.tradeId != q.tradeId) return false;
      if (q.town != null && w.town != q.town) return false;
      if (q.availableOnly && !w.isAvailable) return false;
      if (q.verifiedOnly && !isVerified(w)) return false;
      if (q.minRating > 0 && rating(w).average < q.minRating) return false;
      if (q.maxPrice != null) {
        final p = w.startingPrice;
        if (p == null || p > q.maxPrice!) return false;
      }
      if (tokens.isNotEmpty) {
        final h = _haystack(w);
        if (!tokens.every(h.contains)) return false;
      }
      return true;
    }).toList();

    int byRating(WorkerProfile a, WorkerProfile b) {
      final c = rating(b).average.compareTo(rating(a).average);
      return c != 0 ? c : rating(b).count.compareTo(rating(a).count);
    }

    switch (q.sort) {
      case SortMode.bestMatch:
        out.sort((a, b) {
          final c = _relevance(b, tokens).compareTo(_relevance(a, tokens));
          return c != 0 ? c : byRating(a, b);
        });
      case SortMode.highestRated:
        out.sort(byRating);
      case SortMode.mostExperienced:
        out.sort((a, b) {
          final c = b.years.compareTo(a.years);
          return c != 0 ? c : byRating(a, b);
        });
      case SortMode.lowestPrice:
        out.sort((a, b) {
          final pa = a.startingPrice ?? double.infinity;
          final pb = b.startingPrice ?? double.infinity;
          final c = pa.compareTo(pb);
          return c != 0 ? c : byRating(a, b);
        });
      case SortMode.nearestTown:
        // No coordinates are collected, so "nearest" means same town, then
        // same province, then everywhere else.
        int rank(WorkerProfile w) {
          if (q.town == null) return 0;
          if (w.town == q.town) return 0;
          if (w.province == provinceOfTown(q.town!)) return 1;
          return 2;
        }
        out.sort((a, b) {
          final c = rank(a).compareTo(rank(b));
          return c != 0 ? c : byRating(a, b);
        });
    }
    return out;
  }
}

// ---------------------------------------------------------------------------
// Authentication (demo only)
// ---------------------------------------------------------------------------

/// Replace with a real, secure backend. This local implementation keeps only a
/// salted SHA-256 hash of the password on the device, never the password
/// itself, and checks it when signing in.
/// A salted hash of [password] for [salt] (the account id). Plain passwords
/// are never written to storage.
String hashPassword(String password, String salt) =>
    sha256.convert(utf8.encode('$salt::skillbridge::$password')).toString();

bool verifyPassword(AppUser user, String password) {
  if (user.isDemo) return true;
  if (user.passwordHash.isEmpty) return false;
  return hashPassword(password, user.id) == user.passwordHash;
}

abstract class AuthRepository {
  String? validatePassword(String password);
  AppUser? findAccount(List<AppUser> accounts, String identifier);
  AppUser? authenticate(
    List<AppUser> accounts,
    String identifier,
    String password,
  );
  AppUser createAccount({
    required String name,
    required String phone,
    String email = '',
    required UserRole role,
    required String password,
  });
  AppUser demoUser(UserRole role, {String? workerName});
}

class DemoAuthRepository implements AuthRepository {
  const DemoAuthRepository();

  @override
  String? validatePassword(String password) =>
      password.length < 8 ? 'Use at least 8 characters.' : null;

  @override
  AppUser? findAccount(List<AppUser> accounts, String identifier) {
    final id = identifier.trim().toLowerCase();
    if (id.isEmpty) return null;
    final digits = identifier.replaceAll(RegExp(r'[^0-9]'), '');
    for (final a in accounts) {
      if (a.email.isNotEmpty && a.email.toLowerCase() == id) return a;
      final aDigits = a.phone.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length >= 9 &&
          aDigits.isNotEmpty &&
          aDigits.endsWith(digits.substring(digits.length - 9))) {
        return a;
      }
    }
    return null;
  }

  @override
  AppUser? authenticate(
    List<AppUser> accounts,
    String identifier,
    String password,
  ) {
    final user = findAccount(accounts, identifier);
    if (user == null) return null;
    if (!verifyPassword(user, password)) return null;
    return user;
  }

  @override
  AppUser createAccount({
    required String name,
    required String phone,
    String email = '',
    required UserRole role,
    required String password,
  }) {
    final id = 'u_${DateTime.now().microsecondsSinceEpoch}';
    return AppUser(
      id: id,
      name: name.trim(),
      phone: phone,
      email: email.trim(),
      role: role,
      passwordHash: hashPassword(password, id),
    );
  }

  @override
  AppUser demoUser(UserRole role, {String? workerName}) => AppUser(
        id: role == UserRole.client ? 'u_demo_client' : 'u_demo_worker',
        name: role == UserRole.client ? 'Natasha Phiri' : (workerName ?? 'David Mwamba'),
        role: role,
        isDemo: true,
      );
}

// ---------------------------------------------------------------------------
// Synchronisation (placeholder for a future backend)
// ---------------------------------------------------------------------------

class SyncResult {
  final int synced;
  final int pending;
  final String message;
  const SyncResult(this.synced, this.pending, this.message);
}

abstract class SyncService {
  bool get isConfigured;
  Future<SyncResult> sync(List<String> pendingChanges);
}

/// No server exists yet, so nothing is ever reported as synced.
class LocalOnlySyncService implements SyncService {
  const LocalOnlySyncService();
  @override
  bool get isConfigured => false;
  @override
  Future<SyncResult> sync(List<String> pendingChanges) async => SyncResult(
        0,
        pendingChanges.length,
        'No server is configured, so ${pendingChanges.length} change(s) are saved on this device only.',
      );
}
