import 'package:yaml/yaml.dart';
import 'models.dart';

class QuarkParser {
  QuarkSpec parse(String yamlContent) {
    final doc = loadYaml(yamlContent);
    if (doc is! Map) {
      throw FormatException('Quark Spec root must be a YAML mapping');
    }

    final widgetName = doc['widget']?.toString() ?? 'QuarkWidget';

    // Parse props
    final rawProps = doc['props'];
    final props = <QuarkProp>[];
    if (rawProps is List) {
      for (final item in rawProps) {
        if (item is Map) {
          for (final entry in item.entries) {
            props.add(QuarkProp(
              name: entry.key.toString(),
              rawType: entry.value.toString(),
            ));
          }
        } else if (item is String) {
          // e.g. "name: string"
          final parts = item.split(':');
          if (parts.length == 2) {
            props.add(QuarkProp(
              name: parts[0].trim(),
              rawType: parts[1].trim(),
            ));
          }
        }
      }
    }

    // Parse UI
    final rawUi = doc['ui'];
    if (rawUi is! Map || rawUi.isEmpty) {
      throw FormatException('Quark Spec must contain a non-empty "ui" section');
    }

    final rootEntry = rawUi.entries.first;
    final rootNode = _parseNode(rootEntry.key.toString(), rootEntry.value);

    return QuarkSpec(
      widgetName: widgetName,
      props: props,
      rootUi: rootNode,
    );
  }

  QuarkNode _parseNode(String rawKey, dynamic rawValue) {
    final parsedKey = _parseKeyAndModifiers(rawKey);
    final type = parsedKey.type;
    final modifiers = Map<String, String>.from(parsedKey.modifiers);

    if (rawValue is List) {
      final children = <QuarkNode>[];
      for (final child in rawValue) {
        if (child is Map) {
          for (final entry in child.entries) {
            children.add(_parseNode(entry.key.toString(), entry.value));
          }
        } else if (child is String) {
          children.add(_parseStringLeaf(child));
        }
      }
      return QuarkNode(type: type, modifiers: modifiers, children: children);
    } else if (rawValue is Map) {
      final children = <QuarkNode>[];
      for (final entry in rawValue.entries) {
        children.add(_parseNode(entry.key.toString(), entry.value));
      }
      return QuarkNode(type: type, modifiers: modifiers, children: children);
    } else {
      // Leaf node with a value, e.g. "text: $name (titleMedium)"
      final parsedValue = _parseValueAndModifiers(rawValue?.toString() ?? '');
      modifiers.addAll(parsedValue.modifiers);
      return QuarkNode(
        type: type,
        value: parsedValue.value,
        modifiers: modifiers,
      );
    }
  }

  QuarkNode _parseStringLeaf(String input) {
    // e.g. "text: $name (titleMedium)"
    final colonIdx = input.indexOf(':');
    if (colonIdx != -1) {
      final key = input.substring(0, colonIdx).trim();
      final val = input.substring(colonIdx + 1).trim();
      return _parseNode(key, val);
    }
    return QuarkNode(type: input.trim());
  }

  _ParsedElement _parseKeyAndModifiers(String input) {
    return _parseModifiersInString(input);
  }

  _ParsedValue _parseValueAndModifiers(String input) {
    final res = _parseModifiersInString(input);
    return _ParsedValue(value: res.type, modifiers: res.modifiers);
  }

  _ParsedElement _parseModifiersInString(String input) {
    final trimmed = input.trim();
    final parenStart = trimmed.indexOf('(');
    final parenEnd = trimmed.lastIndexOf(')');

    if (parenStart != -1 && parenEnd > parenStart) {
      final base = trimmed.substring(0, parenStart).trim();
      final modContent = trimmed.substring(parenStart + 1, parenEnd).trim();
      final modifiers = <String, String>{};

      // modContent can be: "titleMedium" or "when: $isPro" or "onTap: $onFollow, titleMedium"
      final parts = modContent.split(',');
      for (final part in parts) {
        int delimiterIdx = part.indexOf('=');
        if (delimiterIdx == -1) {
          delimiterIdx = part.indexOf(':');
        }
        if (delimiterIdx != -1) {
          final k = part.substring(0, delimiterIdx).trim();
          final v = part.substring(delimiterIdx + 1).trim();
          modifiers[k] = v;
        } else {
          final flag = part.trim();
          if (flag.isNotEmpty) {
            modifiers['style'] = flag;
          }
        }
      }
      return _ParsedElement(type: base, modifiers: modifiers);
    }

    return _ParsedElement(type: trimmed, modifiers: {});
  }
}

class _ParsedElement {
  final String type;
  final Map<String, String> modifiers;
  _ParsedElement({required this.type, required this.modifiers});
}

class _ParsedValue {
  final String value;
  final Map<String, String> modifiers;
  _ParsedValue({required this.value, required this.modifiers});
}
