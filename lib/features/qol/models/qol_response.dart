import 'package:flutter/foundation.dart';

/// Represents a user's response to a single QoL question.
///
/// Each response contains a question ID and an optional score.
/// A null score indicates "Not sure" / unable to observe.
@immutable
class QolResponse {
  /// Creates a QoL response.
  const QolResponse({
    required this.questionId,
    this.score,
  });

  /// Creates a QoL response from JSON.
  factory QolResponse.fromJson(Map<String, dynamic> json) {
    return QolResponse(
      questionId: json['questionId'] as String,
      score: json['score'] as int?,
    );
  }

  /// The ID of the question this response answers.
  final String questionId;

  /// The score (0-4) or null for "Not sure".
  ///
  /// - null: Not sure / Unable to observe
  /// - 0: Lowest quality of life indicator for this question
  /// - 4: Highest quality of life indicator for this question
  ///
  /// All questions use semantic scaling where higher = better QoL.
  final int? score;

  /// Whether this response has been answered (score is not null).
  bool get isAnswered => score != null;

  /// Converts this response to JSON for Firestore storage.
  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'score': score,
    };
  }

  /// Creates a copy of this response with updated fields.
  QolResponse copyWith({
    String? questionId,
    int? score,
  }) {
    return QolResponse(
      questionId: questionId ?? this.questionId,
      score: score ?? this.score,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QolResponse &&
          runtimeType == other.runtimeType &&
          questionId == other.questionId &&
          score == other.score;

  @override
  int get hashCode => questionId.hashCode ^ score.hashCode;

  @override
  String toString() => 'QolResponse('
      'questionId: $questionId, '
      'score: $score, '
      'isAnswered: $isAnswered'
      ')';
}
