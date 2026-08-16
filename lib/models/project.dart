class Project {
  Project({
    required this.id,
    required this.name,
    this.colorIndex = 0,
    this.iconIndex = 0,
  });

  factory Project.fromJson(Map<String, dynamic> j) => Project(
    id: j['id'] as String? ?? '',
    name: j['name'] as String? ?? 'Untitled',
    colorIndex: (j['colorIndex'] is num) ? (j['colorIndex'] as num).toInt() : 0,
    iconIndex: (j['iconIndex'] is num) ? (j['iconIndex'] as num).toInt() : 0,
  );

  String id;
  String name;
  int colorIndex;
  int iconIndex;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'colorIndex': colorIndex,
    'iconIndex': iconIndex,
  };

  Project copyWith({String? name, int? colorIndex, int? iconIndex}) => Project(
    id: id,
    name: name ?? this.name,
    colorIndex: colorIndex ?? this.colorIndex,
    iconIndex: iconIndex ?? this.iconIndex,
  );
}
