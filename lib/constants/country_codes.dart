class AppCountry {
  const AppCountry({
    required this.name,
    required this.code,
    required this.flag,
  });

  final String name;
  final String code;
  final String flag;
}

const List<AppCountry> appCountries = [
  AppCountry(name: 'Mauritania', code: '+222', flag: '🇲🇷'),
  AppCountry(name: 'India', code: '+91', flag: '🇮🇳'),
  AppCountry(name: 'United Arab Emirates', code: '+971', flag: '🇦🇪'),
  AppCountry(name: 'Saudi Arabia', code: '+966', flag: '🇸🇦'),
  AppCountry(name: 'United States', code: '+1', flag: '🇺🇸'),
  AppCountry(name: 'United Kingdom', code: '+44', flag: '🇬🇧'),
];

String flagForCountryCode(String code) {
  for (final country in appCountries) {
    if (country.code == code) return country.flag;
  }
  return '🌐';
}
