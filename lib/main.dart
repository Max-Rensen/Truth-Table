import "dart:math";
import "package:flutter/services.dart";
import "package:flutter/material.dart";

const EMPTY = "\u{25A1}";
const VALUES = [
  "\u{2227}", //AND
  "\u{22BC}", //NAND
  "\u{2228}", //OR
  "\u{22BB}", //XOR
  "\u{22BD}", //NOR
  "\u{AC}",   //NOT
  "\u{2192}", //CONDITIONAL
  "\u{2194}", //BICONDITIONAL
];

class TTS extends State<StatefulWidget> {
  final _con = TextEditingController();
  int _select = 1;
  String _prev = "a";

  Widget _buildScaffold(String s, Widget b, [List<Widget> a]) => Scaffold(appBar: AppBar(title: Text(s), actions: a), body: b);
  Text _buildText(String s) => Text(s, textAlign: TextAlign.center);
  Widget _buildButton(Widget b) => ButtonTheme(child: b, minWidth: 50, buttonColor: Colors.white);

  Widget _buildPage() {
    var buttons = VALUES.map((x) => _buildButton(RaisedButton(child: Text(x), onPressed: () => _applyValue(x)))).toList();

    var getButtons = (b, e) => buttons.getRange(b, e).toList();
    var buildRow = (c) => Row(children: c, mainAxisAlignment: MainAxisAlignment.center);
    var buildArrow = (s, n) => RaisedButton(child: Text(s), onPressed: () => _applySelect(n));
    int half = buttons.length ~/ 2;

    var field = TextField(
      textAlign: TextAlign.center,
      autocorrect: false, autofocus: true,
      controller: _con, cursorWidth: 0,
      enableInteractiveSelection: false,
      onChanged: (s) { 
        if (s.length != _prev.length) {
          _con.text = _prev; 
          _applySelect(0); 
        }
      },
    );

    return Container(
      child: Column(children: [
        Row(children: [
          Flexible(child: field),
          IconButton(
            icon: Icon(Icons.clear), tooltip: "Clear",
            onPressed: () { _con.clear(); _select = 1; _prev = "a"; }
          )
        ]),
        buildRow([_buildButton(buildArrow('<', -1)), _buildButton(buildArrow('>', 1))]),
        buildRow(getButtons(0, half)), buildRow(getButtons(half, buttons.length))
      ]
    ));
  }

  Table _buildTable() {
    var elems = _con.text.runes
      .where((c) => !VALUES.contains(String.fromCharCode(c)) &&
        c != 40 && c != 41 && c != 32)
      .toSet()
      .toList();

    var props = elems.map((i) => _buildText(String.fromCharCode(i))).toList();
    props.add(_buildText(_con.text));

    var rows = [TableRow(children: props, decoration: BoxDecoration(color: Color(0xFFD0D0D0)))];

    int l = elems.length;
    for (int i = 0; i < pow(2, l); i++) {
      var bin = i.toRadixString(2).padLeft(l, '0');
      var vals = List.generate(l, (j) => _buildText("${bin[j]}"));

      vals.add(_eval(bin, props.sublist(0, l)));
      rows.add(TableRow(children: vals));
    }

    return Table(children: rows, border: TableBorder.all(), defaultColumnWidth: IntrinsicColumnWidth());
  }

  Text _eval(String bin, List<Text> elems) {
    var s = _con.text.replaceAll(' ', '');
    elems.forEach((e) => s = s.replaceAll(e.data, bin[elems.indexOf(e)]));

    var toBool = (s) => s == '0' ? false : true;
    var check = (i, f) => f(toBool(s[i-1]), toBool(s[i+1]));
    var isBin = (s) => s == '0' || s == '1';

    var simplify = (i) { switch (VALUES.indexOf(s[i])) {
      case 0: return check(i, (a,b) => a && b);
      case 1: return check(i, (a,b) => !(a && b));
      case 2: return check(i, (a,b) => a || b);
      case 3: return check(i, (a,b) => (a || b) && !(a && b));
      case 4: return check(i, (a,b) => !a && !b);
      case 5: return !toBool(s[i+1]);
      case 6: return check(i, (a,b) => !a || b);
      case 7: return check(i, (a,b) => (!a || b) && (a || !b));  
    }};

    while (s.length > 1)
      for (int i = 1; i < s.length-1; i++)
        if (VALUES.contains(s[i]) && ((isBin(s[i-1]) && isBin(s[i+1]))) || (s[i] == VALUES[5] && isBin(s[i+1]))) {
          s = s.substring(0, i-(s[i] == VALUES[5] ? 1 : 2)) + (simplify(i) ? '1' : '0') + s.substring(i+3, s.length);
          break;
        }

    return _buildText(s);
  }

  void _applySelect(int n) {
    var old = _select, s = _con.text, c = 0;
    _prev = s;
    _select += n;

    for (int i = 0; i < s.length; i++)
      if (s[i] != ' ' && s[i] != '(' && s[i] != ')' && ((i > 1 && VALUES.contains(s[i-2])) || (i < s.length-2 && VALUES.contains(s[i+2]))))
        if (++c == _select) _con.selection = TextSelection(baseOffset: i, extentOffset: i+1);

    if (c == 0) _select = old;
  }

  void _applyValue(String v) {
    var t = _con.text;
    var s = _con.selection.start;
    var e = "(${v == VALUES[5] ? '' : EMPTY + ' '}$v $EMPTY)";
    _con.text = t.length > 0 ? t.substring(0, s) + e + t.substring(s+1, t.length) : e;
    _applySelect(0);
  }

  void _showTable() {
    Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext c) =>
      _buildScaffold("Truth Table", ListView(children: [_buildTable()]))
    ));
  }

  Widget build(BuildContext c) => 
    _buildScaffold("Boolean Algebra", _buildPage(), [
      IconButton(
        icon: Icon(Icons.table_chart),
        tooltip: "Generate truth table",
        onPressed: _showTable
      )
    ]);
}

class TT extends StatefulWidget {
  TTS createState() => TTS();
}

void main() => runApp(MaterialApp(title: "Boolean Algebra", home: TT()));