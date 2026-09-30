import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:quark_core/quark_core.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    print('⚡ Quark Engine CLI v1.0.0');
    print('Usage:');
    print('  quark <file.qrk> [--output <file.dart>]  # Transpile Spec to Dart');
    print('  quark <file.dart> [--output <file.qrk>] # Compress Dart to Spec via AST');
    exit(1);
  }

  final inputPath = args[0];
  final inputFile = File(inputPath);
  if (!inputFile.existsSync()) {
    print('❌ Erreur : Fichier introuvable : $inputPath');
    exit(1);
  }

  final ext = p.extension(inputPath).toLowerCase();

  if (ext == '.qrk') {
    _handleSpecToDart(inputFile, args);
  } else if (ext == '.dart') {
    _handleDartToSpec(inputFile, args);
  } else {
    print('❌ Extension de fichier non reconnue ($ext). Utilisez un fichier .qrk ou .dart.');
    exit(1);
  }
}

void _handleSpecToDart(File specFile, List<String> args) {
  print('⚡ [Quark Engine] Transpilation de la spec : ${specFile.path}');
  final qrkContent = specFile.readAsStringSync();

  final parser = QuarkParser();
  final transpiler = QuarkTranspiler();

  try {
    final spec = parser.parse(qrkContent);
    print('🔍 Widget détecté : ${spec.widgetName}');
    print('📦 Propriétés : ${spec.props.map((p) => '${p.name} (${p.dartType})').join(', ')}');

    final dartCode = transpiler.transpile(spec);

    String outputPath;
    final outFlagIdx = args.indexOf('--output');
    if (outFlagIdx != -1 && outFlagIdx + 1 < args.length) {
      outputPath = args[outFlagIdx + 1];
    } else {
      outputPath = p.setExtension(specFile.path, '.dart');
    }

    File(outputPath).writeAsStringSync(dartCode);
    print('✅ Code Flutter généré avec succès dans : $outputPath\n');

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

void _handleDartToSpec(File dartFile, List<String> args) {
  print('⚡ [Quark Engine] Compression AST du code Dart : ${dartFile.path}');
  final dartContent = dartFile.readAsStringSync();

  final extractor = QuarkExtractor();

  try {
    final spec = extractor.extract(dartContent);
    print('🔍 Widget extrait : ${spec.widgetName}');
    print('📦 Propriétés extraites : ${spec.props.map((p) => '${p.name} (${p.rawType})').join(', ')}');

    final qrkYaml = extractor.toYaml(spec);

    String outputPath;
    final outFlagIdx = args.indexOf('--output');
    if (outFlagIdx != -1 && outFlagIdx + 1 < args.length) {
      outputPath = args[outFlagIdx + 1];
    } else {
      outputPath = p.setExtension(dartFile.path, '.extracted.qrk');
    }

    File(outputPath).writeAsStringSync(qrkYaml);
    print('✅ Quark Spec extraite avec succès dans : $outputPath\n');

    final dartChars = dartContent.length;
    final qrkChars = qrkYaml.length;
    final estimatedDartTokens = (dartChars / 4).round();
    final estimatedQrkTokens = (qrkChars / 4).round();
    final savings = (((estimatedDartTokens - estimatedQrkTokens) / estimatedDartTokens) * 100).toStringAsFixed(1);

    print('📊 [Quark AST Compression Report]');
    print('  - Code Dart original : $dartChars caractères (~$estimatedDartTokens tokens)');
    print('  - Quark Spec extraite: $qrkChars caractères (~$estimatedQrkTokens tokens)');
    print('  - Compression de tokens : -$savings % 🚀');
  } catch (e, stack) {
    print('❌ Erreur lors de l\'extraction AST : $e');
    print(stack);
    exit(1);
  }
}
