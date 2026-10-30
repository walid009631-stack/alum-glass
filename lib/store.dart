import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

final store = AppStore();

/// يحفظ كل شيء في الهاتف. صيغة البيانات متسامحة مع الحقول الجديدة
/// لذلك تحديث التطبيق لا يمسح القطاعات والإعدادات.
class AppStore extends ChangeNotifier {
  static const _key = 'alum_glass_data';
  static const schema = 1;

  List<ProfileSystem> systems = [];
  List<CutItem> cut = [];
  double barLength = 600; // 6 متر بالسنتيمتر
  double kerf = 0;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_key);
    if (s == null) return;
    try {
      _fromMap(jsonDecode(s));
    } catch (_) {
      await p.setString('${_key}_corrupt', s); // نحتفظ بنسخة ولا نكتب فوقها
    }
  }

  void _fromMap(dynamic m) {
    final map = m as Map;
    systems = ((map['systems'] ?? []) as List).map(ProfileSystem.fromJson).toList();
    cut = ((map['cut'] ?? []) as List).map(CutItem.fromJson).toList();
    final b = map['barLength'];
    final k = map['kerf'];
    if (b is num && b > 0) barLength = b.toDouble();
    if (k is num && k >= 0) kerf = k.toDouble();
  }

  Map<String, dynamic> toMap() => {
        'schema': schema,
        'systems': systems.map((e) => e.toJson()).toList(),
        'cut': cut.map((e) => e.toJson()).toList(),
        'barLength': barLength,
        'kerf': kerf,
      };

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(toMap()));
  }

  void changed() {
    notifyListeners();
    _save();
  }

  String newId() => DateTime.now().microsecondsSinceEpoch.toString();

  ProfileSystem addSystem(String name) {
    final s = ProfileSystem(id: newId(), name: name);
    systems.add(s);
    changed();
    return s;
  }

  void addCut(CutItem c) {
    cut.add(c);
    changed();
  }

  String exportJson() => const JsonEncoder.withIndent('  ').convert(toMap());

  bool importJson(String text) {
    try {
      _fromMap(jsonDecode(text));
      changed();
      return true;
    } catch (_) {
      return false;
    }
  }
}
