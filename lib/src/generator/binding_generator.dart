library cork.src.generator;

import 'dart:async';

import 'package:analysis/analysis.dart';
import 'package:analyzer/src/generated/ast.dart' hide ImportDirective;
import 'package:cork/cork.dart';
import 'package:cork/src/analyzer/scope.dart';
import 'package:dart_builder/dart_builder.dart';
import 'package:generator/generator.dart';

class StaticBindingGenerator implements Generator<SourceFile> {
  final Anthology _anthology;
  final SourceResolver _sourceResolver;

  factory StaticBindingGenerator({SourceResolver resolver}) {
    if (resolver == null) {
      resolver = new SourceResolver();
    }
    var anthology = new Anthology(resolver: resolver);
    return new StaticBindingGenerator._(anthology, resolver);
  }

  StaticBindingGenerator._(this._anthology, this._sourceResolver);

  Future<SourceFile> generate(Uri uri) {
    var sources = _anthology.crawl(uri: uri);
    var input = new GeneratorInput(sources, const [Inject]);
    return process(input);
  }

  @override
  Future<SourceFile> process(GeneratorInput input) {
    // Open the cork library to resolve the bindings.
    final corkBindingUri = Uri.parse('package:cork/src/binding.dart');
    final corkBindingLib = _anthology.visit(uri: corkBindingUri);
    final utils = new ScopedAnalyzerUtils.fromAnthology(
        _anthology,
        corkBindingLib);

    // Find a binding and provider type ref.
    // TODO: Type this and support better with mirrors.
    final bindingTypeRef = utils.typeRef(
        corkBindingLib.getDeclaration('Binding').element.type);
    final providerTypeRef = utils.typeRef(
        corkBindingLib.getDeclaration('Provider').element.type);

    // Start a collection of imports.
    final imports = <ImportDirective> [
      new ImportDirective(corkBindingUri)
    ];

    final bindings = <Source> [];

    input.read().forEach((ClassDeclaration astNode, sourceLib) {
      var importUri = _sourceResolver.resolve(sourceLib.path);

      // Create a new unique, namespaced type.
      // TODO: Avoid writing duplicate types.
      var classType = utils.typeRef(astNode.element.type);

      // Create a factory.
      var factory = utils.getConstructor(astNode);

      // Create a new binding.
      // TODO: Temporary. Port provider API.
      var constructor = astNode.getConstructor(null);
      List argTypes = constructor == null
          ? const []
          : utils.getPositionalArgumentTypes(constructor);
      var args = new List.generate(argTypes.length, (i) {
        return new Source.fromTemplate('args[{{i}}]', {'i': i});
      });
      var binding = new InvokeMethod.constructor(
          bindingTypeRef,
          positionalArguments: [
            classType,
            new InvokeMethod.constructor(
                providerTypeRef,
                positionalArguments: [
                  new Source.fromTemplate('(args) => {{factory}}', {
                    'factory': factory.invoke(args).toSource()
                  }),
                  new ArrayRef(isConst: true, values: argTypes)
                ])
          ]);

      bindings.add(binding);
    });

    final array = new ArrayRef(values: bindings, typeRef: bindingTypeRef);
    final file = new SourceFile.library(
        'cork_static_bindings',
        imports: imports..addAll(utils.imports),
        topLevelElements: [
            new FieldDefinition(
                'staticBindings',
                isFinal: true,
                assignment: array)
        ]);

    return new Future.value(file);
  }
}
