library cork.src.generator;

import 'dart:async';

import 'package:analysis/analysis.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:cork/cork.dart';
import 'package:generator/generator.dart';

class StaticBindingGenerator implements Generator<String> {
  final _sourceCrawler = new SourceCrawler();
  final _sourceResolver = new SourceResolver();

  Future<String> generate(Uri uri) {
    var sources = _sourceCrawler.crawl(uri: uri);
    var input = new GeneratorInput(sources, const [Inject]);
    return process(input);
  }

  @override
  Future<String> process(GeneratorInput input) {
    var imports = new StringBuffer();
    imports.writeln('import \'package:cork/src/binding.dart\';');

    var body = new StringBuffer('final staticBindings = [\n');
    var result = input.read();
    var counter = 0;

    result.forEach((ClassDeclaration astNode, lib) {
      // Find the constructor.
      var finder = new _FindClassVisitor();
      astNode.accept(finder);

      // Function name.
      var clazz = finder.classAstNode;

      var uri = _sourceResolver.resolve(lib.path);
      imports.writeln('import \'${uri}\' as import_${++counter};');

      var token = clazz.element.displayName;
      body.writeln('  new Binding(import_$counter.$token, new Provider((_) => new import_$counter.$token(), [])),');
    });


    body.writeln('];');

    return new Future.value('${imports}\n${body}');
  }
}

class _FindClassVisitor extends GeneralizingAstVisitor {
  ClassDeclaration classAstNode;

  @override
  visitClassDeclaration(ClassDeclaration astNode) {
    classAstNode = astNode;
  }
}
