library cork.generated.DoubleModuleEntrypoint;

import 'package:cork/src/binding/runtime.dart';
import 'package:cork/testing/integration/spec.dart' as import_1;
import 'package:cork/testing/integration/spec.dart' as import_1;
import 'package:cork/testing/integration/spec.dart' as import_1;
import 'package:cork/testing/integration/spec.dart' as import_1;
import 'package:cork/testing/integration/spec.dart' as import_1;
import 'package:cork/testing/integration/spec.dart' as import_1;
import 'package:cork/testing/integration/spec.dart' as import_1;
import 'package:cork/src/binding/runtime.dart' as import_2;
import 'package:cork/src/binding/runtime.dart' as import_2;

final bindingsForDoubleModuleEntrypoint = <import_2.Binding>[
  new import_2.Binding(import_1.Foo, new import_2.Provider(
      (args) => import_1.FooExtensionModule.getFoo(), const [])),
  new import_2.Binding(import_1.Bar, new import_2.Provider(
      (args) => new import_1.Bar(args[0]), const [import_1.Foo]))
];