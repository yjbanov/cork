library cork.generated.DoubleModuleEntrypoint;

import 'package:cork/src/binding/runtime.dart';
import 'package:cork/testing/integration/spec.dart'
    show Bar, Foo, FooExtensionModule;
import 'package:cork/src/binding/runtime.dart' show Binding, Provider;

final bindingsForDoubleModuleEntrypoint = <Binding>[
  new Binding(
      Foo, new Provider((args) => FooExtensionModule.getFoo(), const [])),
  new Binding(Bar, new Provider((args) => new Bar(args[0]), const [Foo]))
];
