import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/constants.dart';
import '../data/demo/demo_data.dart';
import '../data/local/local_store.dart';
import '../data/repositories/repositories.dart';
import '../data/repositories/rules.dart';
import '../models/models.dart';

// ---------------------------------------------------------------------------
// Service providers (each one can be swapped for a real implementation)
// ---------------------------------------------------------------------------

final storeProvider = Provider<LocalStore>((ref) => throw UnimplementedError('Override storeProvider in main()'));
final mediaProvider = Provider<MediaStore>((ref) => MediaStore());
final authRepoProvider = Provider<AuthRepository>((_) => const DemoAuthRepository());
final searchRepoProvider = Provider<WorkerSearchRepository>((_) => const LocalWorkerSearchRepository());
final syncProvider = Provider<SyncService>((_) => const LocalOnlySyncService());

/// True when the device reports at least one network interface. It does not
/// prove the internet is reachable, and nothing in the prototype needs it.
final onlineProvider = StreamProvider<bool>((ref) async* {
  bool on(List<ConnectivityResult> r) => r.any((e) => e != ConnectivityResult.none);
  try {
    final c = Connectivity();
    yield on(await c.checkConnectivity());
    yield* c.onConnectivityChanged.map(on);
  } catch (_) {
    yield true;
  }
});

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class AppState {
  final bool onboarded;
  final UserRole? chosenRole;
  final AppUser? user;
  final List<AppUser> accounts;
  final List<WorkerProfile> workers;
  final List<Job> jobs;
  final List<JobApplication> applications;
  final List<Booking> bookings;
  final List<Review> reviews;
  final List<Conversation> conversations;
  final List<NotificationItem> notifications;
  final List<QuizAttempt> attempts;
  final Set<String> favourites;
  final List<String> viewedWorkers;
  final List<String> viewedTrades;
  final UserSettings settings;
  final List<String> pending;

  const AppState({
    this.onboarded = false,
    this.chosenRole,
    this.user,
    this.accounts = const [],
    this.workers = const [],
    this.jobs = const [],
    this.applications = const [],
    this.bookings = const [],
    this.reviews = const [],
    this.conversations = const [],
    this.notifications = const [],
    this.attempts = const [],
    this.favourites = const {},
    this.viewedWorkers = const [],
    this.viewedTrades = const [],
    this.settings = const UserSettings(),
    this.pending = const [],
  });

  AppState copyWith({
    bool? onboarded,
    UserRole? chosenRole,
    AppUser? user,
    bool clearUser = false,
    List<AppUser>? accounts,
    List<WorkerProfile>? workers,
    List<Job>? jobs,
    List<JobApplication>? applications,
    List<Booking>? bookings,
    List<Review>? reviews,
    List<Conversation>? conversations,
    List<NotificationItem>? notifications,
    List<QuizAttempt>? attempts,
    Set<String>? favourites,
    List<String>? viewedWorkers,
    List<String>? viewedTrades,
    UserSettings? settings,
    List<String>? pending,
  }) =>
      AppState(
        onboarded: onboarded ?? this.onboarded,
        chosenRole: chosenRole ?? this.chosenRole,
        user: clearUser ? null : (user ?? this.user),
        accounts: accounts ?? this.accounts,
        workers: workers ?? this.workers,
        jobs: jobs ?? this.jobs,
        applications: applications ?? this.applications,
        bookings: bookings ?? this.bookings,
        reviews: reviews ?? this.reviews,
        conversations: conversations ?? this.conversations,
        notifications: notifications ?? this.notifications,
        attempts: attempts ?? this.attempts,
        favourites: favourites ?? this.favourites,
        viewedWorkers: viewedWorkers ?? this.viewedWorkers,
        viewedTrades: viewedTrades ?? this.viewedTrades,
        settings: settings ?? this.settings,
        pending: pending ?? this.pending,
      );

  // ---- identity helpers ----------------------------------------------------

  UserRole get role => user?.role ?? chosenRole ?? UserRole.client;
  bool get isWorker => role == UserRole.worker;

  /// Where the splash screen sends the user next.
  String get initialRouteAfterSplash {
    if (user != null) return '/home';
    return onboarded ? '/role' : '/intro';
  }
  String get myWorkerId => (user?.isDemo ?? false) ? kDefaultDemoWorkerId : kMyWorkerId;
  String get myClientId => (user?.isDemo ?? false) ? kDemoClientId : (user?.id ?? kDemoClientId);
  String get myClientName => (user?.isDemo ?? false) ? kDemoClientName : (user?.name ?? 'Client');
  WorkerProfile? get myWorker => worker(myWorkerId);

  /// First name shown in greetings.
  String get greetingName => isWorker ? (myWorker?.name.trim().split(' ').first ?? user?.firstName ?? 'there') : (user?.firstName ?? 'there');

  WorkerProfile? worker(String id) {
    for (final w in workers) {
      if (w.id == id) return w;
    }
    return null;
  }

  Job? job(String id) {
    for (final j in jobs) {
      if (j.id == id) return j;
    }
    return null;
  }

  Booking? booking(String id) {
    for (final b in bookings) {
      if (b.id == id) return b;
    }
    return null;
  }

  Conversation? conversation(String id) {
    for (final c in conversations) {
      if (c.id == id) return c;
    }
    return null;
  }

  RatingSummary ratingFor(WorkerProfile w) => summarizeRatings(w, reviews);
  List<Review> reviewsFor(String workerId) => reviews.where((r) => r.workerId == workerId).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  Set<String> badgesFor(WorkerProfile w) => computeBadges(worker: w, reviews: reviews, attempts: attempts);

  List<JobApplication> applicationsForJob(String jobId) => applications.where((a) => a.jobId == jobId).toList();
  JobApplication? myApplication(String jobId) {
    JobApplication? found;
    for (final a in applications) {
      if (a.jobId == jobId && a.workerId == myWorkerId) found = a;
    }
    return found;
  }

  // ---- notifications ---------------------------------------------------------

  List<NotificationItem> get myNotifications => notifications.where((n) => n.forRole == role).toList()..sort((a, b) => b.at.compareTo(a.at));
  int get unreadNotifications => myNotifications.where((n) => !n.read).length;

  List<Conversation> get myConversations {
    final l = conversations.where((c) => isWorker ? c.workerId == myWorkerId : c.clientId == myClientId).toList();
    l.sort((a, b) => (b.last?.at ?? DateTime(2000)).compareTo(a.last?.at ?? DateTime(2000)));
    return l;
  }

  int unreadFor(Conversation c) => isWorker ? c.unreadForWorker : c.unreadForClient;
  int get unreadMessages => myConversations.fold(0, (a, c) => a + unreadFor(c));

  // ---- reviews ---------------------------------------------------------------

  /// A completed job or booking this client can review for the worker, or null.
  /// Returns (contextId, label).
  List<({String id, String label})> reviewableContexts(String workerId) {
    final out = <({String id, String label})>[];
    if (isWorker) return out;
    for (final b in bookings) {
      if (b.clientId == myClientId && b.workerId == workerId && b.status == BookingStatus.completed && !alreadyReviewed(b.id)) {
        out.add((id: b.id, label: b.service));
      }
    }
    for (final j in jobs) {
      if (j.clientId != myClientId || j.status != JobStatus.completed || alreadyReviewed(j.id)) continue;
      final accepted = applications.any((a) => a.jobId == j.id && a.workerId == workerId && a.status == ApplicationStatus.accepted);
      if (accepted) out.add((id: j.id, label: j.title));
    }
    return out;
  }

  bool alreadyReviewed(String contextId) => reviews.any((r) => r.contextId == contextId && r.clientId == myClientId);
}

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

const _kSeeded = 'sb.seeded';
const _kOnboarded = 'sb.onboarded';
const _kChosenRole = 'sb.chosenRole';
const _kUser = 'sb.user';
const _kAccounts = 'sb.accounts';
const _kWorkers = 'sb.workers';
const _kJobs = 'sb.jobs';
const _kApps = 'sb.applications';
const _kBookings = 'sb.bookings';
const _kReviews = 'sb.reviews';
const _kConvs = 'sb.conversations';
const _kNotifs = 'sb.notifications';
const _kAttempts = 'sb.attempts';
const _kFavs = 'sb.favourites';
const _kViewedW = 'sb.viewedWorkers';
const _kViewedT = 'sb.viewedTrades';
const _kSettings = 'sb.settings';
const _kPending = 'sb.pending';
const _kDraft = 'sb.profileDraft';

class AppController extends Notifier<AppState> {
  LocalStore get _s => ref.read(storeProvider);

  @override
  AppState build() => _load();

  AppState _load() {
    final s = _s;
    // Seed once. The flag plus stable ids mean launching again never duplicates records.
    if (!s.getBool(_kSeeded)) {
      final seed = DemoSeed.build(DateTime.now());
      s.writeList(_kWorkers, seed.workers.map((e) => e.toJson()).toList());
      s.writeList(_kJobs, seed.jobs.map((e) => e.toJson()).toList());
      s.writeList(_kApps, seed.applications.map((e) => e.toJson()).toList());
      s.writeList(_kBookings, seed.bookings.map((e) => e.toJson()).toList());
      s.writeList(_kReviews, seed.reviews.map((e) => e.toJson()).toList());
      s.writeList(_kConvs, seed.conversations.map((e) => e.toJson()).toList());
      s.writeList(_kNotifs, seed.notifications.map((e) => e.toJson()).toList());
      s.setBool(_kSeeded, true);
    }
    final userMap = s.readMap(_kUser);
    AppUser? user;
    if (userMap != null) {
      try {
        user = AppUser.fromJson(userMap);
      } catch (_) {
        user = null;
      }
    }
    final settingsMap = s.readMap(_kSettings);
    final roleName = s.getString(_kChosenRole);
    return AppState(
      onboarded: s.getBool(_kOnboarded),
      chosenRole: roleName == null ? null : enumFrom(UserRole.values, roleName, UserRole.client),
      user: user,
      accounts: s.readList(_kAccounts, AppUser.fromJson),
      workers: s.readList(_kWorkers, WorkerProfile.fromJson),
      jobs: s.readList(_kJobs, Job.fromJson),
      applications: s.readList(_kApps, JobApplication.fromJson),
      bookings: s.readList(_kBookings, Booking.fromJson),
      reviews: s.readList(_kReviews, Review.fromJson),
      conversations: s.readList(_kConvs, Conversation.fromJson),
      notifications: s.readList(_kNotifs, NotificationItem.fromJson),
      attempts: s.readList(_kAttempts, QuizAttempt.fromJson),
      favourites: s.getStrings(_kFavs).toSet(),
      viewedWorkers: s.getStrings(_kViewedW),
      viewedTrades: s.getStrings(_kViewedT),
      settings: settingsMap == null ? const UserSettings() : UserSettings.fromJson(settingsMap),
      pending: s.getStrings(_kPending),
    );
  }

  String _id(String p) => '${p}_${DateTime.now().microsecondsSinceEpoch}';

  void _pend(String what) {
    final l = [...state.pending, what];
    final trimmed = l.length > 100 ? l.sublist(l.length - 100) : l;
    state = state.copyWith(pending: trimmed);
    _s.setStrings(_kPending, trimmed);
  }

  void _saveWorkers() => _s.writeList(_kWorkers, state.workers.map((e) => e.toJson()).toList());
  void _saveJobs() => _s.writeList(_kJobs, state.jobs.map((e) => e.toJson()).toList());
  void _saveApps() => _s.writeList(_kApps, state.applications.map((e) => e.toJson()).toList());
  void _saveBookings() => _s.writeList(_kBookings, state.bookings.map((e) => e.toJson()).toList());
  void _saveReviews() => _s.writeList(_kReviews, state.reviews.map((e) => e.toJson()).toList());
  void _saveConvs() => _s.writeList(_kConvs, state.conversations.map((e) => e.toJson()).toList());
  void _saveNotifs() => _s.writeList(_kNotifs, state.notifications.map((e) => e.toJson()).toList());
  void _saveUser() {
    final u = state.user;
    _s.writeMap(_kUser, u?.toJson());
    // Keep the saved account in step with edits to the signed-in user.
    if (u != null && !u.isDemo) {
      final accounts = [for (final a in state.accounts) a.id == u.id ? u : a];
      state = state.copyWith(accounts: accounts);
      _s.writeList(_kAccounts, accounts.map((e) => e.toJson()).toList());
    }
  }

  void _notify(UserRole forRole, NotifType type, String title, String body, {String? route}) {
    final cat = type.category;
    final st = state.settings;
    if ((cat == 'jobs' && !st.notifyJobs) || (cat == 'messages' && !st.notifyMessages) || (cat == 'reminders' && !st.notifyReminders)) return;
    final n = NotificationItem(id: _id('n'), forRole: forRole, type: type, title: title, body: body, at: DateTime.now(), route: route);
    state = state.copyWith(notifications: [n, ...state.notifications]);
    _saveNotifs();
  }

  // ---- onboarding and account ------------------------------------------------

  void completeOnboarding() {
    state = state.copyWith(onboarded: true);
    _s.setBool(_kOnboarded, true);
  }

  void chooseRole(UserRole r) {
    state = state.copyWith(chosenRole: r);
    _s.setString(_kChosenRole, r.name);
  }

  /// Returns an error message, or null when the account was created.
  String? register({
    required String name,
    required String phone,
    String email = '',
    required String password,
  }) {
    final auth = ref.read(authRepoProvider);
    final passwordError = auth.validatePassword(password);
    if (passwordError != null) return passwordError;
    final existing = auth.findAccount(state.accounts, phone) ?? (email.isEmpty ? null : auth.findAccount(state.accounts, email));
    if (existing != null) return 'An account with these details already exists on this device. Try signing in.';
    final u = auth.createAccount(name: name, phone: phone, email: email, role: state.chosenRole ?? UserRole.client, password: password);
    final accounts = [...state.accounts, u];
    state = state.copyWith(accounts: accounts, user: u, onboarded: true);
    _s.writeList(_kAccounts, accounts.map((e) => e.toJson()).toList());
    _s.setBool(_kOnboarded, true);
    _saveUser();
    return null;
  }

  String? signIn(String identifier, String password) {
    final auth = ref.read(authRepoProvider);
    final u = auth.findAccount(state.accounts, identifier);
    if (u == null) return 'No account found for that phone number or email on this device. Create an account first.';
    if (auth.authenticate(state.accounts, identifier, password) == null) {
      return 'That password is not correct. Please try again.';
    }
    state = state.copyWith(user: u, chosenRole: u.role, onboarded: true);
    _s.setBool(_kOnboarded, true);
    _s.setString(_kChosenRole, u.role.name);
    _saveUser();
    return null;
  }

  void continueAsDemo(UserRole role) {
    final u = ref.read(authRepoProvider).demoUser(role);
    state = state.copyWith(user: u, chosenRole: role, onboarded: true);
    _s.setBool(_kOnboarded, true);
    _s.setString(_kChosenRole, role.name);
    _saveUser();
  }

  /// Demo mode lets one device test both experiences.
  void switchRole(UserRole role) {
    final u = state.user;
    if (u == null) return;
    final next = u.isDemo ? ref.read(authRepoProvider).demoUser(role) : u.copyWith(role: role);
    state = state.copyWith(user: next, chosenRole: role);
    _s.setString(_kChosenRole, role.name);
    _saveUser();
  }

  void signOut() {
    state = state.copyWith(clearUser: true);
    _s.writeMap(_kUser, null);
  }

  void updateUser({String? name, String? phone, String? email, String? photoPath}) {
    final u = state.user;
    if (u == null) return;
    state = state.copyWith(user: u.copyWith(name: name, phone: phone, email: email, photoPath: photoPath));
    _saveUser();
    // Keep a worker's public profile in step with account edits.
    final w = state.myWorker;
    if (w != null && state.isWorker && !(u.isDemo)) {
      saveWorkerProfile(w.copyWith(name: name, phone: phone, email: email, photoPath: photoPath), quiet: true);
    }
    _pend('account:update');
  }

  Future<void> clearAllData() async {
    await _s.clearApp();
    await ref.read(mediaProvider).clearAll();
    state = _load();
  }

  // ---- worker profile ---------------------------------------------------------

  void saveWorkerProfile(WorkerProfile p, {bool quiet = false}) {
    final exists = state.workers.any((w) => w.id == p.id);
    final list = exists ? [for (final w in state.workers) w.id == p.id ? p : w] : [...state.workers, p];
    state = state.copyWith(workers: list);
    _saveWorkers();
    if (!quiet) _pend('profile:${p.id}');
  }

  void saveDraft(WorkerProfile p) => _s.writeMap(_kDraft, p.toJson());
  void clearDraft() => _s.writeMap(_kDraft, null);
  WorkerProfile? loadDraft(String workerId) {
    final m = _s.readMap(_kDraft);
    if (m == null) return null;
    try {
      final p = WorkerProfile.fromJson(m);
      return p.id == workerId ? p : null;
    } catch (_) {
      return null;
    }
  }

  void toggleAvailable() {
    final w = state.myWorker;
    if (w == null) return;
    saveWorkerProfile(w.copyWith(isAvailable: !w.isAvailable));
  }

  void savePortfolio(List<PortfolioItem> items) {
    final w = state.myWorker;
    if (w == null) return;
    saveWorkerProfile(w.copyWith(portfolio: items));
  }

  // ---- favourites and history -------------------------------------------------

  void toggleFavourite(String workerId) {
    final f = {...state.favourites};
    if (!f.remove(workerId)) f.add(workerId);
    state = state.copyWith(favourites: f);
    _s.setStrings(_kFavs, f.toList());
  }

  void markViewedWorker(String id) {
    final l = [id, ...state.viewedWorkers.where((e) => e != id)];
    final t = l.length > 12 ? l.sublist(0, 12) : l;
    state = state.copyWith(viewedWorkers: t);
    _s.setStrings(_kViewedW, t);
  }

  void markViewedTrade(String id) {
    final l = [id, ...state.viewedTrades.where((e) => e != id)];
    final t = l.length > 8 ? l.sublist(0, 8) : l;
    state = state.copyWith(viewedTrades: t);
    _s.setStrings(_kViewedT, t);
  }

  // ---- jobs and applications --------------------------------------------------

  String postJob(Job draft) {
    final job = Job(
      id: _id('j'),
      title: draft.title,
      tradeId: draft.tradeId,
      description: draft.description,
      province: draft.province,
      town: draft.town,
      neighbourhood: draft.neighbourhood,
      completeBy: draft.completeBy,
      urgency: draft.urgency,
      budgetMin: draft.budgetMin,
      budgetMax: draft.budgetMax,
      pricingPref: draft.pricingPref,
      photoPaths: draft.photoPaths,
      contactMethod: draft.contactMethod,
      clientId: state.myClientId,
      clientName: state.myClientName,
      postedAt: DateTime.now(),
    );
    state = state.copyWith(jobs: [job, ...state.jobs]);
    _saveJobs();
    _pend('job:${job.id}');
    _notify(UserRole.worker, NotifType.jobMatch, 'New job match', '"${job.title}" in ${job.location} may suit your trade.', route: '/job/${job.id}');
    return job.id;
  }

  void setJobStatus(String jobId, JobStatus status) {
    final j = state.job(jobId);
    if (j == null) return;
    state = state.copyWith(jobs: [for (final x in state.jobs) x.id == jobId ? x.copyWith(status: status) : x]);
    _saveJobs();
    _pend('job:$jobId:${status.name}');
    if (status == JobStatus.completed) {
      if (state.applicationsForJob(jobId).any((a) => a.status == ApplicationStatus.accepted)) {
        _notify(UserRole.worker, NotifType.applicationStatus, 'Job marked complete', '"${j.title}" was marked complete by the client.', route: '/job/$jobId');
      }
      _notify(UserRole.client, NotifType.reviewReminder, 'Leave a review', 'Your job "${j.title}" is complete. Review the worker who did it.', route: '/my-jobs');
    }
  }

  /// Returns an error message, or null on success.
  String? applyForJob(String jobId, String message) {
    final job = state.job(jobId);
    if (job == null) return 'This job could not be found.';
    if (job.status != JobStatus.open) return 'This job is no longer open for applications.';
    final mine = state.myApplication(jobId);
    if (mine != null && mine.status != ApplicationStatus.withdrawn) {
      return 'You have already applied for this job.';
    }
    final app = JobApplication(id: _id('a'), jobId: jobId, workerId: state.myWorkerId, message: message.trim(), appliedAt: DateTime.now());
    final list = [
      for (final a in state.applications)
        if (!(mine != null && a.id == mine.id)) a,
      app,
    ];
    state = state.copyWith(applications: list);
    _saveApps();
    _pend('application:${app.id}');
    final wn = state.myWorker?.name ?? 'A worker';
    _notify(UserRole.client, NotifType.application, 'New application', '$wn applied for "${job.title}".', route: '/applicants/$jobId');
    return null;
  }

  void withdrawApplication(String appId) {
    final a = state.applications.where((x) => x.id == appId).toList();
    if (a.isEmpty || a.first.status != ApplicationStatus.pending) return;
    state = state.copyWith(applications: [for (final x in state.applications) x.id == appId ? x.copyWith(status: ApplicationStatus.withdrawn) : x]);
    _saveApps();
    _pend('application:$appId:withdrawn');
  }

  void decideApplication(String appId, bool accept) {
    final matches = state.applications.where((x) => x.id == appId).toList();
    if (matches.isEmpty || matches.first.status != ApplicationStatus.pending) return;
    final app = matches.first;
    final job = state.job(app.jobId);
    if (job == null) return;
    final apps = <JobApplication>[];
    for (final x in state.applications) {
      if (x.id == appId) {
        apps.add(x.copyWith(status: accept ? ApplicationStatus.accepted : ApplicationStatus.declined));
      } else if (accept && x.jobId == app.jobId && x.status == ApplicationStatus.pending) {
        apps.add(x.copyWith(status: ApplicationStatus.declined));
      } else {
        apps.add(x);
      }
    }
    state = state.copyWith(applications: apps);
    _saveApps();
    _pend('application:$appId:${accept ? 'accepted' : 'declined'}');
    if (accept) setJobStatus(job.id, JobStatus.inProgress);
    _notify(UserRole.worker, NotifType.applicationStatus, accept ? 'Application accepted' : 'Application declined', 'Your application for "${job.title}" was ${accept ? 'accepted' : 'declined'}.', route: '/job/${job.id}');
  }

  // ---- bookings ----------------------------------------------------------------

  String createBooking(ServiceRequest r) {
    final b = Booking(
      id: _id('b'),
      workerId: r.workerId,
      clientId: state.myClientId,
      clientName: state.myClientName,
      service: r.service,
      description: r.description,
      preferredDate: r.preferredDate,
      preferredTime: r.preferredTime,
      location: r.location,
      budget: r.budget,
      notes: r.notes,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(bookings: [b, ...state.bookings]);
    _saveBookings();
    _pend('booking:${b.id}');
    _notify(UserRole.worker, NotifType.serviceRequest, 'New service request', '${b.clientName} asked for: ${b.service}.', route: '/booking/${b.id}');
    return b.id;
  }

  bool setBookingStatus(String id, BookingStatus next) {
    final b = state.booking(id);
    if (b == null) return false;
    if (!allowedBookingTransitions(b.status, state.role).contains(next)) return false;
    state = state.copyWith(bookings: [for (final x in state.bookings) x.id == id ? x.copyWith(status: next) : x]);
    _saveBookings();
    _pend('booking:$id:${next.name}');
    final other = state.isWorker ? UserRole.client : UserRole.worker;
    _notify(other, NotifType.booking, 'Booking ${next.label.toLowerCase()}', '"${b.service}" is now ${next.label.toLowerCase()}.', route: '/booking/$id');
    if (next == BookingStatus.completed) {
      _notify(UserRole.client, NotifType.reviewReminder, 'Leave a review', 'Your booking "${b.service}" is complete. Share a review.', route: '/review/$id?workerId=${b.workerId}');
    }
    return true;
  }

  // ---- messaging (local demonstration only) ------------------------------------

  /// Finds or starts the conversation between a worker and a client.
  /// Called from the client side with just a worker id, or from the worker side with the client details.
  String openConversation(String workerId, {String? clientId, String? clientName}) {
    final cid = clientId ?? state.myClientId;
    for (final c in state.conversations) {
      if (c.workerId == workerId && c.clientId == cid) return c.id;
    }
    final c = Conversation(id: _id('cv'), workerId: workerId, clientId: cid, clientName: clientName ?? state.myClientName);
    state = state.copyWith(conversations: [c, ...state.conversations]);
    _saveConvs();
    return c.id;
  }

  void sendMessage(String convId, String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    final fromWorker = state.isWorker;
    state = state.copyWith(conversations: [
      for (final c in state.conversations)
        if (c.id == convId)
          c.copyWith(
            messages: [...c.messages, Message(id: _id('m'), fromWorker: fromWorker, text: t, at: DateTime.now())],
            unreadForClient: fromWorker ? c.unreadForClient + 1 : c.unreadForClient,
            unreadForWorker: fromWorker ? c.unreadForWorker : c.unreadForWorker + 1,
          )
        else
          c
    ]);
    _saveConvs();
    _pend('message:$convId');
  }

  void markConversationRead(String convId) {
    final c = state.conversation(convId);
    if (c == null || state.unreadFor(c) == 0) return;
    state = state.copyWith(conversations: [
      for (final x in state.conversations)
        if (x.id == convId) (state.isWorker ? x.copyWith(unreadForWorker: 0) : x.copyWith(unreadForClient: 0)) else x
    ]);
    _saveConvs();
  }

  // ---- reviews ---------------------------------------------------------------

  /// Returns an error message, or null when saved.
  String? submitReview({required String contextId, required String workerId, required int rating, required String text, required List<String> tags}) {
    final ctx = state.reviewableContexts(workerId).where((c) => c.id == contextId).toList();
    if (state.alreadyReviewed(contextId)) return 'You have already reviewed this job.';
    if (ctx.isEmpty) return 'You can only review a worker after a completed job or booking with them.';
    if (rating < 1 || rating > 5) return 'Choose a star rating.';
    final r = Review(
      id: _id('r'),
      workerId: workerId,
      clientId: state.myClientId,
      clientName: state.myClientName,
      rating: rating,
      text: text.trim(),
      tags: tags,
      createdAt: DateTime.now(),
      contextId: contextId,
      contextLabel: ctx.first.label,
    );
    state = state.copyWith(reviews: [r, ...state.reviews]);
    _saveReviews();
    _pend('review:${r.id}');
    _notify(UserRole.worker, NotifType.message, 'New review', '${r.clientName} left you ${r.rating} star${r.rating == 1 ? '' : 's'}.', route: '/worker/$workerId');
    return null;
  }

  // ---- quizzes ---------------------------------------------------------------

  QuizAttempt submitQuiz(Quiz quiz, List<int> answers) {
    final w = state.myWorker;
    final wid = state.myWorkerId;
    final before = w == null ? <String>{} : state.badgesFor(w);
    final attempt = QuizAttempt(id: _id('qa'), quizId: quiz.id, workerId: wid, score: scoreQuiz(quiz, answers), total: quiz.questions.length, answers: answers, at: DateTime.now());
    state = state.copyWith(attempts: [attempt, ...state.attempts]);
    _s.writeList(_kAttempts, state.attempts.map((e) => e.toJson()).toList());
    _pend('quiz:${attempt.id}');
    final after = w == null ? <String>{} : state.badgesFor(w);
    if (after.contains(quiz.badgeId) && !before.contains(quiz.badgeId)) {
      _notify(UserRole.worker, NotifType.quiz, 'Badge earned', 'You earned the ${badgeNameOf(quiz.badgeId)} badge.', route: '/badges');
    }
    return attempt;
  }

  String badgeNameOf(String id) => badgeById(id).name;

  // ---- notifications and settings ---------------------------------------------

  void markNotificationRead(String id) {
    state = state.copyWith(notifications: [for (final n in state.notifications) n.id == id ? n.copyWith(read: true) : n]);
    _saveNotifs();
  }

  void markAllRead() {
    final role = state.role;
    state = state.copyWith(notifications: [for (final n in state.notifications) n.forRole == role ? n.copyWith(read: true) : n]);
    _saveNotifs();
  }

  void updateSettings(UserSettings s) {
    state = state.copyWith(settings: s);
    _s.writeMap(_kSettings, s.toJson());
  }
}

final appProvider = NotifierProvider<AppController, AppState>(AppController.new);
