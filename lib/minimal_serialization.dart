// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library minimal_serialization_transformer;

import "package:barback/barback.dart";
import "package:analyzer/analyzer.dart";
import "package:path/path.dart" as path;

/// A transformer for generating serialization rules. Usage is as follows.
/// In your pubpsec
///      transformers:
///        - minimal_serialization :
///          $include: lib/stuff.dart lib/more_stuff.dart
///          format: <lists|maps> // If omitted, defaults to lists
/// For each library 'foo' listed in the $include section this will
/// generate a 'foo\_serialization\_rules.dart' library with serialization
/// rules for those classes. Depending on the value of format, those rules
/// will generate the output as either lists (more efficient) or maps
/// (easier to read for debugging.) You can use these like
///       import 'package:my_package/stuff_serialization_rules.dart' as foo;
///       ...
///       var serialization = new Serialization();
///       foo.rules.values.forEach(serialization.addRule);
/// For an example, see package minimal\_serialization\_example
class MinimalSerializationTransformer extends Transformer {
  BarbackSettings _settings;

  get allowedExtensions => ".dart";

  MinimalSerializationTransformer.asPlugin(this._settings);

  apply(Transform t) {
    return t.readInputAsString(t.primaryInput.id).then((contents) {
        var lib = parseCompilationUnit(contents);
        var classes = lib.declarations.where((x) => x is ClassDeclaration);
        var rules = classes
          .map((each) => new CustomRuleGenerator(each,
              _settings.configuration['format']))
          .toList();
        var fileName = path.withoutExtension(t.primaryInput.id.path);
        var newId =
            new AssetId(t.primaryInput.id.package,
                "${fileName}_serialization_rules.dart");
        var id = t.primaryInput.id;
        // Remove the leading /lib on the file name.
        var fileNameInPackage = path.joinAll(path.split(id.path)..removeAt(0));
        var text = '''
// Generated serialization rules. *** DO NOT EDIT ***
// See package minimal_serialization.
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

/// Generates serialization rules for a class.
// TODO(alanknight): Generalize to be able to to handle more complex
// cases similarly to BasicRule in package:serialization.
class CustomRuleGenerator {
  ClassDeclaration declaration;
  String _format;
  List<String> publicFieldNames;

  CustomRuleGenerator(this.declaration, this._format) {
    publicFieldNames = declaration.members
      .where((each) => each is FieldDeclaration)
      .expand((x) => x.fields.variables)
      .where((each) => !each.name.name.startsWith("_"))
      .map((each) => each.name.name)
      .toList();
  }

  get listFormat => _format == null || _format == 'lists';
  get collectionStart => listFormat ? '[' : '{';
  get collectionEnd => listFormat ? ']' : '}';
  nameInQuotes(field) => listFormat ? '' : "'$field' : ";
  deref(field) => listFormat ? publicFieldNames.indexOf(field) : "'$field'";

  get targetName => declaration.name.name;
  get ruleName => targetName + 'SerializationRule';

  get header => '''
class $ruleName extends CustomRule {
  bool appliesTo(instance, _) => instance.runtimeType == $targetName;
  create(state) => new $targetName();
  getState(instance) => $collectionStart
''';

  get fields => publicFieldNames
      .map((field) => "    ${nameInQuotes(field)}instance.$field").join(",\n");

  get setFields => publicFieldNames
      .map((field) =>
          "    instance.$field = state[${deref(field)}]").join(";\n");

  get footer => '''$collectionEnd;
  void setState($targetName instance, state) {
$setFields;
  }
}''';

  get rule => """$header$fields$footer""";
}