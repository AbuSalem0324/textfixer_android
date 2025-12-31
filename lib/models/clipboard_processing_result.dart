class ClipboardProcessingResult {
  final String originalText;
  final String fixedText;
  final String userMessage;
  final String? model;
  final int? originalLength;
  final int? fixedLength;

  // Usage tracking data from v2 backend
  final Map<String, dynamic>? usageSummary;
  final Map<String, dynamic>? remainingQuota;
  final Map<String, dynamic>? limits;
  final String? subscriptionTier;

  ClipboardProcessingResult({
    required this.originalText,
    required this.fixedText,
    required this.userMessage,
    this.model,
    this.originalLength,
    this.fixedLength,
    this.usageSummary,
    this.remainingQuota,
    this.limits,
    this.subscriptionTier,
  });

  /// Check if the text was actually changed
  bool get hasChanges => originalText.trim() != fixedText.trim();

  /// Get the difference in character count
  int get characterDifference => (fixedLength ?? 0) - (originalLength ?? 0);

  /// Get a summary of changes
  String get changeSummary {
    if (!hasChanges) return 'No changes made';

    final charDiff = characterDifference;
    if (charDiff > 0) {
      return 'Text expanded by $charDiff characters';
    } else if (charDiff < 0) {
      return 'Text reduced by ${-charDiff} characters';
    } else {
      return 'Text improved (same length)';
    }
  }

  // Usage tracking helpers
  int get monthlyRequests => usageSummary?['monthly_requests'] ?? 0;
  int get monthlyCharacters => usageSummary?['monthly_characters'] ?? 0;
  int get monthlyRequestsRemaining =>
      remainingQuota?['monthly_requests_remaining'] ?? 0;
  int get monthlyCharactersRemaining =>
      remainingQuota?['monthly_characters_remaining'] ?? 0;
  // Backend sends 'monthly_requests' in limits, not 'monthly_limit'
  int get monthlyLimit => limits?['monthly_requests'] ?? 0;
  // Backend sends 'characters_per_request', not 'character_limit_per_request'
  int get characterLimitPerRequest =>
      limits?['characters_per_request'] ?? 500;

  /// Get usage summary text for display
  String get usageText {
    if (usageSummary == null || limits == null) {
      return '';
    }
    return 'Monthly: $monthlyRequests / $monthlyLimit requests';
  }

  /// Get character usage text for display
  String get characterUsageText {
    if (usageSummary == null) {
      return '';
    }
    final charCount = monthlyCharacters;
    if (charCount < 1000) {
      return '$charCount characters used this month';
    } else if (charCount < 1000000) {
      final k = (charCount / 1000).toStringAsFixed(1);
      return '${k}K characters used this month';
    } else {
      final m = (charCount / 1000000).toStringAsFixed(1);
      return '${m}M characters used this month';
    }
  }

  /// Check if approaching quota limit
  bool get isApproachingLimit {
    if (monthlyLimit == 0) return false;
    final percentUsed = (monthlyRequests / monthlyLimit) * 100;
    return percentUsed >= 80;
  }
}
