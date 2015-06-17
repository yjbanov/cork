library cork.src.generator;

import 'dart:async';

import 'package:analysis/analysis.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:cork/cork.dart';
import 'package:generator/generator.dart';

class StaticBindingGenerator implements Generator<String> {
  final _sourceCrawler = new SourceCrawler();
  final SourceResolver _sourceResolver;

  StaticBindingGenerator({SourceResolver resolver}) :
      _sourceResolver = resolver != null ? resolver : new SourceResolver();

  Future<String> generate(Uri uri) {
    var sources = _sourceCrawler.crawl(uri: uri);
    var input = new GeneratorInput(sources, const [Inject]);
    return process(input);
  }

  @override
  Future<String> process(GeneratorInput input) {
    var imports = <DartImport> [];
    var lines = <GeneratedDartCode> [];
    var file = new DartFile(imports: imports, lines: lines);
    imports.add(new DartImport('package:cork/src/binding.dart'));

    var bindings = <GeneratedDartCode> [];
    lines.add(new DartVariableDefinition(
        'staticBindings',
        isFinal: true,
        assignTo: new DartArray(bindings)));

    var result = input.read();
    var counter = 0;

    result.forEach((ClassDeclaration astNode, lib) {
      // Find the constructor.
      var finder = new _FindClassVisitor();
      astNode.accept(finder);

      // Function name.
      var clazz = finder.classAstNode;

      var uri = _sourceResolver.resolve(lib.path);
      imports.add(new DartImport(uri.toString(), as: 'import_${++counter}'));

      var token = clazz.element.displayName;
      bindings.add(
          new DartInvokeConstructor(
              'Binding',
              positionalArguments: [
                new DartIdentifier('import_$counter.$token'),
                new DartInvokeConstructor(
                  'Provider',
                  positionalArguments: [
                    new DartIdentifier(
                      '(_) => new import_$counter.$token()'
                    ),
                    new DartArray.constant()
                  ]
                )
              ]));
    });

    return new Future.value(
        'library cork_static_bindings;\n\n' + file.toSource());
  }
}

class StaticClassGenerator implements Generator<String> {
  final _sourceCrawler = new SourceCrawler();
  final SourceResolver _sourceResolver;

  StaticClassGenerator({SourceResolver resolver}) :
      _sourceResolver = resolver != null ? resolver : new SourceResolver();

  Future<String> generate(Uri uri) {
    var sources = _sourceCrawler.crawl(uri: uri);
    var input = new GeneratorInput(sources, const [Inject]);
    return process(input);
  }

  @override
  Future<String> process(GeneratorInput input) {
    var imports = <DartImport> [];
    var lines = <GeneratedDartCode> [];
    var file = new DartFile(imports: imports, lines: lines);

    var buffer = new StringBuffer(r'class $GeneratedInjector {');
    var result = input.read();
    var counter = 0;

    result.forEach((ClassDeclaration astNode, lib) {
      // Find the constructor.
      var finder = new _FindClassVisitor();
      astNode.accept(finder);

      // Function name.
      var clazz = finder.classAstNode;

      var uri = _sourceResolver.resolve(lib.path);
      imports.add(new DartImport(uri.toString(), as: 'import_${++counter}'));

      var token = clazz.element.displayName;
      buffer.writeln('import_$counter.$token _$counter;');
      buffer.writeln('import_$counter.$token get$counter () {');
      buffer.write('''
        if (_$counter == null) {
          _$counter = new import_$counter.$token();
        }
        return _$counter;
      ''');
      buffer.writeln('}');
    });

    buffer.writeln('}');

    lines.add(new DartIdentifier(buffer.toString()));

    return new Future.value(
        'library cork_static_class;\n\n' + file.toSource());
  }
}

class _FindClassVisitor extends GeneralizingAstVisitor {
  ClassDeclaration classAstNode;

  @override
  visitClassDeclaration(ClassDeclaration astNode) {
    classAstNode = astNode;
  }
}
