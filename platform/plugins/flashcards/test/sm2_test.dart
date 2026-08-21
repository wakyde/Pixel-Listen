import 'package:flutter_test/flutter_test.dart';
import 'package:flashcards/utils/sm2.dart';

void main() {
  final now = DateTime(2025, 1, 1);

  group('SM-2 Algorithm', () {
    test('rating 0 (forgot) resets interval', () {
      final result = Sm2Algorithm.compute(
        rating: 0,
        interval: 7,
        easeFactor: 2.5,
        reviewCount: 3,
        now: now,
      );

      expect(result.interval, 0);
      expect(result.easeFactor, closeTo(2.3, 0.01));
      expect(result.nextReviewAt, now.add(const Duration(days: 0)));
    });

    test('rating 1 (hard) reduces interval by half', () {
      final result = Sm2Algorithm.compute(
        rating: 1,
        interval: 6,
        easeFactor: 2.5,
        reviewCount: 2,
        now: now,
      );

      expect(result.interval, 3);
      expect(result.easeFactor, closeTo(2.35, 0.01));
      expect(result.nextReviewAt, now.add(const Duration(days: 3)));
    });

    test('rating 2 (good) advances interval correctly', () {
      final result = Sm2Algorithm.compute(
        rating: 2,
        interval: 1,
        easeFactor: 2.5,
        reviewCount: 0,
        now: now,
      );

      expect(result.interval, 3);
      expect(result.easeFactor, 2.5);
      expect(result.nextReviewAt, now.add(const Duration(days: 3)));
    });

    test('rating 2 on interval=0 advances to 1 day', () {
      final result = Sm2Algorithm.compute(
        rating: 2,
        interval: 0,
        easeFactor: 2.5,
        reviewCount: 0,
        now: now,
      );

      expect(result.interval, 1);
      expect(result.nextReviewAt, now.add(const Duration(days: 1)));
    });

    test('rating 2 on interval=3 advances by ease factor', () {
      final result = Sm2Algorithm.compute(
        rating: 2,
        interval: 3,
        easeFactor: 2.5,
        reviewCount: 2,
        now: now,
      );

      expect(result.interval, 7.5);
      expect(result.easeFactor, 2.5);
      expect(result.nextReviewAt, now.add(const Duration(days: 8)));
    });

    test('rating 3 (easy) boosts interval significantly', () {
      final result = Sm2Algorithm.compute(
        rating: 3,
        interval: 3,
        easeFactor: 2.5,
        reviewCount: 2,
        now: now,
      );

      expect(result.interval, closeTo(13, 0.1));
      expect(result.easeFactor, closeTo(2.65, 0.01));
      expect(result.nextReviewAt, now.add(const Duration(days: 13)));
    });

    test('rating 3 on interval=0 sets interval to 1', () {
      final result = Sm2Algorithm.compute(
        rating: 3,
        interval: 0,
        easeFactor: 2.5,
        reviewCount: 0,
        now: now,
      );

      expect(result.interval, 1);
      expect(result.easeFactor, closeTo(2.65, 0.01));
      expect(result.nextReviewAt, now.add(const Duration(days: 1)));
    });

    test('easeFactor never goes below 1.3', () {
      var result = Sm2Algorithm.compute(
        rating: 0,
        interval: 1,
        easeFactor: 1.3,
        reviewCount: 1,
        now: now,
      );

      expect(result.easeFactor, 1.3);

      result = Sm2Algorithm.compute(
        rating: 1,
        interval: 1,
        easeFactor: 1.35,
        reviewCount: 1,
        now: now,
      );

      expect(result.easeFactor, 1.3);
    });

    test('reviewCount increments', () {
      final result = Sm2Algorithm.compute(
        rating: 2,
        interval: 1,
        easeFactor: 2.5,
        reviewCount: 5,
        now: now,
      );

      expect(result.reviewCount, 6);
    });

    test('full SM-2 progression matches spec', () {
      var interval = 0.0;
      var easeFactor = 2.5;
      var reviewCount = 0;

      final result1 = Sm2Algorithm.compute(
        rating: 2,
        interval: interval,
        easeFactor: easeFactor,
        reviewCount: reviewCount,
        now: now,
      );
      expect(result1.interval, 1);
      interval = result1.interval;
      easeFactor = result1.easeFactor;
      reviewCount = result1.reviewCount;

      final result2 = Sm2Algorithm.compute(
        rating: 2,
        interval: interval,
        easeFactor: easeFactor,
        reviewCount: reviewCount,
        now: now,
      );
      expect(result2.interval, 3);
      interval = result2.interval;
      easeFactor = result2.easeFactor;
      reviewCount = result2.reviewCount;

      final result3 = Sm2Algorithm.compute(
        rating: 2,
        interval: interval,
        easeFactor: easeFactor,
        reviewCount: reviewCount,
        now: now,
      );
      expect(result3.interval, 7.5);
      interval = result3.interval;
      easeFactor = result3.easeFactor;
      reviewCount = result3.reviewCount;

      final result4 = Sm2Algorithm.compute(
        rating: 0,
        interval: interval,
        easeFactor: easeFactor,
        reviewCount: reviewCount,
        now: now,
      );
      expect(result4.interval, 0);
      expect(result4.easeFactor, closeTo(2.3, 0.01));
    });
  });
}