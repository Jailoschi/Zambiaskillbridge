import 'package:flutter_test/flutter_test.dart';
import 'package:skillbridge/core/constants/constants.dart';
import 'package:skillbridge/core/utils/format.dart';
import 'package:skillbridge/data/content/quizzes.dart';
import 'package:skillbridge/data/demo/demo_data.dart';
import 'package:skillbridge/data/repositories/repositories.dart';
import 'package:skillbridge/data/repositories/rules.dart';
import 'package:skillbridge/models/models.dart';

void main() {
  group('phone numbers', () {
    test('accepts common Zambian formats', () {
      expect(normaliseZmPhone('0977 123 456'), '977123456');
      expect(normaliseZmPhone('+260 97 123 4567'), '971234567');
      expect(normaliseZmPhone('260971234567'), '971234567');
    });
    test('rejects bad numbers', () {
      expect(normaliseZmPhone('12345'), isNull);
      expect(normaliseZmPhone('0555 123 456'), isNull);
    });
  });

  group('quiz scoring', () {
    test('every quiz has four options and a valid answer index', () {
      for (final q in kQuizzes) {
        expect(q.questions, isNotEmpty);
        for (final k in q.questions) {
          expect(k.options.length, 4);
          expect(k.correctIndex, inInclusiveRange(0, 3));
        }
      }
    });
    test('score counts only correct answers', () {
      final q = kQuizzes.first;
      expect(scoreQuiz(q, [for (final k in q.questions) k.correctIndex]), q.questions.length);
      expect(scoreQuiz(q, List.filled(q.questions.length, -1)), 0);
    });
  });

  group('badge rules', () {
    const worker = WorkerProfile(id: 'w_x', name: 'Test', years: 1);
    QuizAttempt attempt(Quiz q, int score) =>
        QuizAttempt(id: 'a$score', quizId: q.id, workerId: 'w_x', score: score, total: q.questions.length, answers: const [], at: DateTime(2026));
    test('a failing score does not award the quiz badge', () {
      final q = kQuizzes.first;
      final b = computeBadges(worker: worker, reviews: const [], attempts: [attempt(q, 0)]);
      expect(b.contains(q.badgeId), isFalse);
    });
    test('a passing score awards it', () {
      final q = kQuizzes.first;
      final b = computeBadges(worker: worker, reviews: const [], attempts: [attempt(q, q.questions.length)]);
      expect(b.contains(q.badgeId), isTrue);
    });
    test('experience badge follows declared years', () {
      final b = computeBadges(worker: worker.copyWith(), reviews: const [], attempts: const []);
      expect(b.contains('experienced_worker'), isFalse);
    });
  });

  group('booking transitions', () {
    test('worker decides on a request, client can only cancel', () {
      expect(allowedBookingTransitions(BookingStatus.requested, UserRole.worker), [BookingStatus.accepted, BookingStatus.declined]);
      expect(allowedBookingTransitions(BookingStatus.requested, UserRole.client), [BookingStatus.cancelled]);
    });
    test('finished bookings cannot change', () {
      for (final s in [BookingStatus.completed, BookingStatus.declined, BookingStatus.cancelled]) {
        expect(allowedBookingTransitions(s, UserRole.worker), isEmpty);
      }
    });
  });

  group('demo data and search', () {
    final seed = DemoSeed.build(DateTime(2026, 10, 15));
    const repo = LocalWorkerSearchRepository();
    RatingSummary rating(WorkerProfile w) => summarizeRatings(w, seed.reviews);

    test('ids are unique', () {
      expect(seed.workers.map((w) => w.id).toSet().length, seed.workers.length);
      expect(seed.jobs.map((j) => j.id).toSet().length, seed.jobs.length);
    });
    test('no seeded worker claims an official credential', () {
      expect(seed.workers.every((w) => w.externalCredentials.isEmpty), isTrue);
    });
    test('trade filter only returns that trade', () {
      final r = repo.search(seed.workers, const SearchQuery(tradeId: 'plumbing'), rating: rating);
      expect(r, isNotEmpty);
      expect(r.every((w) => w.tradeId == 'plumbing'), isTrue);
    });
    test('partial text matches names', () {
      final r = repo.search(seed.workers, const SearchQuery(text: 'mwam'), rating: rating);
      expect(r.any((w) => w.name.contains('Mwamba')), isTrue);
    });
    test('filters change the result set', () {
      final all = repo.search(seed.workers, const SearchQuery(), rating: rating);
      final strict = repo.search(seed.workers, const SearchQuery(minRating: 4.7, availableOnly: true), rating: rating);
      expect(strict.length, lessThan(all.length));
    });
    test('highest rated sort is ordered', () {
      final r = repo.search(seed.workers, const SearchQuery(sort: SortMode.highestRated), rating: rating);
      for (var i = 1; i < r.length; i++) {
        expect(rating(r[i - 1]).average >= rating(r[i]).average, isTrue);
      }
    });
  });

  test('badge thresholds are defined and below 100 percent', () {
    expect(kBadgeThreshold, inExclusiveRange(0, 1));
    expect(kBadges.map((b) => b.id).toSet().length, kBadges.length);
  });
}
