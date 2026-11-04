class CompanyDetails {
  const CompanyDetails({required this.name, required this.phone});

  final String name;
  final String phone;

  CompanyDetails copyWith({String? name, String? phone}) {
    return CompanyDetails(name: name ?? this.name, phone: phone ?? this.phone);
  }

  @override
  bool operator ==(Object other) {
    return other is CompanyDetails &&
        other.name == name &&
        other.phone == phone;
  }

  @override
  int get hashCode => Object.hash(name, phone);
}
