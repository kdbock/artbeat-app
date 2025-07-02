/// AdDuration model for ad campaign length
class AdDuration {
  final int days;

  AdDuration({required this.days});

  factory AdDuration.fromMap(Map<String, dynamic> map) {
    final raw = map['days'] ?? 1;
    final intDays = raw is int ? raw : int.tryParse(raw.toString()) ?? 1;
    return AdDuration(days: intDays);
  }

  Map<String, dynamic> toMap() => {'days': days};
}
