import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'models.dart';

class _WidgetCall {
  final String typeName;
  final NodeList<Expression> arguments;

  _WidgetCall(this.typeName, this.arguments);

  static _WidgetCall? from(Expression expr) {
    if (expr is InstanceCreationExpression) {
      final typeName = expr.constructorName.type.toSource();
      return _WidgetCall(typeName, expr.argumentList.arguments);
    } else if (expr is MethodInvocation) {
      if (expr.target == null) {
        return _WidgetCall(expr.methodName.name, expr.argumentList.arguments);
      } else {
        final target = expr.target!.toSource();
        return _WidgetCall(target, expr.argumentList.arguments);
      }
    }
    return null;
  }
}

/// Quark Extractor - Reads Dart AST and compresses it into a QuarkSpec.
class QuarkExtractor {
  QuarkSpec extract(String dartCode) {
    final parseResult = parseString(content: dartCode);
    final unit = parseResult.unit;

    ClassDeclaration? targetClass;
    for (final declaration in unit.declarations) {
      if (declaration is ClassDeclaration) {
        final extendsClause = declaration.extendsClause;
        if (extendsClause != null &&
            extendsClause.superclass.toSource() == 'StatelessWidget') {
          targetClass = declaration;
          break;
        }
      }
    }

    if (targetClass == null) {
      throw FormatException(
          'Aucune classe StatelessWidget trouvée dans le fichier Dart.');
    }

    final widgetName = targetClass.namePart.typeName.lexeme;

    // 1. Extract props
    final props = <QuarkProp>[];
    for (final member in targetClass.body.members) {
      if (member is FieldDeclaration) {
        final rawTypeStr = member.fields.type?.toSource() ?? 'dynamic';
        final qrkType = _toQuarkType(rawTypeStr);
        for (final variable in member.fields.variables) {
          props.add(QuarkProp(
            name: variable.name.lexeme,
            rawType: qrkType,
          ));
        }
      }
    }

    // 2. Find build method and return expression
    MethodDeclaration? buildMethod;
    for (final member in targetClass.body.members) {
      if (member is MethodDeclaration && member.name.lexeme == 'build') {
        buildMethod = member;
        break;
      }
    }

    if (buildMethod == null) {
      throw FormatException('Méthode build() introuvable.');
    }

    Expression? returnExpression;
    final body = buildMethod.body;
    if (body is BlockFunctionBody) {
      for (final stmt in body.block.statements) {
        if (stmt is ReturnStatement) {
          returnExpression = stmt.expression;
          break;
        }
      }
    } else if (body is ExpressionFunctionBody) {
      returnExpression = body.expression;
    }

    if (returnExpression == null) {
      throw FormatException('Instruction return ou expression introuvable dans build().');
    }

    final rootNode = _astToQuarkNode(returnExpression);

    return QuarkSpec(
      widgetName: widgetName,
      props: props,
      rootUi: rootNode,
    );
  }

  QuarkNode _astToQuarkNode(Expression expr, {String? condition}) {
    final modifiers = <String, String>{};
    if (condition != null) {
      modifiers['when'] = condition;
    }

    final call = _WidgetCall.from(expr);
    if (call != null) {
      final typeName = call.typeName;
      final args = call.arguments;

      switch (typeName) {
        case 'Card':
          final childArg = _findNamedArg(args, 'child');
          final children = <QuarkNode>[];
          if (childArg != null) {
            children.add(_astToQuarkNode(childArg.expression));
          }
          return QuarkNode(type: 'card', modifiers: modifiers, children: children);

        case 'Row':
          final childrenArg = _findNamedArg(args, 'children');
          final children = _extractChildren(childrenArg?.expression);
          return QuarkNode(type: 'row', modifiers: modifiers, children: children);

        case 'Column':
          final childrenArg = _findNamedArg(args, 'children');
          final children = _extractChildren(childrenArg?.expression);
          return QuarkNode(type: 'col', modifiers: modifiers, children: children);

        case 'Stack':
          final childrenArg = _findNamedArg(args, 'children');
          final children = _extractChildren(childrenArg?.expression);
          return QuarkNode(type: 'stack', modifiers: modifiers, children: children);

        case 'Container':
        case 'SizedBox':
          final childArg = _findNamedArg(args, 'child');
          final children = <QuarkNode>[];
          if (childArg != null) {
            children.add(_astToQuarkNode(childArg.expression));
          }
          return QuarkNode(type: 'box', modifiers: modifiers, children: children);

        case 'Text':
          final textValue = _extractFirstArg(args);
          final styleArg = _findNamedArg(args, 'style');
          if (styleArg != null) {
            final styleSource = styleArg.expression.toSource();
            final parts = styleSource.split('.');
            if (parts.isNotEmpty) {
              modifiers['style'] = parts.last;
            }
          }
          return QuarkNode(
            type: 'text',
            value: _cleanTextValue(textValue),
            modifiers: modifiers,
          );

        case 'CircleAvatar':
          final bgArg = _findNamedArg(args, 'backgroundImage');
          String avatarVal = '';
          if (bgArg != null) {
            final bgCall = _WidgetCall.from(bgArg.expression);
            if (bgCall != null && bgCall.arguments.isNotEmpty) {
              avatarVal = _extractFirstArg(bgCall.arguments);
            } else {
              avatarVal = bgArg.expression.toSource();
            }
          }
          return QuarkNode(
            type: 'avatar',
            value: _cleanTextValue(avatarVal),
            modifiers: modifiers,
          );

        case 'Chip':
          final labelArg = _findNamedArg(args, 'label');
          String labelVal = '';
          if (labelArg != null) {
            final lblCall = _WidgetCall.from(labelArg.expression);
            if (lblCall != null && lblCall.arguments.isNotEmpty) {
              labelVal = _extractFirstArg(lblCall.arguments);
            } else {
              labelVal = labelArg.expression.toSource();
            }
          }
          return QuarkNode(
            type: 'chip',
            value: _cleanTextValue(labelVal),
            modifiers: modifiers,
          );

        case 'ElevatedButton':
        case 'TextButton':
        case 'OutlinedButton':
        case 'FilledButton':
          final childArg = _findNamedArg(args, 'child');
          final onPresArg = _findNamedArg(args, 'onPressed');
          String btnText = '';
          if (childArg != null) {
            final btnChildCall = _WidgetCall.from(childArg.expression);
            if (btnChildCall != null && btnChildCall.arguments.isNotEmpty) {
              btnText = _extractFirstArg(btnChildCall.arguments);
            } else {
              btnText = childArg.expression.toSource();
            }
          }
          if (onPresArg != null) {
            final actionSource = onPresArg.expression.toSource();
            modifiers['onTap'] = actionSource.startsWith(r'$') ? actionSource : '\$$actionSource';
          }
          return QuarkNode(
            type: 'button',
            value: _cleanTextValue(btnText),
            modifiers: modifiers,
          );

        default:
          final childArg = _findNamedArg(args, 'child');
          final childrenArg = _findNamedArg(args, 'children');
          if (childArg != null) {
            return QuarkNode(
              type: typeName.toLowerCase(),
              modifiers: modifiers,
              children: [_astToQuarkNode(childArg.expression)],
            );
          } else if (childrenArg != null) {
            return QuarkNode(
              type: typeName.toLowerCase(),
              modifiers: modifiers,
              children: _extractChildren(childrenArg.expression),
            );
          }
          return QuarkNode(type: typeName.toLowerCase(), modifiers: modifiers);
      }
    }

    return QuarkNode(type: 'unknown', modifiers: modifiers);
  }

  List<QuarkNode> _extractChildren(Expression? expr) {
    final nodes = <QuarkNode>[];
    if (expr is ListLiteral) {
      for (final element in expr.elements) {
        if (element is IfElement) {
          final condStr = '\$${element.expression.toSource()}';
          if (element.thenElement is Expression) {
            nodes.add(_astToQuarkNode(
              element.thenElement as Expression,
              condition: condStr,
            ));
          }
        } else if (element is Expression) {
          nodes.add(_astToQuarkNode(element));
        }
      }
    }
    return nodes;
  }

  NamedExpression? _findNamedArg(NodeList<Expression> args, String name) {
    for (final arg in args) {
      if (arg is NamedExpression && arg.name.label.name == name) {
        return arg;
      }
    }
    return null;
  }

  String _extractFirstArg(NodeList<Expression> args) {
    if (args.isNotEmpty && args.first is! NamedExpression) {
      return args.first.toSource();
    }
    return '';
  }

  String _cleanTextValue(String raw) {
    final trimmed = raw.trim();
    if ((trimmed.startsWith("'") && trimmed.endsWith("'")) ||
        (trimmed.startsWith('"') && trimmed.endsWith('"'))) {
      return trimmed.substring(1, trimmed.length - 1);
    }
    if (trimmed.startsWith(r'$')) {
      return trimmed;
    }
    // If it's a variable identifier, prefix with $
    if (RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$').hasMatch(trimmed)) {
      return '\$$trimmed';
    }
    return trimmed;
  }

  String _toQuarkType(String dartType) {
    switch (dartType) {
      case 'String':
        return 'string';
      case 'int':
        return 'int';
      case 'double':
        return 'double';
      case 'bool':
        return 'bool';
      case 'VoidCallback':
        return 'action';
      default:
        return dartType;
    }
  }

  String toYaml(QuarkSpec spec) {
    final buf = StringBuffer();
    buf.writeln('widget: ${spec.widgetName}');
    buf.writeln('props:');
    for (final p in spec.props) {
      buf.writeln('  - ${p.name}: ${p.rawType}');
    }
    buf.writeln();
    buf.writeln('ui:');
    _serializeNode(spec.rootUi, buf, 2, inList: false);
    return buf.toString();
  }

  void _serializeNode(
    QuarkNode node,
    StringBuffer buf,
    int indentLevel, {
    required bool inList,
  }) {
    final indent = ' ' * indentLevel;
    final prefix = inList ? '$indent- ' : indent;

    if (node.children.isEmpty) {
      buf.writeln('$prefix${_formatLeaf(node)}');
    } else {
      buf.writeln('$prefix${node.type}:');
      final childIndent = inList ? indentLevel + 4 : indentLevel + 2;
      final isSingleChildContainer =
          node.type == 'card' || node.type == 'box';

      if (isSingleChildContainer && node.children.length == 1) {
        _serializeNode(node.children.first, buf, childIndent, inList: false);
      } else {
        for (final child in node.children) {
          _serializeNode(child, buf, childIndent, inList: true);
        }
      }
    }
  }

  String _formatLeaf(QuarkNode node) {
    String modStr = '';
    if (node.modifiers.isNotEmpty) {
      final parts = <String>[];
      if (node.modifiers.containsKey('style')) {
        parts.add(node.modifiers['style']!);
      }
      if (node.modifiers.containsKey('when')) {
        parts.add('when=${node.modifiers['when']}');
      }
      if (node.modifiers.containsKey('onTap')) {
        parts.add('onTap=${node.modifiers['onTap']}');
      }
      if (parts.isNotEmpty) {
        modStr = ' (${parts.join(', ')})';
      }
    }

    if (node.value != null && node.value!.isNotEmpty) {
      return '${node.type}: ${node.value}$modStr';
    }
    return '${node.type}$modStr';
  }
}
