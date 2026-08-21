class Sm2Algorithm {
  Sm2Algorithm._();

  static Sm2Result compute({
    required int rating,
    required double interval,
    required double easeFactor,
    required int reviewCount,
    required DateTime now,
  }) {
    assert(rating >= 0 && rating <= 3, 'Rating must be 0-3');

    double newInterval;
    double newEaseFactor;
    int newReviewCount = reviewCount + 1;

    switch (rating) {
      case 0:
        newInterval = 0;
        newEaseFactor = _clampMin(easeFactor - 0.2, 1.3);
        break;
      case 1:
        newInterval = _clampMin(interval * 0.5, 1);
        newEaseFactor = _clampMin(easeFactor - 0.15, 1.3);
        break;
      case 2:
        if (interval == 0) {
          newInterval = 1;
        } else if (interval == 1) {
          newInterval = 3;
        } else {
          newInterval = interval * easeFactor;
        }
        newEaseFactor = easeFactor;
        break;
      case 3:
        if (interval == 0) {
          newInterval = 1;
        } else {
          newInterval = (interval + 1) * easeFactor * 1.3;
        }
        newEaseFactor = easeFactor + 0.15;
        break;
      default:
        throw ArgumentError('Invalid rating: $rating');
    }

    final nextReviewAt = now.add(Duration(days: newInterval.round()));

    return Sm2Result(
      interval: newInterval,
      easeFactor: newEaseFactor,
      reviewCount: newReviewCount,
      nextReviewAt: nextReviewAt,
    );
  }

  static double _clampMin(double value, double min) {
    return value < min ? min : value;
  }
}

class Sm2Result {
  final double interval;
  final double easeFactor;
  final int reviewCount;
  final DateTime nextReviewAt;

  const Sm2Result({
    required this.interval,
    required this.easeFactor,
    required this.reviewCount,
    required this.nextReviewAt,
  });
}