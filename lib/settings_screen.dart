import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models.dart';
import 'store.dart';
import 'widgets.dart';

Future<bool> _confirm(BuildContext c, String msg) async =>
    (await showDialog<bool>(
      context: c,
      builder: (_) => AlertDialog(
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('تأكيد')),
        ],
      ),
    )) ==
    true;

Future<String?> _askName(BuildContext c, String title, [String initial = '']) async {
  final ctl = TextEditingController(text: initial);
  final ok = await showDialog<bool>(
    context: c,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: TextField(controller: ctl, autofocus: true),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('حفظ')),
      ],
    ),
  );
  final v = ctl.text.trim();
  return ok == true && v.isNotEmpty ? v : null;
}

// ───────────────────────── قائمة القطاعات ─────────────────────────
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات القطاعات'), actions: [
        IconButton(
          tooltip: 'نسخ احتياطي / استيراد',
          icon: const Icon(Icons.backup),
          onPressed: () => _backup(context),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('قطاع جديد'),
        onPressed: () async {
          final n = await _askName(context, 'اسم القطاع');
          if (n != null) store.addSystem(n);
        },
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) => store.systems.isEmpty
            ? const Center(child: Text('لا توجد قطاعات. اضغط "قطاع جديد".'))
            : ListView(padding: const EdgeInsets.only(bottom: 90), children: [
                for (final s in store.systems)
                  ListTile(
                    title: Text(s.name),
                    subtitle: Text('${s.rulesCount} قاعدة'),
                    leading: const Icon(Icons.straighten),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'dup') {
                          final c = ProfileSystem.fromJson(s.toJson())
                            ..id = store.newId()
                            ..name = '${s.name} (نسخة)';
                          store.systems.add(c);
                          store.changed();
                        } else if (v == 'del' &&
                            await _confirm(context, 'حذف القطاع "${s.name}" وكل قواعده؟')) {
                          store.systems.remove(s);
                          store.changed();
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'dup', child: Text('تكرار')),
                        PopupMenuItem(value: 'del', child: Text('حذف')),
                      ],
                    ),
                    onTap: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => SystemScreen(sys: s))),
                  ),
              ]),
      ),
    );
  }

  void _backup(BuildContext context) {
    final ctl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('نسخ احتياطي'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('نسخ البيانات إلى الحافظة'),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: store.exportJson()));
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('تم النسخ، الصقه في ملاحظات أو واتساب')));
              }
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: ctl,
            maxLines: 4,
            decoration: const InputDecoration(
                hintText: 'الصق هنا بيانات نسخة سابقة', border: OutlineInputBorder()),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
          FilledButton(
            onPressed: () async {
              if (ctl.text.trim().isEmpty) return;
              if (!await _confirm(context, 'سيتم استبدال كل البيانات الحالية. متابعة؟')) return;
              final ok = store.importJson(ctl.text);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ok ? 'تم الاستيراد' : 'البيانات غير صالحة')));
              }
            },
            child: const Text('استيراد'),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── قطاع واحد ─────────────────────────
class SystemScreen extends StatelessWidget {
  final ProfileSystem sys;
  const SystemScreen({super.key, required this.sys});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: Text(sys.name), actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final n = await _askName(context, 'تعديل الاسم', sys.name);
              if (n != null) {
                sys.name = n;
                store.changed();
              }
            },
          ),
        ]),
        body: ListView(children: [
          for (final k in templateKeys)
            ListTile(
              title: Text(templateLabels[k]!),
              subtitle: Text(
                  '${sys.templates[k]?.profiles.length ?? 0} قطعة • ${sys.templates[k]?.glass.length ?? 0} زجاج'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => TemplateScreen(sys: sys, keyName: k))),
            ),
        ]),
      ),
    );
  }
}

// ───────────────────────── قواعد نوع واحد ─────────────────────────
class TemplateScreen extends StatelessWidget {
  final ProfileSystem sys;
  final String keyName;
  const TemplateScreen({super.key, required this.sys, required this.keyName});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final t = sys.of(keyName);
        return Scaffold(
          appBar: AppBar(
            title: Text('${sys.name} • ${templateLabels[keyName]}'),
            actions: [
              PopupMenuButton<String>(
                onSelected: (_) => _copyFrom(context, t),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'copy', child: Text('نسخ القواعد من نوع آخر')),
                ],
              ),
            ],
          ),
          body: ListView(padding: const EdgeInsets.all(12), children: [
            sectionTitle('قواعد القطاعات (القطع)'),
            for (final r in t.profiles)
              Card(
                child: ListTile(
                  title: Text(r.name),
                  subtitle: Text('${r.formula.describe()}   ×   ${r.qty}'),
                  onTap: () => _editProfile(context, t, r),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      if (await _confirm(context, 'حذف "${r.name}"؟')) {
                        t.profiles.remove(r);
                        store.changed();
                      }
                    },
                  ),
                ),
              ),
            OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('إضافة قطعة'),
              onPressed: () => _editProfile(context, t, null),
            ),
            sectionTitle('قواعد الزجاج (البلور)'),
            for (final g in t.glass)
              Card(
                child: ListTile(
                  isThreeLine: true,
                  title: Text(g.name),
                  subtitle: Text(
                      'العرض: ${g.w.describe()}\nالارتفاع: ${g.h.describe()}   ×   ${g.qty}'),
                  onTap: () => _editGlass(context, t, g),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      if (await _confirm(context, 'حذف "${g.name}"؟')) {
                        t.glass.remove(g);
                        store.changed();
                      }
                    },
                  ),
                ),
              ),
            OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('إضافة زجاج'),
              onPressed: () => _editGlass(context, t, null),
            ),
            const SizedBox(height: 40),
          ]),
        );
      },
    );
  }

  Future<void> _copyFrom(BuildContext context, Template target) async {
    final src = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('نسخ القواعد من:'),
        children: [
          for (final k in templateKeys.where((k) => k != keyName))
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, k),
              child: Text(templateLabels[k]!),
            ),
        ],
      ),
    );
    if (src == null || !context.mounted) return;
    if (!target.isEmpty && !await _confirm(context, 'سيتم استبدال القواعد الحالية. متابعة؟')) return;
    final c = sys.of(src).copy();
    target.profiles = c.profiles;
    target.glass = c.glass;
    store.changed();
  }

  Future<void> _editProfile(BuildContext context, Template t, ProfileRule? r) async {
    final name = TextEditingController(text: r?.name ?? '');
    final qty = TextEditingController(text: '${r?.qty ?? 1}');
    final f = FormulaCtl(r?.formula ?? Formula());
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text(r == null ? 'إضافة قطعة' : 'تعديل قطعة'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                  controller: name,
                  decoration: const InputDecoration(
                      labelText: 'اسم القطعة', border: OutlineInputBorder())),
              f.view('الطول = (القيمة − الخصمية) ÷ القسمة + الإضافة', set),
              const SizedBox(height: 10),
              numField(qty, 'العدد'),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حفظ')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final q = (parseNum(qty.text) ?? 1).round().clamp(1, 1000);
    final n = name.text.trim().isEmpty ? 'قطعة' : name.text.trim();
    if (r == null) {
      t.profiles.add(ProfileRule(name: n, formula: f.value, qty: q));
    } else {
      r.name = n;
      r.formula = f.value;
      r.qty = q;
    }
    store.changed();
  }

  Future<void> _editGlass(BuildContext context, Template t, GlassRule? g) async {
    final name = TextEditingController(text: g?.name ?? '');
    final qty = TextEditingController(text: '${g?.qty ?? 1}');
    final fw = FormulaCtl(g?.w ?? Formula());
    final fh = FormulaCtl(g?.h ?? Formula(base: 'H'));
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text(g == null ? 'إضافة زجاج' : 'تعديل زجاج'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                  controller: name,
                  decoration: const InputDecoration(
                      labelText: 'الاسم', border: OutlineInputBorder())),
              fw.view('عرض الزجاج', set),
              fh.view('ارتفاع الزجاج', set),
              const SizedBox(height: 10),
              numField(qty, 'العدد'),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حفظ')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final q = (parseNum(qty.text) ?? 1).round().clamp(1, 1000);
    final n = name.text.trim().isEmpty ? 'زجاج' : name.text.trim();
    if (g == null) {
      t.glass.add(GlassRule(name: n, w: fw.value, h: fh.value, qty: q));
    } else {
      g.name = n;
      g.w = fw.value;
      g.h = fh.value;
      g.qty = q;
    }
    store.changed();
  }
}
