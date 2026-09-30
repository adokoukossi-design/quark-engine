import 'package:dart_style/dart_style.dart';
import 'models.dart';

class QuarkTranspiler {
  final DartFormatter _formatter = DartFormatter(
    languageVersion: DartFormatter.latestShortStyleLanguageVersion,
  );

  String transpile(QuarkSpec spec) {
    final buffer = StringBuffer();

    // 1. Imports
    buffer.writeln("import 'package:flutter/material.dart';");
    buffer.writeln();

    // 2. Class declaration
    buffer.writeln('class ${spec.widgetName} extends StatelessWidget {');

    // 3. Properties (final fields)
    for (final prop in spec.props) {
      buffer.writeln('  final ${prop.dartType} ${prop.name};');
    }
    if (spec.props.isNotEmpty) {
      buffer.writeln();
    }

    // 4. Constructor
    buffer.write('  const ${spec.widgetName}({super.key');
    for (final prop in spec.props) {
      buffer.write(', required this.${prop.name}');
    }
    buffer.writeln('});');
    buffer.writeln();

    // 5. build method
    buffer.writeln('  @override');
    buffer.writeln('  Widget build(BuildContext context) {');
    buffer.write('    return ');
    _transpileNode(spec.rootUi, buffer, 4);
    buffer.writeln(';');
    buffer.writeln('  }');
    buffer.writeln('}');

    final rawCode = buffer.toString();
    try {
      return _formatter.format(rawCode);
    } catch (_) {
      // If formatting fails for some reason, return raw code
      return rawCode;
    }
  }

  void _transpileNode(QuarkNode node, StringBuffer buffer, int indentLevel) {
    final indent = ' ' * indentLevel;
    final childIndent = ' ' * (indentLevel + 2);

    switch (node.type.toLowerCase()) {
      case 'card':
        buffer.writeln('Card(');
        buffer.write('${childIndent}child: ');
        if (node.children.length == 1) {
          _transpileNode(node.children.first, buffer, indentLevel + 2);
        } else if (node.children.isNotEmpty) {
          buffer.writeln('Column(');
          buffer.writeln('$childIndent  children: [');
          for (final child in node.children) {
            _transpileChildWithCondition(child, buffer, indentLevel + 4);
          }
          buffer.writeln('$childIndent  ],');
          buffer.write('$childIndent)');
        } else {
          buffer.write('const SizedBox()');
        }
        buffer.write('\n$indent)');
        break;

      case 'row':
        buffer.writeln('Row(');
        buffer.writeln('${childIndent}children: [');
        for (final child in node.children) {
          _transpileChildWithCondition(child, buffer, indentLevel + 2);
        }
        buffer.writeln('$childIndent],');
        buffer.write('$indent)');
        break;

      case 'col':
        buffer.writeln('Column(');
        buffer.writeln('${childIndent}children: [');
        for (final child in node.children) {
          _transpileChildWithCondition(child, buffer, indentLevel + 2);
        }
        buffer.writeln('$childIndent],');
        buffer.write('$indent)');
        break;

      case 'text':
        final style = node.modifiers['style'];
        final val = _resolveValue(node.value ?? "''");
        buffer.write('Text($val');
        if (style != null && style.isNotEmpty) {
          buffer.write(', style: Theme.of(context).textTheme.$style');
        }
        buffer.write(')');
        break;

      case 'avatar':
        final val = _resolveValue(node.value ?? "''");
        buffer.write('CircleAvatar(backgroundImage: NetworkImage($val))');
        break;

      case 'chip':
        final val = _resolveValue(node.value ?? "''");
        buffer.write('Chip(label: Text($val))');
        break;

      case 'button':
        final val = _resolveValue(node.value ?? "''");
        final onTap = node.modifiers['onTap'] ?? node.modifiers['onPressed'];
        final action = onTap != null ? _cleanVar(onTap) : '() {}';
        buffer.write('ElevatedButton(onPressed: $action, child: Text($val))');
        break;

      default:
        // Generic fallback widget
        buffer.write('Container()');
    }
  }

  void _transpileChildWithCondition(
    QuarkNode child,
    StringBuffer buffer,
    int indentLevel,
  ) {
    final indent = ' ' * indentLevel;
    if (child.hasCondition) {
      final cond = _cleanVar(child.condition!);
      buffer.write('$indent if ($cond) ');
      _transpileNode(child, buffer, indentLevel);
      buffer.writeln(',');
    } else {
      buffer.write(indent);
      _transpileNode(child, buffer, indentLevel);
      buffer.writeln(',');
    }
  }

  String _resolveValue(String raw) {
    final trimmed = raw.trim();
    if (trimmed.startsWith(r'$')) {
      return trimmed.substring(1);
    }
    if ((trimmed.startsWith("'") && trimmed.endsWith("'")) ||
        (trimmed.startsWith('"') && trimmed.endsWith('"'))) {
      return trimmed;
    }
    return "'$trimmed'";
  }

  String _cleanVar(String raw) {
    final trimmed = raw.trim();
    if (trimmed.startsWith(r'$')) {
      return trimmed.substring(1);
    }
    return trimmed;
  }
}
