library cork.runtime.logger;

import 'package:logging/logging.dart';

/// A global logger re-used from within cork.
final logger = new Logger('cork');

/// Returns the current stack trace.
StackTrace getStackTrace() {
  try { throw ''; } catch (_, s) { return s; }
}
