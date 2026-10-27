import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillbridge/data/content/quizzes.dart';
import 'package:skillbridge/data/local/local_store.dart';
import 'package:skillbridge/models/models.dart';
import 'package:skillbridge/state/app_state.dart';

Future<ProviderContainer> _container(SharedPreferences prefs) async {
  final c = ProviderContainer(overrides: [storeProvider.overrideWithValue(LocalStore(prefs))]);
  addTearDown(c.dispose);
  return c;
}

Job _draft() => Job(id: 'draft', title: 'Fix leaking kitchen tap', tradeId: 'plumbing', description: 'The kitchen tap drips all night and needs a new washer.', clientId: '', clientName: '', postedAt: DateTime.now());

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('seeding happens once and does not duplicate on the next launch', () async {
    final prefs = await SharedPreferences.getInstance();
    final first = await _container(prefs);
    final n = first.read(appProvider).workers.length;
    expect(n, greaterThan(5));
    final second = await _container(prefs);
    expect(second.read(appProvider).workers.length, n);
  });

  test('job to application to review flow works and blocks duplicates', () async {
    final prefs = await SharedPreferences.getInstance();
    final c = await _container(prefs);
    final ctl = c.read(appProvider.notifier);

    ctl.continueAsDemo(UserRole.client);
    final jobId = ctl.postJob(_draft());
    expect(c.read(appProvider).job(jobId), isNotNull);

    ctl.switchRole(UserRole.worker);
    expect(ctl.applyForJob(jobId, 'I can come tomorrow.'), isNull);
    expect(ctl.applyForJob(jobId, 'Again'), isNotNull, reason: 'duplicate application must be refused');

    ctl.switchRole(UserRole.client);
    final app = c.read(appProvider).applicationsForJob(jobId).single;
    ctl.decideApplication(app.id, true);
    expect(c.read(appProvider).job(jobId)!.status, JobStatus.inProgress);

    final workerId = app.workerId;
    expect(c.read(appProvider).reviewableContexts(workerId).any((x) => x.id == jobId), isFalse, reason: 'job is not completed yet');
    expect(ctl.submitReview(contextId: jobId, workerId: workerId, rating: 5, text: 'Great', tags: const []), isNotNull);

    ctl.setJobStatus(jobId, JobStatus.completed);
    final before = c.read(appProvider).ratingFor(c.read(appProvider).worker(workerId)!).count;
    expect(ctl.submitReview(contextId: jobId, workerId: workerId, rating: 5, text: 'Great work', tags: const ['On time']), isNull);
    final after = c.read(appProvider).ratingFor(c.read(appProvider).worker(workerId)!).count;
    expect(after, before + 1);
    expect(ctl.submitReview(contextId: jobId, workerId: workerId, rating: 4, text: 'Twice', tags: const []), isNotNull, reason: 'second review must be refused');
  });

  test('a passing quiz attempt is stored and counts towards badges', () async {
    final prefs = await SharedPreferences.getInstance();
    final c = await _container(prefs);
    final ctl = c.read(appProvider.notifier);
    ctl.continueAsDemo(UserRole.worker);
    final quiz = kQuizzes.first;
    ctl.submitQuiz(quiz, [for (final q in quiz.questions) q.correctIndex]);
    final s = c.read(appProvider);
    expect(s.attempts.length, 1);
    expect(s.badgesFor(s.myWorker!), contains(quiz.badgeId));
  });

  test('favourites, settings and messages persist across launches', () async {
    final prefs = await SharedPreferences.getInstance();
    final c = await _container(prefs);
    final ctl = c.read(appProvider.notifier);
    ctl.continueAsDemo(UserRole.client);
    ctl.toggleFavourite('w_david');
    ctl.updateSettings(const UserSettings(notifyMessages: false));
    final convId = ctl.openConversation('w_david');
    ctl.sendMessage(convId, 'Hello David');

    final again = await _container(prefs);
    final s = again.read(appProvider);
    expect(s.favourites, contains('w_david'));
    expect(s.settings.notifyMessages, isFalse);
    expect(s.conversation(convId)!.messages.last.text, 'Hello David');
    expect(s.user, isNotNull);
  });

  test('register rejects duplicates and sign in checks the password', () async {
    final prefs = await SharedPreferences.getInstance();
    final c = await _container(prefs);
    final ctl = c.read(appProvider.notifier);
    ctl.chooseRole(UserRole.client);
    expect(ctl.register(name: 'Test User', phone: '+260971234567', password: 'password123'), isNull);
    ctl.signOut();
    expect(ctl.register(name: 'Other', phone: '+260971234567', password: 'password123'), isNotNull);
    expect(ctl.signIn('0971234567', 'wrong-password'), isNotNull);
    expect(ctl.signIn('0971234567', 'password123'), isNull);
    expect(ctl.signIn('0961111111', 'password123'), isNotNull);
  });

  test('passwords are stored as salted hashes, never in plain text', () async {
    final prefs = await SharedPreferences.getInstance();
    final c = await _container(prefs);
    final ctl = c.read(appProvider.notifier);
    ctl.chooseRole(UserRole.worker);
    expect(ctl.register(name: 'Test User', phone: '+260971234567', password: 'secret123'), isNull);
    final account = c.read(appProvider).accounts.single;
    expect(account.passwordHash, isNotEmpty);
    expect(account.passwordHash.contains('secret123'), isFalse);
    expect(prefs.getString('sb.accounts'), isNot(contains('secret123')));
  });

  test('clearing app data resets to seed data and signs the user out', () async {
    final prefs = await SharedPreferences.getInstance();
    final c = await _container(prefs);
    final ctl = c.read(appProvider.notifier);
    ctl.continueAsDemo(UserRole.client);
    final seededCount = c.read(appProvider).jobs.length;
    final id = ctl.postJob(_draft());
    expect(c.read(appProvider).jobs.length, seededCount + 1);
    await ctl.clearAllData();
    final s = c.read(appProvider);
    expect(s.user, isNull);
    expect(s.job(id), isNull);
    expect(s.jobs.length, seededCount);
  });
}
