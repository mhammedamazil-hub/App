class Settings {
  Settings({
    this.themeMode = 0,
    this.accentIndex = 0,
    this.welcomeSeen = false,
  });

  factory Settings.fromJson(Map<String, dynamic> j) => Settings(
    themeMode: (j['themeMode'] is num) ? (j['themeMode'] as num).toInt() : 0,
    accentIndex: (j['accentIndex'] is num)
        ? (j['accentIndex'] as num).toInt()
        : 0,
    welcomeSeen: j['welcomeSeen'] == true,
  );

  /// 0 = system, 1 = light, 2 = dark.
  int themeMode;
  int accentIndex;
  bool welcomeSeen;

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode,
    'accentIndex': accentIndex,
    'welcomeSeen': welcomeSeen,
  };
}
