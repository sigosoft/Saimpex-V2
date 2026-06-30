class LoginModel {
  final String name;
  final String whatsappNumber;
  final String countryCode;

  LoginModel({
    required this.name,
    required this.whatsappNumber,
    required this.countryCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'whatsappNumber': whatsappNumber,
      'countryCode': countryCode,
      'fullNumber': '$countryCode$whatsappNumber',
    };
  }
}
