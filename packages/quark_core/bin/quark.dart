import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:quark_core/quark_core.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    print('⚡ Quark Engine CLI v1.0.0');
    print('Usage: quark <spec_file.qrk> [--output <output.dart>]');
    exit(1);
  }

  final specPath = args[0];
  final specFile = File(specPath);
  if (!specFile.existsSync()) {
    print('❌ Erreur : Fichier introuvable : $specPath');
    exit(1);
  }

  print('⚡ [Quark Engine] Lecture de la spec : $specPath');
  final qrkContent = specFile.readAsStringSync();

  final parser = QuarkParser();
  final transpiler = QuarkTranspiler();

  try {
    final spec = parser.parse(qrkContent);
    print('🔍 Widget détecté : ${spec.widgetName}');
    print('📦 Propriétés : ${spec.props.map((p) => '${p.name} (${p.dartType})').join(', ')}');

    final dartCode = transpiler.transpile(spec);

    // Determine output file
    String outputPath;
    final outFlagIdx = args.indexOf('--output');
    if (outFlagIdx != -1 && outFlagIdx + 1 < args.length) {
      outputPath = args[outFlagIdx + 1];
    } else {
      outputPath = p.setExtension(specPath, '.dart');
    }

    File(outputPath).writeAsStringSync(dartCode);
    print('✅ Code Flutter généré avec succès dans : $outputPath\n');

    // Metrics summary
    final qrkChars = qrkContent.length;
    final dartChars = dartCode.length;
    final estimatedQrkTokens = (qrkChars / 4).round();
    final estimatedDartTokens = (dartChars / 4).round();
    final savings = (((estimatedDartTokens - estimatedQrkTokens) / estimatedDartTokens) * 100).toStringAsFixed(1);

    print('📊 [Quark Metrics Report]');
    print('  - Taille Quark Spec  : $qrkChars caractères (~$estimatedQrkTokens tokens)');
    print('  - Taille Code Dart    : $dartChars caractères (~$estimatedDartTokens tokens)');
    print('  - Économie de tokens : $savings % 🎉');
  } catch (e, stack) {
    print('❌ Erreur lors de la transpilation : $e');
    print(stack);
    exit(1);
  }
}
