/// Quark Pulse - Single-Pass LLM Invocator for Quark Engine.
library;

import 'dart:convert';
import 'dart:io';
import 'models.dart';
import 'parser.dart';
import 'transpiler.dart';

/// Standard Prompt definitions and token estimation for Quark Pulse.
class QuarkPulsePrompt {
  static const String systemPrompt = '''
You are Quark Pulse, the ultra-compact Spec-Driven Flutter architect of Quark Engine.
Your objective: Generate or modify a Quark Spec (.qrk) with absolute determinism and zero syntax noise.

RULES:
1. Respond ONLY with the complete, updated Quark Spec in a ```yaml code block.
2. No conversational greetings, no explanations, no markdown commentary outside the code block.
3. No raw Dart code (Dart code is transpiled locally).

QUARK SPEC GRAMMAR (v1):
widget: <WidgetName>
props:
  - <name>: string | int | double | bool | action | action<T>

ui:
  <rootContainer>: # card | box | row | col | stack
    # Indentation: 2 spaces per hierarchy level
    - avatar: \$avatarUrl
    - text: \$name (titleMedium)
    - chip: PRO (when=\$isPro)
    - button: Follow (onTap=\$onFollow)
    - col:
        - ...
    - row:
        - ...

MODIFIERS:
- Typography: (styleName), e.g. (titleMedium), (bodySmall), (headlineLarge)
- Conditional: (when=\$boolProp)
- Action: (onTap=\$actionProp)
''';

  /// Formats the single-pass prompt combining current spec and developer instruction.
  static String buildUserMessage({
    String? currentSpec,
    required String instruction,
  }) {
    final buffer = StringBuffer();
    if (currentSpec != null && currentSpec.trim().isNotEmpty) {
      buffer.writeln('CURRENT SPEC:');
      buffer.writeln('```yaml');
      buffer.writeln(currentSpec.trim());
      buffer.writeln('```');
      buffer.writeln();
    }
    buffer.writeln('INSTRUCTION:');
    buffer.writeln(instruction.trim());
    return buffer.toString();
  }

  /// Approximate token counter (~4 characters per token).
  static int estimateTokens(String text) {
    if (text.isEmpty) return 0;
    return (text.length / 4).round();
  }
}

/// Execution metrics and generated outputs from a Quark Pulse pass.
class QuarkPulseResult {
  final String originalSpec;
  final String promptSent;
  final String rawResponse;
  final String updatedSpecYaml;
  final QuarkSpec parsedSpec;
  final String generatedDartCode;
  final int inputTokens;
  final int outputTokens;
  final int dartTokens;
  final double tokenSavingsPercent;

  QuarkPulseResult({
    required this.originalSpec,
    required this.promptSent,
    required this.rawResponse,
    required this.updatedSpecYaml,
    required this.parsedSpec,
    required this.generatedDartCode,
    required this.inputTokens,
    required this.outputTokens,
    required this.dartTokens,
    required this.tokenSavingsPercent,
  });
}

/// Abstract LLM Provider interface.
abstract class QuarkPulseProvider {
  Future<String> complete({
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.1,
  });
}

/// Mock / Simulation Provider for deterministic offline testing and benchmarks.
class SimulationPulseProvider implements QuarkPulseProvider {
  final String Function(String systemPrompt, String userPrompt)? onComplete;
  final String? fixedResponse;

  SimulationPulseProvider({this.onComplete, this.fixedResponse});

  @override
  Future<String> complete({
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.1,
  }) async {
    if (fixedResponse != null) {
      return fixedResponse!;
    }
    if (onComplete != null) {
      return onComplete!(systemPrompt, userPrompt);
    }
    throw StateError(
        'SimulationPulseProvider requires either fixedResponse or onComplete.');
  }
}

/// Generic OpenAI/Ollama-compatible HTTP Provider.
class OpenAiPulseProvider implements QuarkPulseProvider {
  final String baseUrl;
  final String apiKey;
  final String model;

  OpenAiPulseProvider({
    this.baseUrl = 'http://localhost:11434/v1',
    this.apiKey = 'ollama',
    this.model = 'llama3',
  });

  @override
  Future<String> complete({
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.1,
  }) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl/chat/completions');
      final request = await client.postUrl(uri);
      request.headers.set('Content-Type', 'application/json');
      if (apiKey.isNotEmpty) {
        request.headers.set('Authorization', 'Bearer $apiKey');
      }

      final payload = {
        'model': model,
        'temperature': temperature,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
      };

      request.add(utf8.encode(jsonEncode(payload)));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        throw HttpException(
          'HTTP ${response.statusCode}: $responseBody',
          uri: uri,
        );
      }

      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      final choices = json['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        throw FormatException('No choices returned by LLM endpoint');
      }
      final message = choices.first['message'] as Map<String, dynamic>;
      return message['content']?.toString() ?? '';
    } finally {
      client.close();
    }
  }
}

/// The core Quark Pulse Single-Pass Engine.
class QuarkPulse {
  final QuarkPulseProvider provider;
  final QuarkParser parser;
  final QuarkTranspiler transpiler;

  QuarkPulse({
    required this.provider,
    QuarkParser? parser,
    QuarkTranspiler? transpiler,
  })  : parser = parser ?? QuarkParser(),
        transpiler = transpiler ?? QuarkTranspiler();

  /// Extracts pure YAML content from LLM response.
  static String extractSpec(String raw) {
    var content = raw.trim();
    final codeBlockRegex =
        RegExp(r'```(?:yaml|qrk)?\s*([\s\S]*?)```', multiLine: true);
    final match = codeBlockRegex.firstMatch(content);
    if (match != null) {
      content = match.group(1)?.trim() ?? content;
    }
    return content;
  }

  /// Executes a single-pass modification or creation.
  Future<QuarkPulseResult> execute({
    String? currentSpec,
    required String instruction,
  }) async {
    final systemPrompt = QuarkPulsePrompt.systemPrompt;
    final userPrompt = QuarkPulsePrompt.buildUserMessage(
      currentSpec: currentSpec,
      instruction: instruction,
    );

    final rawResponse = await provider.complete(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
    );

    final extractedYaml = extractSpec(rawResponse);
    final parsedSpec = parser.parse(extractedYaml);
    final generatedDart = transpiler.transpile(parsedSpec);

    final inputTokens =
        QuarkPulsePrompt.estimateTokens(systemPrompt + userPrompt);
    final outputTokens = QuarkPulsePrompt.estimateTokens(extractedYaml);
    final dartTokens = QuarkPulsePrompt.estimateTokens(generatedDart);

    // Baseline Flutter agent cost comparison (sending full Dart file + verbose instructions)
    final baselineInputTokens = dartTokens + 800;
    final savings = baselineInputTokens > 0
        ? (((baselineInputTokens - inputTokens) / baselineInputTokens) * 100)
            .clamp(0.0, 99.9)
        : 0.0;

    return QuarkPulseResult(
      originalSpec: currentSpec ?? '',
      promptSent: userPrompt,
      rawResponse: rawResponse,
      updatedSpecYaml: extractedYaml,
      parsedSpec: parsedSpec,
      generatedDartCode: generatedDart,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      dartTokens: dartTokens,
      tokenSavingsPercent: savings,
    );
  }
}
