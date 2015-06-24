library cork.src.generator;

import 'dart:async';

import 'package:analysis/analysis.dart';
import 'package:analyzer/src/generated/ast.dart' hide ImportDirective;
import 'package:cork/src/binding/analyzer.dart';
import 'package:cork/src/binding/static.dart';
import 'package:dart_builder/dart_builder.dart';

class BindingGenerator {
  final StaticBindingAnalyzer _analyzer;
  final Anthology _anthology;

  BindingGenerator(Anthology anthology)
      : _anthology = anthology,
        _analyzer = new StaticBindingAnalyzer(
            new AnthologyAnalysisProvider(anthology));

  Future<SourceFile> process(Uri uri, String entry) {
    ClassDeclaration clazz = _anthology.visit(uri: uri).getDeclaration(entry);
    return generate(_analyzer.resolve(clazz), entry);
  }

  Future<SourceFile> generate(Iterable<BindingRef> bindingRefs, String entry) {
    final corkBindingUri = Uri.parse('package:cork/src/binding/runtime.dart');
    final corkBindingLib = _anthology.visit(uri: corkBindingUri);

    // Find a binding and provider type ref.
    // TODO: Type this and support better with mirrors.
    final bindingTypeRef = _analyzer.scopeType(
        corkBindingLib.getDeclaration('Binding').element.type);
    final providerTypeRef = _analyzer.scopeType(
        corkBindingLib.getDeclaration('Provider').element.type);

    // Start a collection of imports.
    final imports = <ImportDirective> [
      new ImportDirective(corkBindingUri)
    ];

    final bindings = <CallRef> [];

    // Dedupe tokens.
    var dedupe = <TypeRef, BindingRef> {};
    for (final ref in bindingRefs) {
      dedupe[ref.tokenRef] = ref;
    }
    bindingRefs = dedupe.values;

    for (final ref in bindingRefs) {
      var closure = new Source.fromTemplate('(args) => {{factory}}', {
        'factory':
            ref.providerRef.factoryRef.invoke(
                new List.generate(ref.providerRef.dependencies.length,
                    (i) => new Source.fromDart('args[$i]'))).toSource()
      });

      var callRef = new CallRef.constructor(
          bindingTypeRef,
          positionalArguments: [
            ref.tokenRef,
            new CallRef.constructor(
                providerTypeRef,
                positionalArguments: [
                  closure,
                  new ArrayRef(
                      values: ref.providerRef.dependencies,
                      isConst: true)
                ])
          ]);
      bindings.add(callRef);
    }

    final field = new FieldRef(
        'bindingsFor$entry',
        assignment: new ArrayRef(values: bindings, typeRef: bindingTypeRef),
        isFinal: true);

    final file = new SourceFile.library(
        'cork.generated.$entry',
        imports: imports..addAll(_analyzer.calculateImports()),
        topLevelElements: [field]);

    return new Future.value(file);
  }
}
