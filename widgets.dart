import 'package:flutter/material.dart';
import 'models.dart';

Widget numField(TextEditingController c, String label, {void Function(String)? onChanged}) =>
    TextField(
      controller: c,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );

Widget sectionTitle(String t) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
      child: Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );

/// حقول تحرير قاعدة: (العرض أو الارتفاع − الخصمية) ÷ القسمة + الإضافة
class FormulaCtl {
  String base;
  final ded = TextEditingController();
  final div = TextEditingController();
  final add = TextEditingController();

  FormulaCtl(Formula f) : base = f.base {
    ded.text = fmt(f.deduction);
    div.text = fmt(f.divisor);
    add.text = fmt(f.add);
  }

  Formula get value {
    final d = parseNum(div.text) ?? 1;
    return Formula(
      base: base,
      deduction: parseNum(ded.text) ?? 0,
      divisor: d == 0 ? 1 : d,
      add: parseNum(add.text) ?? 0,
    );
  }

  Widget view(String title, void Function(void Function()) set) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          sectionTitle(title),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'W', label: Text('من العرض')),
              ButtonSegment(value: 'H', label: Text('من الارتفاع')),
            ],
            selected: {base},
            onSelectionChanged: (s) => set(() => base = s.first),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: numField(ded, 'الخصمية')),
            const SizedBox(width: 6),
            Expanded(child: numField(div, 'القسمة على')),
            const SizedBox(width: 6),
            Expanded(child: numField(add, 'الإضافة')),
          ]),
        ],
      );
}
