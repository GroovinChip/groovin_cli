import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:groovin_cli/src/templates/groovin_core_bundle.dart';

// A valid Dart identifier that can be used for a package, i.e. no
// capital letters.
// https://dart.dev/guides/language/language-tour#important-concepts
final RegExp _identifierRegExp = RegExp('[a-z_][a-z0-9_]*');

/// A method which returns a [Future<MasonGenerator>] given a [MasonBundle].
typedef GeneratorBuilder = Future<MasonGenerator> Function(MasonBundle);

/// {@template create_command}
/// `groovin create` command creates a new groovin flutter app.
/// {@endtemplate}
class CreateCommand extends Command<int> {
  /// {@macro create_command}
  CreateCommand({
    Logger logger,
    GeneratorBuilder generator,
  })  : _logger = logger ?? Logger(),
        _generator = generator ?? MasonGenerator.fromBundle {
    argParser
      ..addOption(
        'project-name',
        help: 'The project name for this new Flutter project. '
            'This must be a valid dart package name.',
        defaultsTo: null,
      )
      ..addOption(
        'description',
        help: 'The description for this new Flutter project.',
        defaultsTo: null,
      )
      ..addOption(
      'package_id',
      help: 'The package or bundle ID for this new Flutter project.',
      defaultsTo: 'com.example.app',
    );
  }

  final Logger _logger;
  final Future<MasonGenerator> Function(MasonBundle) _generator;

  @override
  String get description =>
      'Creates a new groovin flutter project in the specified directory.';

  @override
  String get summary => '$invocation\n$description';

  @override
  String get name => 'create';

  @override
  List<String> get aliases => ['bake'];

  @override
  String get invocation => 'groovin create <output directory>';

  /// [ArgResults] which can be overridden for testing.
  @visibleForTesting
  ArgResults argResultOverrides;

  ArgResults get _argResults => argResultOverrides ?? argResults;

  @override
  Future<int> run() async {
    final outputDirectory = _outputDirectory;
    final projectName = _projectName;
    final description = _description;
    final packageId = _packageId;
    final generateDone = _logger.progress('Bootstrapping');
    final generator = await _generator(groovinCoreBundle);
    final fileCount = await generator.generate(
      DirectoryGeneratorTarget(outputDirectory, _logger),
      vars: {
        'project_name': projectName,
        'description': description,
        'package_id': packageId,
      },
    );

    generateDone('Bootstrapping complete');
    _logSummary(fileCount);

    /*unawaited(_analytics.sendEvent(
      'create',
      generator.id,
      label: generator.description,
    ));
    await _analytics.waitForLastPing(timeout: VeryGoodCommandRunner.timeout);*/

    return ExitCode.success.code;
  }

  void _logSummary(int fileCount) {
    _logger
      ..info(
        '${lightGreen.wrap('✓')} '
        'Generated $fileCount file(s):',
      )
      ..flush(_logger.success)
      ..info('\n')
      ..alert('Created a Groovin App! 🍪')
      ..info('\n');
  }

  /// Gets the project name.
  ///
  /// Uses the current directory path name
  /// if the `--project-name` option is not explicitly specified.
  String get _projectName {
    final projectName = _argResults['project-name'] ??
        path.basename(path.normalize(_outputDirectory.absolute.path));
    _validateProjectName(projectName);
    return projectName;
  }

  String get _description {
    final description = _argResults['description'] ?? '';
    return description;
  }

  String get _packageId {
    final packageId = _argResults['package_id'] ?? 'com.example.app';
    return packageId;
  }

  void _validateProjectName(String name) {
    final isValidProjectName = _isValidPackageName(name);
    if (!isValidProjectName) {
      throw UsageException(
        '"$name" is not a valid package name.\n\n'
        'See https://dart.dev/tools/pub/pubspec#name for more information.',
        usage,
      );
    }
  }

  bool _isValidPackageName(String name) {
    final match = _identifierRegExp.matchAsPrefix(name);
    return match != null && match.end == name.length;
  }

  Directory get _outputDirectory {
    final rest = _argResults.rest;
    _validateOutputDirectoryArg(rest);
    return Directory(rest.first);
  }

  void _validateOutputDirectoryArg(List<String> args) {
    if (args.isEmpty) {
      throw UsageException(
        'No option specified for the output directory.',
        usage,
      );
    }

    if (args.length > 1) {
      throw UsageException('Multiple output directories specified.', usage);
    }
  }
}
