import 'package:quark_core/quark_core.dart';

void main() {
  const sampleSpec = '''
widget: SimpleCard
props:
  - title: string
  - count: int

ui:
  card:
    col:
      - text: \$title
      - text: \$count
''';

  print('--- 1. Parsing Spec ---');
  final parser = QuarkParser();
  final spec = parser.parse(sampleSpec);
  print('Widget: \${spec.widgetName}, Props: \${spec.props.length}');

  print('\n--- 2. Transpiling to Dart ---');
  final transpiler = QuarkTranspiler();
  final dartCode = transpiler.transpile(spec);
  print(dartCode);

  print('\n--- 3. Extracting back from Dart ---');
  final extractor = QuarkExtractor();
  final extractedSpec = extractor.extract(dartCode);
  final yamlOut = extractor.toYaml(extractedSpec);
  print(yamlOut);
}
