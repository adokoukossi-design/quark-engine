import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:quark_core/quark_core.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('⚡ Quark Engine CLI v1.0.0');
    print('Usage:');
    print('  quark <file.qrk> [--output <file.dart>]         # Transpile Spec to Dart');
    print('  quark <file.dart> [--output <file.qrk>]        # Compress Dart to Spec via AST');
    print('  quark pulse <file.qrk> "<prompt>" [--dry-run]  # Single-pass LLM prompt & spec update');
    exit(1);
  }

  if (args[0] == 'pulse') {
    await _handlePulse(args);
    return;
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

Future<void> _handlePulse(List<String> args) async {
  if (args.length < 2) {
    print('Usage: quark pulse <file.qrk> "<instruction>" [--dry-run] [--output <file.qrk>]');
    exit(1);
  }

  final isDryRun = args.contains('--dry-run');
  String? specPath;
  String? instruction;

  for (int i = 1; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--dry-run') continue;
    if (arg == '--output' && i + 1 < args.length) {
      i++;
      continue;
    }
    if (specPath == null && arg.endsWith('.qrk')) {
      specPath = arg;
    } else {
      instruction ??= arg;
    }
  }

  if (instruction == null) {
    print('❌ Erreur : Instruction utilisateur requise.');
    exit(1);
  }

  String? currentSpecContent;
  if (specPath != null) {
    final f = File(specPath);
    if (!f.existsSync()) {
      print('❌ Erreur : Fichier spec introuvable : $specPath');
      exit(1);
    }
    currentSpecContent = f.readAsStringSync();
  }

  print('⚡ [Quark Pulse] Invocateur Single-Pass');
  print('📝 Instruction : "$instruction"');
  if (specPath != null) {
    print('📄 Spec source : $specPath');
  }

  final userMsg = QuarkPulsePrompt.buildUserMessage(
    currentSpec: currentSpecContent,
    instruction: instruction,
  );

  final systemTokens =
      QuarkPulsePrompt.estimateTokens(QuarkPulsePrompt.systemPrompt);
  final userTokens = QuarkPulsePrompt.estimateTokens(userMsg);
  final totalInputTokens = systemTokens + userTokens;

  print('\n📊 [Quark Pulse Token Footprint]');
  print('  - System Prompt : ~$systemTokens tokens');
  print('  - Spec + Tâche  : ~$userTokens tokens');
  print(
      '  - Total Entrée  : ~$totalInputTokens tokens 🚀 (vs ~1500-3000 tokens en approche classique)');

  if (isDryRun) {
    print('\n--- [PROMPT SYSTÈME EMBARQUÉ] ---');
    print(QuarkPulsePrompt.systemPrompt);
    print('--- [PAYLOAD UTILISATEUR] ---');
    print(userMsg);
    print('✅ Mode Dry-Run terminé.');
    return;
  }

  // Attempt connection with local OpenAiPulseProvider (Ollama / local endpoint)
  final provider = OpenAiPulseProvider();
  final pulse = QuarkPulse(provider: provider);

  try {
    print('\n🌐 Envoi de la requête Single-Pass au LLM...');
    final result = await pulse.execute(
      currentSpec: currentSpecContent,
      instruction: instruction,
    );

    print('✅ Réponse reçue et spec validée !');
    print('🔍 Widget mis à jour : ${result.parsedSpec.widgetName}');

    String outputPath;
    final outFlagIdx = args.indexOf('--output');
    if (outFlagIdx != -1 && outFlagIdx + 1 < args.length) {
      outputPath = args[outFlagIdx + 1];
    } else if (specPath != null) {
      outputPath = specPath;
    } else {
      outputPath = 'generated_widget.qrk';
    }

    File(outputPath).writeAsStringSync(result.updatedSpecYaml);
    print('💾 Spec enregistrée dans : $outputPath');

    // Auto-transpile to Dart
    final dartOutput = p.setExtension(outputPath, '.dart');
    File(dartOutput).writeAsStringSync(result.generatedDartCode);
    print('🎯 Code Dart Flutter synchronisé : $dartOutput');
  } catch (e) {
    print('⚠️ Impossible de contacter le serveur LLM distant ($e).');
    print('💡 Utilisez --dry-run pour inspecter le payload généré.');
  }
}
