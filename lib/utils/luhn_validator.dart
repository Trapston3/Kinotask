/// Luhn algorithm validator for credit/debit card numbers.
class LuhnValidator {
  LuhnValidator._();

  /// Returns `true` if [number] is a valid card number (15–16 digits)
  /// that passes the Luhn checksum.
  static bool validate(String number) {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 15 || digits.length > 16) return false;

    var sum = 0;
    var alternate = false;

    for (var i = digits.length - 1; i >= 0; i--) {
      var d = int.parse(digits[i]);
      if (alternate) {
        d *= 2;
        if (d > 9) d -= 9;
      }
      sum += d;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }

  /// Extract potential card numbers from OCR text.
  static List<String> extractCandidates(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^0-9\s]'), '');
    final matches =
        RegExp(r'(?:\d[\s]*){15,16}').allMatches(cleaned);
    return matches
        .map((m) => m.group(0)!.replaceAll(' ', ''))
        .where((n) => n.length >= 15 && n.length <= 16)
        .toList();
  }
}
