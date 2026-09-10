class Certification {
  const Certification({
    required this.id,
    required this.userId,
    required this.title,
    required this.issuer,
    required this.fileName,
    required this.fileUrl,
    required this.fileType,
    this.issuedDate,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String issuer;
  final String fileName;
  final String fileUrl;
  final String fileType;
  final DateTime? issuedDate;
  final DateTime? createdAt;

  factory Certification.fromMap(Map<String, dynamic> map) {
    return Certification(
      id: map['id'].toString(),
      userId: map['user_id'].toString(),
      title: map['title'].toString(),
      issuer: map['issuer'].toString(),
      fileName: map['file_name'].toString(),
      fileUrl: map['file_url'].toString(),
      fileType: map['file_type'].toString(),
      issuedDate: _date(map['issued_date']),
      createdAt: _date(map['created_at']),
    );
  }

  static DateTime? _date(Object? value) {
    return value == null ? null : DateTime.tryParse(value.toString());
  }
}
