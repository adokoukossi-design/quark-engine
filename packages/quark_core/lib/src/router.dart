/// Quark Router - Local Semantic Routing Engine for Zero-Token Pipeline.
library;

import 'extractor.dart';
import 'models.dart';
import 'parser.dart';
import 'pulse.dart';
import 'transpiler.dart';

/// Target destination determined by Quark Router.
enum QuarkRouteTarget {
  localEngine,
  pulse,
}

/// Category of deterministic local refactoring operations.
enum LocalOperationType {
  renameProp,
  renameWidget,
  changeStyle,
  removeProp,
  unknown,
}

/// Routing decision with rationale and extracted parameters.
class QuarkRouteDecision {
  final QuarkRouteTarget target;
  final String reason;
  final LocalOperationType? localOpType;
  final Map<String, String> parameters;
  final double confidence;

  const QuarkRouteDecision({
    required this.target,
    required this.reason,
    this.localOpType,
    this.parameters = const {},
    this.confidence = 1.0,
  });

  bool get isLocal => target == QuarkRouteTarget.localEngine;
  bool get isPulse => target == QuarkRouteTarget.pulse;
}

/// Semantic intent router deciding between local zero-token refactoring and Pulse LLM.
class QuarkRouter {
  /// Analyzes developer intent and determines routing target.
  QuarkRouteDecision route(String instruction, {QuarkSpec? currentSpec}) {
    // 1. Rename Property
    // e.g. "renomme la prop isPro en isPremium", "rename prop name to fullName"
    final renamePropRegex = RegExp(
      r'(?:renomme|rename)\s+(?:la\s+prop(?:riété)?\s+|le\s+champ\s+|property\s+|prop\s+)?([a-zA-Z0-9_]+)\s+(?:en|to|par)\s+([a-zA-Z0-9_]+)',
      caseSensitive: false,
    );
    final renamePropMatch = renamePropRegex.firstMatch(instruction);
    if (renamePropMatch != null) {
      final oldName = renamePropMatch.group(1)!;
      final newName = renamePropMatch.group(2)!;
      return QuarkRouteDecision(
        target: QuarkRouteTarget.localEngine,
        localOpType: LocalOperationType.renameProp,
        reason:
            'Renommage déterministe de propriété exécutable en local sans LLM (0 token).',
        parameters: {'oldName': oldName, 'newName': newName},
        confidence: 0.99,
      );
    }

    // 2. Rename Widget
    // e.g. "renomme le widget en UserCard", "rename widget to ProfileCard"
    final renameWidgetRegex = RegExp(
      r'(?:renomme|rename)\s+(?:le\s+widget\s+|widget\s+)?(?:en|to)\s+([A-Z][a-zA-Z0-9_]*)',
      caseSensitive: false,
    );
    final renameWidgetMatch = renameWidgetRegex.firstMatch(instruction);
    if (renameWidgetMatch != null) {
      final newName = renameWidgetMatch.group(1)!;
      return QuarkRouteDecision(
        target: QuarkRouteTarget.localEngine,
        localOpType: LocalOperationType.renameWidget,
        reason:
            'Renommage déterministe du widget exécutable en local sans LLM (0 token).',
        parameters: {'newWidgetName': newName},
        confidence: 0.99,
      );
    }

    // 3. Change Style Modifier
    // e.g. "change le style en headlineMedium", "change style to titleLarge"
    final changeStyleRegex = RegExp(
      r'(?:change|passe|modifie)\s+(?:le\s+style\s+|la\s+typo\s+|style\s+)?(?:en|to|par)\s+([a-zA-Z0-9_]+)',
      caseSensitive: false,
    );
    final changeStyleMatch = changeStyleRegex.firstMatch(instruction);
    if (changeStyleMatch != null) {
      final newStyle = changeStyleMatch.group(1)!;
      return QuarkRouteDecision(
        target: QuarkRouteTarget.localEngine,
        localOpType: LocalOperationType.changeStyle,
        reason:
            'Modification déterministe de style typographique locale sans LLM (0 token).',
        parameters: {'newStyle': newStyle},
        confidence: 0.95,
      );
    }

    // 4. Remove Property
    // e.g. "supprime la prop avatarUrl", "delete prop bio"
    final removePropRegex = RegExp(
      r'(?:supprime|delete|remove)\s+(?:la\s+prop(?:riété)?\s+|le\s+champ\s+|property\s+|prop\s+)([a-zA-Z0-9_]+)',
      caseSensitive: false,
    );
    final removePropMatch = removePropRegex.firstMatch(instruction);
    if (removePropMatch != null) {
      final propName = removePropMatch.group(1)!;
      return QuarkRouteDecision(
        target: QuarkRouteTarget.localEngine,
        localOpType: LocalOperationType.removeProp,
        reason:
            'Suppression locale d\'une propriété sans consommation de tokens (0 token).',
        parameters: {'propName': propName},
        confidence: 0.95,
      );
    }

    // 5. Default: Complex instruction or new feature requires Quark Pulse
    return const QuarkRouteDecision(
      target: QuarkRouteTarget.pulse,
      reason:
          'Requête créative ou structurelle nécessitant l\'intelligence distante de Quark Pulse.',
      confidence: 0.90,
    );
  }
}

/// Local deterministic transformation engine (0 LLM tokens).
class QuarkLocalEngine {
  QuarkSpec apply(QuarkSpec spec, QuarkRouteDecision decision) {
    switch (decision.localOpType) {
      case LocalOperationType.renameProp:
        final oldName = decision.parameters['oldName']!;
        final newName = decision.parameters['newName']!;
        return renameProp(spec, oldName, newName);

      case LocalOperationType.renameWidget:
        final newWidgetName = decision.parameters['newWidgetName']!;
        return renameWidget(spec, newWidgetName);

      case LocalOperationType.changeStyle:
        final newStyle = decision.parameters['newStyle']!;
        return changeStyle(spec, newStyle);

      case LocalOperationType.removeProp:
        final propName = decision.parameters['propName']!;
        return removeProp(spec, propName);

      default:
        return spec;
    }
  }

  QuarkSpec renameProp(QuarkSpec spec, String oldName, String newName) {
    final updatedProps = spec.props.map((p) {
      if (p.name == oldName) {
        return QuarkProp(name: newName, rawType: p.rawType);
      }
      return p;
    }).toList();

    final updatedUi = _renameVarInNode(spec.rootUi, oldName, newName);

    return QuarkSpec(
      widgetName: spec.widgetName,
      props: updatedProps,
      rootUi: updatedUi,
    );
  }

  QuarkSpec renameWidget(QuarkSpec spec, String newWidgetName) {
    return QuarkSpec(
      widgetName: newWidgetName,
      props: spec.props,
      rootUi: spec.rootUi,
    );
  }

  QuarkSpec changeStyle(QuarkSpec spec, String newStyle) {
    final updatedUi = _changeStyleInNode(spec.rootUi, newStyle);
    return QuarkSpec(
      widgetName: spec.widgetName,
      props: spec.props,
      rootUi: updatedUi,
    );
  }

  QuarkSpec removeProp(QuarkSpec spec, String propName) {
    final updatedProps = spec.props.where((p) => p.name != propName).toList();
    final updatedUi = _removePropReferencesInNode(spec.rootUi, propName);
    return QuarkSpec(
      widgetName: spec.widgetName,
      props: updatedProps,
      rootUi: updatedUi ?? spec.rootUi,
    );
  }

  QuarkNode _renameVarInNode(QuarkNode node, String oldName, String newName) {
    final targetVar = '\$$oldName';
    final newVar = '\$$newName';

    String? updatedValue = node.value;
    if (updatedValue == targetVar) {
      updatedValue = newVar;
    }

    final updatedModifiers = Map<String, String>.from(node.modifiers);
    for (final entry in updatedModifiers.entries.toList()) {
      if (entry.value == targetVar) {
        updatedModifiers[entry.key] = newVar;
      }
    }

    final updatedChildren = node.children
        .map((child) => _renameVarInNode(child, oldName, newName))
        .toList();

    return QuarkNode(
      type: node.type,
      value: updatedValue,
      modifiers: updatedModifiers,
      children: updatedChildren,
    );
  }

  QuarkNode _changeStyleInNode(QuarkNode node, String newStyle) {
    final updatedModifiers = Map<String, String>.from(node.modifiers);
    if (node.type == 'text' && updatedModifiers.containsKey('style')) {
      updatedModifiers['style'] = newStyle;
    }

    final updatedChildren = node.children
        .map((child) => _changeStyleInNode(child, newStyle))
        .toList();

    return QuarkNode(
      type: node.type,
      value: node.value,
      modifiers: updatedModifiers,
      children: updatedChildren,
    );
  }

  QuarkNode? _removePropReferencesInNode(QuarkNode node, String propName) {
    final targetVar = '\$$propName';
    if (node.value == targetVar) {
      return null;
    }

    final updatedChildren = <QuarkNode>[];
    for (final child in node.children) {
      final updated = _removePropReferencesInNode(child, propName);
      if (updated != null) {
        updatedChildren.add(updated);
      }
    }

    return QuarkNode(
      type: node.type,
      value: node.value,
      modifiers: node.modifiers,
      children: updatedChildren,
    );
  }
}

/// Result of complete Quark Engine execution pipeline.
class QuarkEngineResult {
  final QuarkRouteDecision routeDecision;
  final QuarkSpec resultSpec;
  final String resultSpecYaml;
  final String generatedDart;
  final int inputTokensUsed;
  final int tokensSavedVsBaseline;

  QuarkEngineResult({
    required this.routeDecision,
    required this.resultSpec,
    required this.resultSpecYaml,
    required this.generatedDart,
    required this.inputTokensUsed,
    required this.tokensSavedVsBaseline,
  });
}

/// The unified coordinator orchestrating Quark Router, Quark Local Engine, and Quark Pulse.
class QuarkEngineCoordinator {
  final QuarkRouter router;
  final QuarkLocalEngine localEngine;
  final QuarkPulse pulse;
  final QuarkParser parser;
  final QuarkTranspiler transpiler;
  final QuarkExtractor extractor;

  QuarkEngineCoordinator({
    QuarkRouter? router,
    QuarkLocalEngine? localEngine,
    required this.pulse,
    QuarkParser? parser,
    QuarkTranspiler? transpiler,
    QuarkExtractor? extractor,
  })  : router = router ?? QuarkRouter(),
        localEngine = localEngine ?? QuarkLocalEngine(),
        parser = parser ?? QuarkParser(),
        transpiler = transpiler ?? QuarkTranspiler(),
        extractor = extractor ?? QuarkExtractor();

  /// Executes developer intention through the optimal route.
  Future<QuarkEngineResult> process({
    required String instruction,
    String? currentSpecYaml,
  }) async {
    QuarkSpec? initialSpec;
    if (currentSpecYaml != null && currentSpecYaml.trim().isNotEmpty) {
      initialSpec = parser.parse(currentSpecYaml);
    }

    final decision = router.route(instruction, currentSpec: initialSpec);

    if (decision.isLocal && initialSpec != null) {
      // 100% Local Execution — ZERO TOKENS!
      final updatedSpec = localEngine.apply(initialSpec, decision);
      final updatedYaml = extractor.toYaml(updatedSpec);
      final dartCode = transpiler.transpile(updatedSpec);
      final dartTokens = QuarkPulsePrompt.estimateTokens(dartCode);

      return QuarkEngineResult(
        routeDecision: decision,
        resultSpec: updatedSpec,
        resultSpecYaml: updatedYaml,
        generatedDart: dartCode,
        inputTokensUsed: 0,
        tokensSavedVsBaseline: dartTokens + 800,
      );
    } else {
      // Routed to Quark Pulse Single-Pass
      final pulseResult = await pulse.execute(
        currentSpec: currentSpecYaml,
        instruction: instruction,
      );

      return QuarkEngineResult(
        routeDecision: decision,
        resultSpec: pulseResult.parsedSpec,
        resultSpecYaml: pulseResult.updatedSpecYaml,
        generatedDart: pulseResult.generatedDartCode,
        inputTokensUsed: pulseResult.inputTokens,
        tokensSavedVsBaseline:
            pulseResult.dartTokens + 800 - pulseResult.inputTokens,
      );
    }
  }
}
