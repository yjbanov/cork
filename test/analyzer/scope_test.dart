library cork.test.analyzer.scope_test;

import 'package:analysis/analysis.dart';
import 'package:analyzer/analyzer.dart';
import 'package:cork/src/analyzer/scope.dart';
import 'package:test/test.dart';

void main() {
  group('ScopedAnalyzerUtils', () {
    final uri = Uri.parse('package:cork/testing/library/foo.dart');

    Anthology anthology;
    ScopedAnalyzerUtils utils;

    CompilationUnit astUnit;

    setUp(() {
      var resolver = new SourceResolver.forTesting();
      anthology = new Anthology(resolver: resolver);
      var library = anthology.visit(uri: uri);
      astUnit = library.astUnits().first;
      utils = new ScopedAnalyzerUtils.fromAnthology(anthology, library);
    });

    test('can return a scoped type and import', () {
      ClassDeclaration fooModuleClazz = astUnit.declarations.last;
      MethodDeclaration barFactoryMethod = fooModuleClazz.members.first;

      var typeRef = utils.typeRef(barFactoryMethod.returnType.type);
      expect(typeRef.name, 'Bar');
      expect(typeRef.namespace, 'import_1');

      var imports = utils.imports;
      expect(imports, hasLength(1));
      expect(imports.first.as, 'import_1');
      expect(
          imports.first.uri.toString(),
          'package:cork/testing/library/foo_imported.dart');
    });
  });
}
