library cork.dynamic;

import 'package:cork/cork.dart';
export 'package:cork/cork.dart';
import 'package:cork/src/mirrors.dart';

/// Create a dynamic (mirrors-resolved) [Injector] from [entryPoint].
Injector createInjector(Type entryPoint) => new Injector(resolve(entryPoint));
