import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart';
import 'package:mason/mason.dart';
import 'package:usage/usage_io.dart';
import 'package:groovin_cli/src/commands/commands.dart';

import 'version.dart';

/// {@template groovin_command_runner}
/// A [CommandRunner] for the Groovin CLI.
/// {@endtemplate}
class GroovinCommandRunner extends CommandRunner<int> {
  /// {@macro groovin_command_runner}
  GroovinCommandRunner({Logger logger})
      : _logger = logger ?? Logger(),
        super('groovin', '🍪 A Delicious Command Line Interface') {
    argParser
      ..addFlag(
        'version',
        negatable: false,
        help: 'Print the current version.',
      );
      /*..addOption(
        'analytics',
        help: 'Toggle anonymous usage statistics.',
        allowed: ['true', 'false'],
        allowedHelp: {
          'true': 'Enable anonymous usage statistics',
          'false': 'Disable anonymous usage statistics',
        },
      );*/
    addCommand(CreateCommand(logger: logger));
  }

  /// Standard timeout duration for the CLI.
  static const timeout = Duration(milliseconds: 500);

  final Logger _logger;

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      /*if (_analytics.firstRun) {
        final response = _logger.prompt(lightGray.wrap(
'''+---------------------------------------------------+
|           Welcome to the Groovin CLI!           |
+---------------------------------------------------+
| We would like to collect anonymous                |
| usage statistics in order to improve the tool.    |
| Would you like to opt-into help us improve? [y/n] |
+---------------------------------------------------+\n''',
        ));
        final normalizedResponse = response.toLowerCase().trim();
        _analytics.enabled =
            normalizedResponse == 'y' || normalizedResponse == 'yes';
      }*/
      final _argResults = parse(args);
      return await runCommand(_argResults) ?? ExitCode.success.code;
    } on FormatException catch (e, stackTrace) {
      _logger
        ..err(e.message)
        ..err('$stackTrace')
        ..info('')
        ..info(usage);
      return ExitCode.usage.code;
    } on UsageException catch (e) {
      _logger
        ..err(e.message)
        ..info('')
        ..info(usage);
      return ExitCode.usage.code;
    }
  }

  @override
  Future<int> runCommand(ArgResults topLevelResults) async {
    if (topLevelResults['version'] == true) {
      _logger.info('groovin version: $packageVersion');
      return ExitCode.success.code;
    }
    /*if (topLevelResults['analytics'] != null) {
      final optIn = topLevelResults['analytics'] == 'true' ? true : false;
      _analytics.enabled = optIn;
      _logger.info('analytics ${_analytics.enabled ? 'enabled' : 'disabled'}.');
      return ExitCode.success.code;
    }*/
    return super.runCommand(topLevelResults);
  }
}
