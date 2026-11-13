/// The light map from the Figma maps (Store Map, tracking): warm beige land,
/// white roads, no shop / hospital / bus icons.
const String lightMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#f4efe8"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8a7d74"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#f4efe8"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"visibility":"off"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"visibility":"on"},{"color":"#e4efe0"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#ffffff"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#e6dcd3"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#f7e7d4"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#d5e6ee"}]}
]
''';
