library cork.generated.SingleModuleEntrypoint;

import 'package:cork/src/binding/runtime.dart';
import 'package:cork/testing/integration/spec.dart' show Bar, Foo;
import 'package:cork/src/binding/runtime.dart' show Binding, Provider;

final bindingsForSingleModuleEntrypoint = <Binding>[
  new Binding(Foo, new Provider((args) => new Foo(), const [])),
  new Binding(Bar, new Provider((args) => new Bar(args[0]), const [Foo]))
];
