library cork.src.generator.class_generator;

import 'dart:async';

import 'package:analysis/analysis.dart';
import 'package:analyzer/analyzer.dart' hide ImportDirective;
import 'package:cork/cork.dart' show Inject;
import 'package:cork/src/analyzer/scope.dart';
import 'package:dart_builder/dart_builder.dart';
import 'package:generator/generator.dart' show Generator, GeneratorInput;

class InjectorClassGenerator implements Generator<SourceFile> {
  final Anthology _anthology;
  final SourceResolver _sourceResolver;

  factory InjectorClassGenerator({SourceResolver resolver}) {
    if (resolver == null) {
      resolver = new SourceResolver();
    }
    var anthology = new Anthology(resolver: resolver);
    return new InjectorClassGenerator._(anthology, resolver);
  }

  InjectorClassGenerator._(this._anthology, this._sourceResolver);

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

    final classes = <ClassRef> [];
    final fields = <FieldRef> [];
    final methods = <MethodRef> [];

    var counter = 0;

    input.read().forEach((ClassDeclaration astNode, sourceLib) {
      counter++;
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
        return new Source.fromDart('a${i + 1}');
      });

      // Create a field to hold the instance of this type.
      var fieldDef = new FieldRef('_$counter', typeRef: classType);
      fields.add(fieldDef);

      // Create a method to return an existing or create a new type.
      var argCounter = 1;
      methods.add(new MethodRef(
          'get$counter',
          returnTypeRef: classType,
          positionalArguments: argTypes.map((type) {
            return new ParameterRef('a${argCounter++}', typeRef: type);
          }).toList(growable: false),
          methodBody: new Source.fromTemplate(r'''
            if ({{field}} == null) {
              {{field}} = {{factory}};
            }
            return {{field}};
          ''', {
            'factory': factory.invoke(args).toSource(),
            'field': fieldDef.name,
            'type': classType.toSource()
          })));
    });

    classes.add(new ClassRef(
        r'$GeneratedInjector',
        fields: fields,
        methods: methods));

    final file = new SourceFile.library(
        'cork_static_class',
        imports: imports..addAll(utils.imports),
        topLevelElements: classes);

    return new Future.value(file);
  }
}
