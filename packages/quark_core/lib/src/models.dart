/// Data structures for Quark Spec representation.

class QuarkProp {
  final String name;
  final String rawType;

  QuarkProp({required this.name, required this.rawType});

  String get dartType {
    switch (rawType.toLowerCase()) {
      case 'string':
        return 'String';
      case 'int':
        return 'int';
      case 'double':
        return 'double';
      case 'bool':
        return 'bool';
      case 'action':
        return 'VoidCallback';
      default:
        if (rawType.startsWith('action<') && rawType.endsWith('>')) {
          final inner = rawType.substring(7, rawType.length - 1);
          return 'ValueChanged<$inner>';
        }
        return rawType;
    }
  }
}

class QuarkNode {
  final String type;
  final String? value;
  final Map<String, String> modifiers;
  final List<QuarkNode> children;

  QuarkNode({
    required this.type,
    this.value,
    this.modifiers = const {},
    this.children = const [],
  });

  bool get hasCondition => modifiers.containsKey('when');
  String? get condition => modifiers['when'];
}

class QuarkSpec {
  final String widgetName;
  final List<QuarkProp> props;
  final QuarkNode rootUi;

  QuarkSpec({
    required this.widgetName,
    required this.props,
    required this.rootUi,
  });
}
