class Payslip {
  const Payslip({
    required this.id,
    required this.month,
    required this.year,
    required this.publishedAt,
  });

  factory Payslip.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final month = json['month'];
    final year = json['year'];
    final published = json['published_at'];
    if (id is! String ||
        !RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(id) ||
        month is! int ||
        month < 1 ||
        month > 12 ||
        year is! int ||
        year < 1 ||
        year > 9999 ||
        published is! String) {
      throw const FormatException('Invalid payslip.');
    }
    final publishedAt = DateTime.tryParse(published);
    if (publishedAt == null) {
      throw const FormatException('Invalid payslip publication date.');
    }
    return Payslip(id: id, month: month, year: year, publishedAt: publishedAt);
  }

  final String id;
  final int month;
  final int year;
  final DateTime publishedAt;
}

class PayslipCollection {
  const PayslipCollection({required this.total, required this.payslips});

  factory PayslipCollection.fromJson(Map<String, dynamic> json) {
    final total = json['total'];
    final payslips = json['payslips'];
    if (total is! int || total < 0 || payslips is! List) {
      throw const FormatException('Invalid payslip list.');
    }
    return PayslipCollection(
      total: total,
      payslips: payslips.map((value) {
        if (value is! Map<String, dynamic>) {
          throw const FormatException('Invalid payslip.');
        }
        return Payslip.fromJson(value);
      }).toList(),
    );
  }

  final int total;
  final List<Payslip> payslips;
}
