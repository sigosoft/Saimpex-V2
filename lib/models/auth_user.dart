class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.mobile,
    required this.points,
    required this.isNewUser,
    this.email,
    this.image,
    this.countryCodeId,
    this.countryCode,
  });

  final int id;
  final String name;
  final String mobile;
  final String? email;
  final String? image;
  final String points;
  final int? countryCodeId;
  final String? countryCode;
  final bool isNewUser;

  factory AuthUser.fromJson(Map<String, dynamic> json, {bool? isNewUser}) {
    return AuthUser(
      id: _asInt(json['id']),
      name: _asString(json['name']),
      mobile: _asString(json['mobile']),
      email: _nullableString(json['email']),
      image: _nullableString(json['image']),
      points: _asString(json['points']),
      countryCodeId: json['country_code_id'] == null
          ? null
          : _asInt(json['country_code_id']),
      countryCode: _nullableString(json['country_code']),
      isNewUser: isNewUser ?? json['is_new_user'] == true,
    );
  }

  AuthUser copyWith({String? countryCode, String? image}) {
    return AuthUser(
      id: id,
      name: name,
      mobile: mobile,
      email: email,
      image: image ?? this.image,
      points: points,
      countryCodeId: countryCodeId,
      countryCode: countryCode ?? this.countryCode,
      isNewUser: isNewUser,
    );
  }

  /// Keeps local-only fields when a profile response omits them.
  AuthUser mergedWith(AuthUser? cached) {
    if (cached == null) return this;
    return AuthUser(
      id: id == 0 ? cached.id : id,
      name: name.isEmpty ? cached.name : name,
      mobile: mobile.isEmpty ? cached.mobile : mobile,
      email: email ?? cached.email,
      image: image ?? cached.image,
      points: points.isEmpty ? cached.points : points,
      countryCodeId: countryCodeId ?? cached.countryCodeId,
      countryCode: countryCode ?? cached.countryCode,
      isNewUser: cached.isNewUser,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mobile': mobile,
      'email': email,
      'image': image,
      'points': points,
      'country_code_id': countryCodeId,
      'country_code': countryCode,
      'is_new_user': isNewUser,
    };
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

String _asString(dynamic value) {
  if (value == null) return '';
  return value.toString();
}

String? _nullableString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}
