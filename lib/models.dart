const templateKeys = ['w1', 'w2', 'w3', 'w4', 'door', 'side'];
const templateLabels = <String, String>{
  'w1': 'شباك - درفة واحدة',
  'w2': 'شباك - درفتان',
  'w3': 'شباك - 3 درف',
  'w4': 'شباك - 4 درف',
  'door': 'الباب',
  'side': 'الطرف',
};

String fmt(double v) {
  var s = v.toStringAsFixed(2);
  if (s.contains('.')) {
    s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }
  return s == '-0' ? '0' : s;
}

double? parseNum(String t) {
  const ar = '٠١٢٣٤٥٦٧٨٩';
  var s = t.trim();
  for (var i = 0; i < 10; i++) {
    s = s.replaceAll(ar[i], '$i');
  }
  s = s.replaceAll('٫', '.').replaceAll(',', '.').replaceAll('٬', '');
  return double.tryParse(s);
}

double _d(dynamic v, double def) =>
    v is num ? v.toDouble() : (double.tryParse('$v') ?? def);
int _i(dynamic v, int def) => v is num ? v.toInt() : (int.tryParse('$v') ?? def);

/// نتيجة = (العرض أو الارتفاع − الخصمية) ÷ القسمة + الإضافة
class Formula {
  String base; // 'W' أو 'H'
  double deduction;
  double divisor;
  double add;
  Formula({this.base = 'W', this.deduction = 0, this.divisor = 1, this.add = 0});

  double calc(double w, double h) {
    final v = base == 'W' ? w : h;
    final d = divisor == 0 ? 1 : divisor;
    return (v - deduction) / d + add;
  }

  String describe() {
    var s = base == 'W' ? 'العرض' : 'الارتفاع';
    if (deduction != 0) s = '$s − ${fmt(deduction)}';
    if (divisor != 1) s = '($s) ÷ ${fmt(divisor)}';
    if (add != 0) s = '$s + ${fmt(add)}';
    return s;
  }

  Map<String, dynamic> toJson() =>
      {'base': base, 'deduction': deduction, 'divisor': divisor, 'add': add};

  factory Formula.fromJson(dynamic j) {
    if (j is! Map) return Formula();
    return Formula(
      base: j['base'] == 'H' ? 'H' : 'W',
      deduction: _d(j['deduction'], 0),
      divisor: _d(j['divisor'], 1),
      add: _d(j['add'], 0),
    );
  }
}

class ProfileRule {
  String name;
  Formula formula;
  int qty;
  ProfileRule({required this.name, required this.formula, this.qty = 1});

  Map<String, dynamic> toJson() =>
      {'name': name, 'formula': formula.toJson(), 'qty': qty};
  factory ProfileRule.fromJson(dynamic j) => ProfileRule(
        name: '${(j as Map)['name'] ?? ''}',
        formula: Formula.fromJson(j['formula']),
        qty: _i(j['qty'], 1),
      );
}

class GlassRule {
  String name;
  Formula w;
  Formula h;
  int qty;
  GlassRule({required this.name, required this.w, required this.h, this.qty = 1});

  Map<String, dynamic> toJson() =>
      {'name': name, 'w': w.toJson(), 'h': h.toJson(), 'qty': qty};
  factory GlassRule.fromJson(dynamic j) => GlassRule(
        name: '${(j as Map)['name'] ?? ''}',
        w: Formula.fromJson(j['w']),
        h: Formula.fromJson(j['h']),
        qty: _i(j['qty'], 1),
      );
}

class Template {
  List<ProfileRule> profiles;
  List<GlassRule> glass;
  Template({List<ProfileRule>? profiles, List<GlassRule>? glass})
      : profiles = profiles ?? [],
        glass = glass ?? [];

  bool get isEmpty => profiles.isEmpty && glass.isEmpty;

  Map<String, dynamic> toJson() => {
        'profiles': profiles.map((e) => e.toJson()).toList(),
        'glass': glass.map((e) => e.toJson()).toList(),
      };
  factory Template.fromJson(dynamic j) {
    if (j is! Map) return Template();
    return Template(
      profiles: ((j['profiles'] ?? []) as List).map(ProfileRule.fromJson).toList(),
      glass: ((j['glass'] ?? []) as List).map(GlassRule.fromJson).toList(),
    );
  }
  Template copy() => Template.fromJson(toJson());
}

/// "قطاع" = نظام/سلسلة ألمنيوم، له قواعد خاصة لكل نوع (شباك 1-4 درف، باب، طرف)
class ProfileSystem {
  String id;
  String name;
  Map<String, Template> templates;
  ProfileSystem({required this.id, required this.name, Map<String, Template>? templates})
      : templates = templates ?? {};

  Template of(String key) => templates.putIfAbsent(key, () => Template());
  int get rulesCount =>
      templates.values.fold(0, (a, t) => a + t.profiles.length + t.glass.length);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'templates': templates.map((k, v) => MapEntry(k, v.toJson())),
      };
  factory ProfileSystem.fromJson(dynamic j) {
    final m = j as Map;
    final t = <String, Template>{};
    ((m['templates'] ?? {}) as Map).forEach((k, v) => t['$k'] = Template.fromJson(v));
    return ProfileSystem(id: '${m['id']}', name: '${m['name'] ?? ''}', templates: t);
  }
}

class CutItem {
  String label;
  double length;
  int qty;
  CutItem({this.label = '', required this.length, this.qty = 1});
  Map<String, dynamic> toJson() => {'label': label, 'length': length, 'qty': qty};
  factory CutItem.fromJson(dynamic j) => CutItem(
        label: '${(j as Map)['label'] ?? ''}',
        length: _d(j['length'], 0),
        qty: _i(j['qty'], 1),
      );
}
