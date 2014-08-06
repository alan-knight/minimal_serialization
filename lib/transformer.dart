// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library minimal_serialization_transformer;

import "package:barback/barback.dart";
import "package:analyzer/analyzer.dart";
import "package:path/path.dart" as path;

class MinimalSerializationTransformer extends Transformer {

  get allowedExtensions => ".dart";

  MinimalSerializationTransformer.asPlugin();

  apply(Transform t) {
    return t.readInputAsString(t.primaryInput.id).then((contents) {
        var lib = parseCompilationUnit(contents);
        var classes = lib.declarations.where((x) => x is ClassDeclaration);
        var rules = classes
          .map((each) => new CustomRuleGenerator(each))
          .toList();
        var fileName = path.withoutExtension(t.primaryInput.id.path);
        var newId =
            new AssetId(t.primaryInput.id.package,
                "${fileName}_serialization_rules.dart");
        var id = t.primaryInput.id;
        // Remove the leading /lib on the file name.
        var fileNameInPackage = path.joinAll(path.split(id.path)..removeAt(0));
        var text = '''
// Generated serialization rules
library ${path.basenameWithoutExtension(fileName)}_serialization_rules.dart;

import "package:serialization/serialization.dart";
import "package:${id.package}/${path.basename(id.path)}";

get rules => {
${rules.map((x) => "    '${x.declaration.name}' : new "
    "${x.ruleName}()").join(",\n")}
};

${rules.map((x) => x.rule).join("\n\n")}

''';
        t.addOutput(new Asset.fromString(newId, text));
      });
  }

}

class CustomRuleGenerator {
  ClassDeclaration declaration;
  CustomRuleGenerator(this.declaration);

  get targetName => declaration.name.name;
  get ruleName => targetName + 'SerializationRule';

  get publicFieldNames => declaration.members
      .where((each) => each is FieldDeclaration)
      .expand((x) => x.fields.variables)
      .where((each) => !each.name.name.startsWith("_"))
      .map((each) => each.name.name);

  get header => '''
class $ruleName extends CustomRule {
  bool appliesTo(instance, _) => instance.runtimeType == $targetName;
  create(state) => new $targetName();
  getState(instance) => {
''';

  get fields => publicFieldNames
      .map((field) => "    '$field' : instance.$field").join(",\n");

  get setFields => publicFieldNames
      .map((field) => "    instance.$field = state['$field']").join(";\n");

  get footer => '''};
  void setState($targetName instance, Map state) {
$setFields;
  }
}''';

  get rule => """$header$fields$footer""";
}