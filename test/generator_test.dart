library cork.test.generator_test;

import 'package:cork/cork.dart';
import 'package:cork/src/generator.dart';
import 'package:cork/testing/library/foo.dart';
import 'package:cork/testing/library/foo_generated.dart' as generated;
import 'package:test/test.dart';

void main() {
  group('StaticBindingGenerator', () {
    final foo = Uri.parse('package:cork/testing/library/foo.dart');
    StaticBindingGenerator generator;

    setUp(() {
      generator = new StaticBindingGenerator();
    });

    test('analyzes a library and generate a collection of bindings', () async {
      var result = await generator.generate(foo);
      expect(result, [
        "import 'package:cork/src/binding.dart';",
        "import 'package:cork/testing/library/foo.dart' as import_1;",
        "",
        "final staticBindings = [",
        "  new Binding(import_1.Foo, new Provider((_) => new import_1.Foo(), [])),",
        "];\n"
      ].join('\n'));
    });

    test('produces bindings that work with Injector', () {
      var injector = new Injector(generated.staticBindings);
      expect(injector.get(Foo), const isInstanceOf<Foo>());
    });
  });
}
