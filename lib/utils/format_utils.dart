class FormatUtils {
  /// Format currency with rupee symbol and proper formatting
  /// Handles large numbers with K, L, Cr suffixes when compact is true
  static String formatCurrency(double value, {bool compact = false}) {
    final absValue = value.abs();

    if (compact && absValue >= 10000000) {
      // 1 Crore and above -> show in Crores
      return '₹${(absValue / 10000000).toStringAsFixed(1)}Cr';
    } else if (compact && absValue >= 100000) {
      // 1 Lakh and above -> show in Lakhs
      return '₹${(absValue / 100000).toStringAsFixed(1)}L';
    } else if (compact && absValue >= 10000) {
      // 10,000 and above -> show in K
      return '₹${(absValue / 1000).toStringAsFixed(1)}K';
    } else {
      // Below 10,000 or not compact -> show full amount with proper formatting
      return formatCurrencyFull(absValue);
    }
  }

  /// Format currency without compact notation (always show full amount)
  /// Shows decimals only if they exist
  static String formatCurrencyFull(double value) {
    final absValue = value.abs();
    // Check if value has decimals
    if (absValue == absValue.roundToDouble()) {
      // No decimals, show as integer with Indian formatting
      return '₹${formatIndianNumber(absValue)}';
    } else {
      // Has decimals, show up to 2 decimal places
      final formatted = absValue.toStringAsFixed(2);
      // Remove trailing zeros after decimal
      final cleaned = formatted.replaceAll(RegExp(r'\\.?0+$'), '');
      return '₹$cleaned';
    }
  }

  /// Format large numbers with Indian numbering system
  static String formatIndianNumber(double value) {
    final rounded = value.roundToDouble().toInt();
    final str = rounded.toString();
    
    if (str.length <= 3) return str;
    
    final lastThree = str.substring(str.length - 3);
    final remaining = str.substring(0, str.length - 3);
    
    final buffer = StringBuffer();
    var count = 0;
    
    for (var i = remaining.length - 1; i >= 0; i--) {
      if (count == 2) {
        buffer.write(',');
        count = 0;
      }
      buffer.write(remaining[i]);
      count++;
    }
    
    return '${buffer.toString().split('').reversed.join()},$lastThree';
  }
}
