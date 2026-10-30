import 'package:flutter/material.dart';
import 'cutting.dart';
import 'models.dart';
import 'store.dart';
import 'widgets.dart';

class CuttingScreen extends StatefulWidget {
  const CuttingScreen({super.key});
  @override
  State<CuttingScreen> createState() => _CuttingScreenState();
}

class _CuttingScreenState extends State<CuttingScreen> {
  final barC = TextEditingController(text: fmt(store.barLength));
  final kerfC = TextEditingController(text: fmt(store.kerf));
  final lenC = TextEditingController();
  final qtyC = TextEditingController(text: '1');
  final lblC = TextEditingController();
  CutResult? result;

  @override
  void dispose() {
    for (final c in [barC, kerfC, lenC, qtyC, lblC]) {
      c.dispose();
    }
    super.dispose();
  }

  void _add() {
    final l = parseNum(lenC.text);
    final q = int.tryParse((parseNum(qtyC.text) ?? 1).round().toString()) ?? 1;
    if (l == null || l <= 0 || q <= 0) return;
    store.addCut(CutItem(label: lblC.text.trim(), length: l, qty: q));
    lenC.clear();
    qtyC.text = '1';
    lblC.clear();
    setState(() => result = null);
  }

  void _calc() {
    final bar = parseNum(barC.text) ?? 0;
    if (bar <= 0) return;
    store.barLength = bar;
    store.kerf = parseNum(kerfC.text) ?? 0;
    store.changed();
    final all = <double>[];
    for (final c in store.cut) {
      for (var i = 0; i < c.qty; i++) {
        all.add(c.length);
      }
    }
    setState(() => result = optimize(all, store.barLength, store.kerf));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تقطيع القطاعات'), actions: [
        IconButton(
          tooltip: 'مسح القائمة',
          icon: const Icon(Icons.delete_sweep),
          onPressed: () {
            store.cut.clear();
            store.changed();
            setState(() => result = null);
          },
        ),
      ]),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) => ListView(padding: const EdgeInsets.all(14), children: [
          Row(children: [
            Expanded(child: numField(barC, 'طول العود (6 م = 600 سم)')),
            const SizedBox(width: 8),
            Expanded(child: numField(kerfC, 'سماكة المنشار')),
          ]),
          sectionTitle('إضافة قطعة'),
          TextField(
              controller: lblC,
              decoration: const InputDecoration(
                  labelText: 'الاسم (اختياري)', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(flex: 3, child: numField(lenC, 'الطول المطلوب')),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: numField(qtyC, 'الكمية')),
            IconButton.filled(onPressed: _add, icon: const Icon(Icons.add)),
          ]),
          sectionTitle('القطع المطلوبة (${store.cut.length})'),
          for (var i = 0; i < store.cut.length; i++)
            Card(
              child: ListTile(
                dense: true,
                title: Text('${fmt(store.cut[i].length)}  ×  ${store.cut[i].qty}',
                    textDirection: TextDirection.ltr, textAlign: TextAlign.right),
                subtitle: store.cut[i].label.isEmpty ? null : Text(store.cut[i].label),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    store.cut.removeAt(i);
                    store.changed();
                    setState(() => result = null);
                  },
                ),
              ),
            ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: store.cut.isEmpty ? null : _calc,
            icon: const Icon(Icons.calculate),
            label: const Text('احسب التقطيع'),
          ),
          if (result != null) ..._resultView(result!),
        ]),
      ),
    );
  }

  List<Widget> _resultView(CutResult r) {
    final bar = store.barLength;
    final totalWaste = r.bars.fold<double>(0, (a, b) => a + b.waste(bar));
    final pct = r.bars.isEmpty ? 0 : totalWaste / (r.bars.length * bar) * 100;
    final groups = <String, (Bar, int)>{};
    for (final b in r.bars) {
      final sig = b.pieces.map(fmt).join('+');
      final g = groups[sig];
      groups[sig] = (b, (g?.$2 ?? 0) + 1);
    }
    return [
      sectionTitle('النتيجة'),
      if (r.tooLong.isNotEmpty)
        Card(
          color: Colors.red.shade50,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
                'قطع أطول من العود ولم تُحسب: ${r.tooLong.map(fmt).join(" ، ")}',
                style: const TextStyle(color: Colors.red)),
          ),
        ),
      Card(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('عدد الأعواد المطلوبة: ${r.bars.length}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('إجمالي الهدر: ${fmt(totalWaste)}  (${pct.toStringAsFixed(1)}%)'),
          ]),
        ),
      ),
      for (final e in groups.entries)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${e.value.$2} × عود:   ${e.key.replaceAll("+", "  +  ")}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _barView(e.value.$1, bar),
              const SizedBox(height: 4),
              Text('الهدر في العود: ${fmt(e.value.$1.waste(bar))}'),
            ]),
          ),
        ),
    ];
  }

  Widget _barView(Bar b, double barLen) {
    final waste = b.waste(barLen);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        height: 30,
        child: Row(children: [
          for (final p in b.pieces)
            Expanded(
              flex: (p * 1000).round().clamp(1, 1 << 30),
              child: Container(
                margin: const EdgeInsets.only(right: 1),
                color: Colors.primaries[(p * 10).round() % Colors.primaries.length].shade300,
                alignment: Alignment.center,
                child: FittedBox(child: Text(fmt(p), style: const TextStyle(fontSize: 11))),
              ),
            ),
          if (waste > 1e-9)
            Expanded(
              flex: (waste * 1000).round().clamp(1, 1 << 30),
              child: Container(color: Colors.grey.shade400),
            ),
        ]),
      ),
    );
  }
}
