library cork_static_bindings;

import 'package:cork/src/binding.dart';
import 'package:cork/src/binding.dart' as import_1;
import 'package:cork/src/binding.dart' as import_1;
import 'package:cork/testing/library/foo.dart' as import_2;
import 'package:cork/testing/library/foo.dart' as import_2;

final staticBindings = <import_1.Binding>[
  new import_1.Binding(import_2.Foo,
      new import_1.Provider((args) => new import_2.Foo(), const []))
];
