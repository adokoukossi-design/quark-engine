import 'dart:io';
import 'package:quark_core/quark_core.dart';
import 'package:test/test.dart';

void main() {
  group('Quark Core - Transpiler & Parser', () {
    const rawYaml = '''
widget: UserProfileCard
props:
  - name: string
  - avatarUrl: string
  - isPro: bool
  - onFollow: action

ui:
  card:
    row:
      - avatar: \$avatarUrl
      - col:
          - text: \$name (titleMedium)
          - chip: PRO (when=\$isPro)
      - button: Suivre (onTap=\$onFollow)
''';

    test('QuarkParser parses spec correctly', () {
      final parser = QuarkParser();
      final spec = parser.parse(rawYaml);

      expect(spec.widgetName, equals('UserProfileCard'));
      expect(spec.props.length, equals(4));
      expect(spec.props[0].name, equals('name'));
      expect(spec.props[0].dartType, equals('String'));
      expect(spec.props[2].name, equals('isPro'));
      expect(spec.props[2].dartType, equals('bool'));
      expect(spec.props[3].name, equals('onFollow'));
      expect(spec.props[3].dartType, equals('VoidCallback'));

      expect(spec.rootUi.type, equals('card'));
      expect(spec.rootUi.children.length, equals(1));
      final row = spec.rootUi.children.first;
      expect(row.type, equals('row'));
      expect(row.children.length, equals(3));
    });

    test('QuarkTranspiler produces valid Flutter code', () {
      final parser = QuarkParser();
      final spec = parser.parse(rawYaml);
      final transpiler = QuarkTranspiler();
      final dartCode = transpiler.transpile(spec);

      expect(dartCode, contains('class UserProfileCard extends StatelessWidget {'));
      expect(dartCode, contains('final String name;'));
      expect(dartCode, contains('final bool isPro;'));
      expect(dartCode, contains('final VoidCallback onFollow;'));
      expect(dartCode, contains('Card('));
      expect(dartCode, contains('CircleAvatar(backgroundImage: NetworkImage(avatarUrl))'));
      expect(dartCode, contains('Text(name, style: Theme.of(context).textTheme.titleMedium)'));
      expect(dartCode, contains("if (isPro) Chip(label: Text('PRO'))"));
      expect(dartCode, contains("ElevatedButton(onPressed: onFollow, child: Text('Suivre'))"));
    });
  });

  group('Quark Core - Extractor & AST Compression', () {
    test('QuarkExtractor extracts AST into QuarkSpec and YAML', () {
      const dartCode = '''
import 'package:flutter/material.dart';

class UserProfileCard extends StatelessWidget {
  final String name;
  final String avatarUrl;
  final bool isPro;
  final VoidCallback onFollow;

  const UserProfileCard(
      {super.key,
      required this.name,
      required this.avatarUrl,
      required this.isPro,
      required this.onFollow});

  @override
  Widget build(BuildContext context) {
    return Card(
        child: Row(
      children: [
        CircleAvatar(backgroundImage: NetworkImage(avatarUrl)),
        Column(
          children: [
            Text(name, style: Theme.of(context).textTheme.titleMedium),
            if (isPro) Chip(label: Text('PRO')),
          ],
        ),
        ElevatedButton(onPressed: onFollow, child: Text('Suivre')),
      ],
    ));
  }
}
''';

      final extractor = QuarkExtractor();
      final spec = extractor.extract(dartCode);

      expect(spec.widgetName, equals('UserProfileCard'));
      expect(spec.props.length, equals(4));
      expect(spec.props.map((p) => p.name), containsAll(['name', 'avatarUrl', 'isPro', 'onFollow']));

      final yaml = extractor.toYaml(spec).trim();
      expect(yaml, contains('widget: UserProfileCard'));
      expect(yaml, contains('- avatar: \$avatarUrl'));
      expect(yaml, contains('- text: \$name (titleMedium)'));
      expect(yaml, contains('- chip: PRO (when=\$isPro)'));
      expect(yaml, contains('- button: Suivre (onTap=\$onFollow)'));
    });

    test('Round-Trip Spec -> Dart -> Extracted Spec -> Dart is identical', () {
      final specFile = File('../../examples/user_profile_card.qrk');
      expect(specFile.existsSync(), isTrue);

      final originalSpecYaml = specFile.readAsStringSync().trim();
      final parser = QuarkParser();
      final transpiler = QuarkTranspiler();
      final extractor = QuarkExtractor();

      // 1. Spec -> Dart
      final spec1 = parser.parse(originalSpecYaml);
      final dart1 = transpiler.transpile(spec1);

      // 2. Dart -> Extracted Spec
      final spec2 = extractor.extract(dart1);
      final extractedYaml = extractor.toYaml(spec2).trim();

      // Extracted YAML must match original Spec YAML
      expect(extractedYaml, equals(originalSpecYaml));

      // 3. Extracted Spec -> Dart
      final dart2 = transpiler.transpile(spec2);
      expect(dart2, equals(dart1));
    });

    test('Round-Trip on v2 Spec -> Dart -> Extracted Spec is identical', () {
      final specFile = File('../../examples/user_profile_card_v2.qrk');
      expect(specFile.existsSync(), isTrue);

      final originalSpecYaml = specFile.readAsStringSync().trim();
      final parser = QuarkParser();
      final transpiler = QuarkTranspiler();
      final extractor = QuarkExtractor();

      // 1. Spec -> Dart
      final spec1 = parser.parse(originalSpecYaml);
      final dart1 = transpiler.transpile(spec1);

      // 2. Dart -> Extracted Spec
      final spec2 = extractor.extract(dart1);
      final extractedYaml = extractor.toYaml(spec2).trim();

      // Extracted YAML must match original Spec YAML
      expect(extractedYaml, equals(originalSpecYaml));

      // 3. Extracted Spec -> Dart
      final dart2 = transpiler.transpile(spec2);
      expect(dart2, equals(dart1));
    });
  });

  group('Quark Pulse - Single-Pass LLM Invocator', () {
    test('QuarkPulsePrompt is ultra-compact and dense', () {
      final tokenCount =
          QuarkPulsePrompt.estimateTokens(QuarkPulsePrompt.systemPrompt);
      expect(tokenCount, lessThan(300));
      expect(QuarkPulsePrompt.systemPrompt, contains('QUARK SPEC GRAMMAR'));
      expect(QuarkPulsePrompt.systemPrompt, contains('MODIFIERS'));
    });

    test('QuarkPulsePrompt.buildUserMessage formats payload accurately', () {
      final message = QuarkPulsePrompt.buildUserMessage(
        currentSpec: 'widget: TestWidget\nprops:\n  - id: int',
        instruction: 'Add a title property',
      );

      expect(message, contains('CURRENT SPEC:'));
      expect(message, contains('widget: TestWidget'));
      expect(message, contains('INSTRUCTION:'));
      expect(message, contains('Add a title property'));
    });

    test('QuarkPulse.extractSpec extracts YAML correctly from markdown fences', () {
      const rawMarkdown = '''
Sure! Here is the updated spec:
```yaml
widget: Sample
props:
  - count: int
ui:
  box:
    text: \$count
```
Hope this helps!
''';

      final extracted = QuarkPulse.extractSpec(rawMarkdown);
      expect(extracted, startsWith('widget: Sample'));
      expect(extracted, endsWith('text: \$count'));
      expect(extracted, isNot(contains('Sure!')));
      expect(extracted, isNot(contains('```')));
    });

    test('QuarkPulse execution with simulation provider works end-to-end', () async {
      final v1File = File('../../examples/user_profile_card.qrk');
      final v2File = File('../../examples/user_profile_card_v2.qrk');
      expect(v1File.existsSync(), isTrue);
      expect(v2File.existsSync(), isTrue);

      final v1Content = v1File.readAsStringSync();
      final v2Content = v2File.readAsStringSync();

      final provider = SimulationPulseProvider(
        fixedResponse: '```yaml\n$v2Content\n```',
      );
      final pulse = QuarkPulse(provider: provider);

      final result = await pulse.execute(
        currentSpec: v1Content,
        instruction: 'Add bio and onContact button',
      );

      expect(result.parsedSpec.widgetName, equals('UserProfileCard'));
      expect(result.parsedSpec.props.length, equals(6));
      expect(result.generatedDartCode, contains('final String bio;'));
      expect(result.generatedDartCode, contains('final VoidCallback onContact;'));
      expect(result.generatedDartCode, contains('ElevatedButton(onPressed: onContact, child: Text(\'Contacter\'))'));
      expect(result.inputTokens, lessThan(400));
      expect(result.tokenSavingsPercent, greaterThan(60.0));
    });
  });

  group('Quark Router & Local Engine - Semantic Dispatcher & Local Refactoring', () {
    final router = QuarkRouter();
    final localEngine = QuarkLocalEngine();
    final parser = QuarkParser();

    const sampleYaml = '''
widget: UserProfileCard
props:
  - name: string
  - avatarUrl: string
  - isPro: bool
  - onFollow: action

ui:
  card:
    row:
      - avatar: \$avatarUrl
      - col:
          - text: \$name (titleMedium)
          - chip: PRO (when=\$isPro)
      - button: Suivre (onTap=\$onFollow)
''';

    test('QuarkRouter routes trivial refactors locally and complex tasks to Pulse', () {
      final d1 = router.route('renomme la prop isPro en isPremium');
      expect(d1.isLocal, isTrue);
      expect(d1.localOpType, equals(LocalOperationType.renameProp));
      expect(d1.parameters['oldName'], equals('isPro'));
      expect(d1.parameters['newName'], equals('isPremium'));

      final d2 = router.route('renomme le widget en MemberProfileCard');
      expect(d2.isLocal, isTrue);
      expect(d2.localOpType, equals(LocalOperationType.renameWidget));
      expect(d2.parameters['newWidgetName'], equals('MemberProfileCard'));

      final d3 = router.route('change le style en headlineMedium');
      expect(d3.isLocal, isTrue);
      expect(d3.localOpType, equals(LocalOperationType.changeStyle));
      expect(d3.parameters['newStyle'], equals('headlineMedium'));

      final d4 = router.route('supprime la prop avatarUrl');
      expect(d4.isLocal, isTrue);
      expect(d4.localOpType, equals(LocalOperationType.removeProp));
      expect(d4.parameters['propName'], equals('avatarUrl'));

      final d5 = router.route('ajoute une grille d\'images avec un carousel animé et un switch');
      expect(d5.isPulse, isTrue);
      expect(d5.isLocal, isFalse);
    });

    test('QuarkLocalEngine renames property across props and UI variables with 0 tokens', () {
      final spec = parser.parse(sampleYaml);
      final decision = router.route('renomme la prop isPro en isPremium');
      final updated = localEngine.apply(spec, decision);

      expect(updated.props.any((p) => p.name == 'isPremium'), isTrue);
      expect(updated.props.any((p) => p.name == 'isPro'), isFalse);

      final transpiler = QuarkTranspiler();
      final dartCode = transpiler.transpile(updated);
      expect(dartCode, contains('final bool isPremium;'));
      expect(dartCode, contains('if (isPremium) Chip(label: Text(\'PRO\'))'));
    });

    test('QuarkEngineCoordinator processes local tasks with 0 tokens and pulse tasks with low tokens', () async {
      final pulseProvider = SimulationPulseProvider(
        fixedResponse: sampleYaml,
      );
      final coordinator = QuarkEngineCoordinator(
        pulse: QuarkPulse(provider: pulseProvider),
      );

      // Local route: 0 tokens
      final localResult = await coordinator.process(
        instruction: 'renomme le widget en VipCard',
        currentSpecYaml: sampleYaml,
      );
      expect(localResult.routeDecision.isLocal, isTrue);
      expect(localResult.inputTokensUsed, equals(0));
      expect(localResult.resultSpec.widgetName, equals('VipCard'));
      expect(localResult.generatedDart, contains('class VipCard extends StatelessWidget {'));

      // Pulse route: low tokens
      final pulseResult = await coordinator.process(
        instruction: 'ajoute un bouton de partage avec compteur de likes',
        currentSpecYaml: sampleYaml,
      );
      expect(pulseResult.routeDecision.isPulse, isTrue);
      expect(pulseResult.inputTokensUsed, greaterThan(0));
      expect(pulseResult.inputTokensUsed, lessThan(400));
    });
  });
}
