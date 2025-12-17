import 'package:flutter/foundation.dart';
import 'package:hydracat/features/qol/models/qol_domain.dart';

/// Represents a single question in the Quality of Life assessment.
///
/// Each question belongs to a domain and has 5 response options (0-4 scale)
/// plus a "Not sure" option. All text is stored as localization keys.
@immutable
class QolQuestion {
  /// Creates a QoL question.
  const QolQuestion({
    required this.id,
    required this.domain,
    required this.textKey,
    required this.responseLabelKeys,
    required this.order,
  });

  /// Unique identifier for this question (e.g., "vitality_1").
  final String id;

  /// Domain this question belongs to (from [QolDomain] constants).
  final String domain;

  /// Localization key for the question text.
  final String textKey;

  /// Map of response scores (0-4) to their localization keys.
  ///
  /// Each question has 5 response options with question-specific labels.
  /// Higher scores always indicate better quality of life (semantic scaling).
  final Map<int, String> responseLabelKeys;

  /// Display order in the questionnaire (0-13).
  final int order;

  /// All 14 questions in the QoL assessment, in display order.
  static const List<QolQuestion> all = [
    // VITALITY DOMAIN (3 questions)
    QolQuestion(
      id: 'vitality_1',
      domain: QolDomain.vitality,
      textKey: 'qolQuestionVitality1',
      responseLabelKeys: {
        0: 'qolVitality1Label0',
        1: 'qolVitality1Label1',
        2: 'qolVitality1Label2',
        3: 'qolVitality1Label3',
        4: 'qolVitality1Label4',
      },
      order: 0,
    ),
    QolQuestion(
      id: 'vitality_2',
      domain: QolDomain.vitality,
      textKey: 'qolQuestionVitality2',
      responseLabelKeys: {
        0: 'qolVitality2Label0',
        1: 'qolVitality2Label1',
        2: 'qolVitality2Label2',
        3: 'qolVitality2Label3',
        4: 'qolVitality2Label4',
      },
      order: 1,
    ),
    QolQuestion(
      id: 'vitality_3',
      domain: QolDomain.vitality,
      textKey: 'qolQuestionVitality3',
      responseLabelKeys: {
        0: 'qolVitality3Label0',
        1: 'qolVitality3Label1',
        2: 'qolVitality3Label2',
        3: 'qolVitality3Label3',
        4: 'qolVitality3Label4',
      },
      order: 2,
    ),

    // COMFORT DOMAIN (3 questions)
    QolQuestion(
      id: 'comfort_1',
      domain: QolDomain.comfort,
      textKey: 'qolQuestionComfort1',
      responseLabelKeys: {
        0: 'qolComfort1Label0',
        1: 'qolComfort1Label1',
        2: 'qolComfort1Label2',
        3: 'qolComfort1Label3',
        4: 'qolComfort1Label4',
      },
      order: 3,
    ),
    QolQuestion(
      id: 'comfort_2',
      domain: QolDomain.comfort,
      textKey: 'qolQuestionComfort2',
      responseLabelKeys: {
        0: 'qolComfort2Label0',
        1: 'qolComfort2Label1',
        2: 'qolComfort2Label2',
        3: 'qolComfort2Label3',
        4: 'qolComfort2Label4',
      },
      order: 4,
    ),
    QolQuestion(
      id: 'comfort_3',
      domain: QolDomain.comfort,
      textKey: 'qolQuestionComfort3',
      responseLabelKeys: {
        0: 'qolComfort3Label0',
        1: 'qolComfort3Label1',
        2: 'qolComfort3Label2',
        3: 'qolComfort3Label3',
        4: 'qolComfort3Label4',
      },
      order: 5,
    ),

    // EMOTIONAL DOMAIN (3 questions)
    QolQuestion(
      id: 'emotional_1',
      domain: QolDomain.emotional,
      textKey: 'qolQuestionEmotional1',
      responseLabelKeys: {
        0: 'qolEmotional1Label0',
        1: 'qolEmotional1Label1',
        2: 'qolEmotional1Label2',
        3: 'qolEmotional1Label3',
        4: 'qolEmotional1Label4',
      },
      order: 6,
    ),
    QolQuestion(
      id: 'emotional_2',
      domain: QolDomain.emotional,
      textKey: 'qolQuestionEmotional2',
      responseLabelKeys: {
        0: 'qolEmotional2Label0',
        1: 'qolEmotional2Label1',
        2: 'qolEmotional2Label2',
        3: 'qolEmotional2Label3',
        4: 'qolEmotional2Label4',
      },
      order: 7,
    ),
    QolQuestion(
      id: 'emotional_3',
      domain: QolDomain.emotional,
      textKey: 'qolQuestionEmotional3',
      responseLabelKeys: {
        0: 'qolEmotional3Label0',
        1: 'qolEmotional3Label1',
        2: 'qolEmotional3Label2',
        3: 'qolEmotional3Label3',
        4: 'qolEmotional3Label4',
      },
      order: 8,
    ),

    // APPETITE DOMAIN (3 questions)
    QolQuestion(
      id: 'appetite_1',
      domain: QolDomain.appetite,
      textKey: 'qolQuestionAppetite1',
      responseLabelKeys: {
        0: 'qolAppetite1Label0',
        1: 'qolAppetite1Label1',
        2: 'qolAppetite1Label2',
        3: 'qolAppetite1Label3',
        4: 'qolAppetite1Label4',
      },
      order: 9,
    ),
    QolQuestion(
      id: 'appetite_2',
      domain: QolDomain.appetite,
      textKey: 'qolQuestionAppetite2',
      responseLabelKeys: {
        0: 'qolAppetite2Label0',
        1: 'qolAppetite2Label1',
        2: 'qolAppetite2Label2',
        3: 'qolAppetite2Label3',
        4: 'qolAppetite2Label4',
      },
      order: 10,
    ),
    QolQuestion(
      id: 'appetite_3',
      domain: QolDomain.appetite,
      textKey: 'qolQuestionAppetite3',
      responseLabelKeys: {
        0: 'qolAppetite3Label0',
        1: 'qolAppetite3Label1',
        2: 'qolAppetite3Label2',
        3: 'qolAppetite3Label3',
        4: 'qolAppetite3Label4',
      },
      order: 11,
    ),

    // TREATMENT BURDEN DOMAIN (2 questions)
    QolQuestion(
      id: 'treatment_1',
      domain: QolDomain.treatmentBurden,
      textKey: 'qolQuestionTreatment1',
      responseLabelKeys: {
        0: 'qolTreatment1Label0',
        1: 'qolTreatment1Label1',
        2: 'qolTreatment1Label2',
        3: 'qolTreatment1Label3',
        4: 'qolTreatment1Label4',
      },
      order: 12,
    ),
    QolQuestion(
      id: 'treatment_2',
      domain: QolDomain.treatmentBurden,
      textKey: 'qolQuestionTreatment2',
      responseLabelKeys: {
        0: 'qolTreatment2Label0',
        1: 'qolTreatment2Label1',
        2: 'qolTreatment2Label2',
        3: 'qolTreatment2Label3',
        4: 'qolTreatment2Label4',
      },
      order: 13,
    ),
  ];

  /// Gets a question by its ID.
  ///
  /// Returns null if no question with the given [id] exists.
  static QolQuestion? getById(String id) {
    for (final question in all) {
      if (question.id == id) {
        return question;
      }
    }
    return null;
  }

  /// Gets all questions for a specific domain.
  ///
  /// Returns questions in display order.
  static List<QolQuestion> getByDomain(String domain) {
    return all.where((q) => q.domain == domain).toList();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QolQuestion &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          domain == other.domain &&
          textKey == other.textKey &&
          order == other.order;

  @override
  int get hashCode =>
      id.hashCode ^ domain.hashCode ^ textKey.hashCode ^ order.hashCode;

  @override
  String toString() => 'QolQuestion(id: $id, domain: $domain, order: $order)';
}
