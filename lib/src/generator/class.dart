library cork.src.generator;

import 'dart:async';

import 'package:analysis/analysis.dart';
import 'package:analyzer/src/generated/ast.dart' hide ImportDirective;
import 'package:cork/src/binding/analyzer.dart';
import 'package:cork/src/binding/static.dart';
import 'package:dart_builder/dart_builder.dart';

class ClassGenerator {
  final StaticBindingAnalyzer _analyzer;
  final Anthology _anthology;

  ClassGenerator(Anthology anthology)
      : _anthology = anthology,
        _analyzer = new StaticBindingAnalyzer(
            new AnthologyAnalysisProvider(anthology));

  Future<SourceFile> process(Uri uri, String entry) {
    ClassDeclaration clazz = _anthology.visit(uri: uri).getDeclaration(entry);
    return generate(_analyzer.resolve(clazz), entry);
  }

  Future<SourceFile> generate(Iterable<BindingRef> bindingRefs, String entry) {
    final corkCoreUri = Uri.parse('package:cork/cork.dart');
    final corkBindingUri = Uri.parse('package:cork/src/binding/runtime.dart');

    // Start a collection of imports.
    final imports = <ImportDirective> [
      new ImportDirective(corkCoreUri),
      new ImportDirective(corkBindingUri)
    ];

    final fields = <FieldRef> [];
    final methods = <MethodRef> [
      new MethodRef(
          'get',
          methodBody: new Source.fromTemplate(
              "throw new UnsupportedError('{{message}}');", {
                'message': 'Generated injector does not support dynamic get.'
              }),
          positionalArguments: [
            new ParameterRef('_')
          ]
      )
    ];

    var counter = 0;
    final typeToIdMap = <TypeRef, int> {};

    // Dedupe tokens.
    var dedupe = <TypeRef, BindingRef> {};
    for (final ref in bindingRefs) {
      dedupe[ref.tokenRef] = ref;
    }
    bindingRefs = dedupe.values;

    for (final ref in bindingRefs) {
      counter++;
      typeToIdMap[ref.tokenRef] = counter;
    }

    for (final ref in bindingRefs) {
      // Create a field to hold the instance of this type.
      var fieldDef = new FieldRef(
          '_${typeToIdMap[ref.tokenRef]}',
          typeRef: ref.tokenRef);
      fields.add(fieldDef);

      // Create a method to return an existing or create a new type.
      var args = ref.providerRef.dependencies.map((d) {
        var id = typeToIdMap[d];
        return new Source.fromDart('get$id()');
      }).toList(growable: false);
      methods.add(new MethodRef(
          'get${typeToIdMap[ref.tokenRef]}',
          returnTypeRef: ref.tokenRef,
          methodBody: new Source.fromTemplate(r'''
            if ({{field}} == null) {
              {{field}} = {{factory}};
            }
            return {{field}};
          ''', {
            'factory': ref.providerRef.factoryRef.invoke(args).toSource(),
            'field': fieldDef.name,
          })));
    }

    final clazz = new ClassRef(
        '${entry}Injector',
        fields: fields,
        methods: methods,
        implement: const [
          const TypeRef('Injector')
        ]);

    final file = new SourceFile.library(
        'cork.generated.$entry',
        imports: imports..addAll(_analyzer.scopedImports),
        topLevelElements: [clazz]);

    return new Future.value(file);
  }
}
