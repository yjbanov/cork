import 'package:cork/src/binding.dart';
import 'package:cork/testing/library/foo.dart' as import_1;

final staticBindings = [
  new Binding(import_1.Foo, new Provider((_) => new import_1.Foo(), [])),
];
