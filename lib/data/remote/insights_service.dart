import 'api_client.dart';

/// Backed by the Node API's `/insights` endpoints instead of client-side
/// aggregation over Firestore. The heuristics (at-risk threshold, revenue
/// forecast) now live entirely server-side — see `insights.service.ts` —
/// so this stays a thin passthrough.
class InsightsService {
  final ApiClient _api;
  InsightsService({ApiClient? api}) : _api = api ?? ApiClient.instance;

  Future<AtRiskInsights> getAtRiskStudents() async {
    final response = await _api.get('/insights/at-risk-students');
    return AtRiskInsights.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<RevenueForecast> getRevenueForecast() async {
    final response = await _api.get('/insights/revenue-forecast');
    return RevenueForecast.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }
}

class AtRiskStudent {
  final String studentId;
  final String fullName;
  final double averagePercentage;

  const AtRiskStudent(
      {required this.studentId,
      required this.fullName,
      required this.averagePercentage});

  factory AtRiskStudent.fromJson(Map<String, dynamic> json) => AtRiskStudent(
        studentId: json['studentId'] as String,
        fullName: json['fullName'] as String,
        averagePercentage: (json['averagePercentage'] as num).toDouble(),
      );
}

class AtRiskInsights {
  final List<AtRiskStudent> students;
  final double academyAveragePercentage;
  final String? weakestSubject;

  const AtRiskInsights({
    required this.students,
    required this.academyAveragePercentage,
    required this.weakestSubject,
  });

  factory AtRiskInsights.fromJson(Map<String, dynamic> json) {
    final weakest = json['weakestSubject'] as Map<String, dynamic>?;
    return AtRiskInsights(
      students: (json['students'] as List<dynamic>)
          .map((s) => AtRiskStudent.fromJson(s as Map<String, dynamic>))
          .toList(),
      academyAveragePercentage:
          (json['academyAveragePercentage'] as num).toDouble(),
      weakestSubject: weakest?['subject'] as String?,
    );
  }
}

class RevenueForecast {
  final double totalPayable;
  final double totalPaid;
  final double collectionEfficiency;
  final double pendingAmount;
  final double projectedRevenue;
  final double predictedCollection;

  const RevenueForecast({
    required this.totalPayable,
    required this.totalPaid,
    required this.collectionEfficiency,
    required this.pendingAmount,
    required this.projectedRevenue,
    required this.predictedCollection,
  });

  factory RevenueForecast.fromJson(Map<String, dynamic> json) =>
      RevenueForecast(
        totalPayable: (json['totalPayable'] as num).toDouble(),
        totalPaid: (json['totalPaid'] as num).toDouble(),
        collectionEfficiency: (json['collectionEfficiency'] as num).toDouble(),
        pendingAmount: (json['pendingAmount'] as num).toDouble(),
        projectedRevenue: (json['projectedRevenue'] as num).toDouble(),
        predictedCollection: (json['predictedCollection'] as num).toDouble(),
      );
}
