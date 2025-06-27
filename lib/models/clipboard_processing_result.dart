class ClipboardProcessingResult {
  final String originalText;
  final String fixedText;
  final String userMessage;
  final String? model;
  final int? originalLength;
  final int? fixedLength;

  ClipboardProcessingResult({
    required this.originalText,
    required this.fixedText,
    required this.userMessage,
    this.model,
    this.originalLength,
    this.fixedLength,
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
}
