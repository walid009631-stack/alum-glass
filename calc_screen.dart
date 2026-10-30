import 'package:flutter/material.dart';
import 'models.dart';
import 'settings_screen.dart';
import 'store.dart';
import 'widgets.dart';

const _titles = {
  'window': 'قسم الشبابيك',
  'door': 'قسم الأبواب',
  'side': 'قسم الطرف',
  'glass': 'قسم البلور',
};

/// شاشة حساب مشتركة الكود ومستقلة الحالة: شبابيك / أبواب / طرف / بلور
class CalcScreen extends StatefulWidget {
  final String kind;
  const CalcScreen({super.key, required this.kind});
  @override
  State<CalcScreen> createState() => _CalcScreenState();
}

class _CalcScreenState extends State<CalcScreen> {
  String? sysId;
  int leaves = 1;
  String glassType = 'w1';
  final wC = TextEditingController();
  final hC = TextEditingController();

  @override
  void dispose() {
    wC.dispose();
    hC.dispose();
    super.dispose();
  }

  String get key => switch (widget.kind) {
        'window' => 'w$leaves',
        'glass' => glassType,
        _ => widget.kind,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[widget.kind]!)),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          if (store.systems.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('لا توجد قطاعات بعد.\nأضف قطاعاً وحدد خصمياته من الإعدادات.',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen())),
                    child: const Text('فتح إعدادات القطاعات'),
                  ),
                ]),
              ),
            );
          }
          final sys = store.systems.firstWhere((s) => s.id == sysId,
              orElse: () => store.systems.first);
          sysId = sys.id;
          final w = parseNum(wC.text), h = parseNum(hC.text);
          final t = sys.templates[key];

          return ListView(padding: const EdgeInsets.all(14), children: [
            DropdownButton<String>(
              isExpanded: true,
              value: sys.id,
              items: [
                for (final s in store.systems)
                  DropdownMenuItem(value: s.id, child: Text('القطاع: ${s.name}'))
              ],
              onChanged: (v) => setState(() => sysId = v),
            ),
            if (widget.kind == 'window') ...[
              sectionTitle('عدد الدرف'),
              SegmentedButton<int>(
                segments: [
                  for (final n in [1, 2, 3, 4])
                    ButtonSegment(value: n, label: Text('$n')),
                ],
                selected: {leaves},
                onSelectionChanged: (s) => setState(() => leaves = s.first),
              ),
            ],
            if (widget.kind == 'glass') ...[
              sectionTitle('النوع'),
              DropdownButton<String>(
                isExpanded: true,
                value: glassType,
                items: [
                  for (final k in templateKeys)
                    DropdownMenuItem(value: k, child: Text(templateLabels[k]!))
                ],
                onChanged: (v) => setState(() => glassType = v!),
              ),
            ],
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: numField(wC, 'العرض', onChanged: (_) => setState(() {}))),
              const SizedBox(width: 10),
              Expanded(child: numField(hC, 'الارتفاع', onChanged: (_) => setState(() {}))),
            ]),
            const SizedBox(height: 8),
            ..._results(sys, t, w, h),
          ]);
        },
      ),
    );
  }

  List<Widget> _results(ProfileSystem sys, Template? t, double? w, double? h) {
    if (w == null || h == null) {
      return [const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('أدخل العرض والارتفاع')))];
    }
    final showProfiles = widget.kind != 'glass';
    final hasProfiles = showProfiles && t != null && t.profiles.isNotEmpty;
    final hasGlass = t != null && t.glass.isNotEmpty;
    if (!hasProfiles && !hasGlass) {
      return [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'لا توجد قواعد محفوظة لـ "${templateLabels[key]}" في القطاع "${sys.name}".\n'
            'أضفها من: إعدادات القطاعات.',
            textAlign: TextAlign.center,
          ),
        )
      ];
    }
    final out = <Widget>[];
    if (hasProfiles) {
      out.add(sectionTitle('قياسات القطاعات'));
      for (final r in t.profiles) {
        final v = r.formula.calc(w, h);
        out.add(_tile(r.name, fmt(v), r.qty, bad: v <= 0, onAdd: v <= 0 ? null : () {
          store.addCut(CutItem(label: '${sys.name} - ${r.name}', length: v, qty: r.qty));
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('أضيفت إلى قائمة التقطيع'), duration: Duration(seconds: 1)));
        }));
      }
    }
    if (hasGlass) {
      out.add(sectionTitle('قياسات الزجاج'));
      for (final g in t.glass) {
        final gw = g.w.calc(w, h), gh = g.h.calc(w, h);
        out.add(_tile(g.name, '${fmt(gw)} × ${fmt(gh)}', g.qty, bad: gw <= 0 || gh <= 0));
      }
    }
    return out;
  }

  Widget _tile(String name, String size, int qty, {bool bad = false, VoidCallback? onAdd}) => Card(
        child: ListTile(
          title: Text(name.isEmpty ? '—' : name),
          subtitle: Text('العدد: $qty'),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(size,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: bad ? Colors.red : null)),
            if (onAdd != null)
              IconButton(
                  tooltip: 'إضافة للتقطيع',
                  icon: const Icon(Icons.playlist_add),
                  onPressed: onAdd),
          ]),
        ),
      );
}
