# Minimal Serialization Transformer for Dart

This provides a minimal transformer that generates `CustomRule` subclasses
for serialization of Dart struct objects (only public fields required
for serialization, no constructor parameters). This package works
with the [serialization package][pkg].

For an example of usage, see the [example].

To use, add the following to your pubspec.yaml:

    dependencies:
      minimal_serialization: >= 0.1.2 < 0.2.0
    transformers:
      - minimal_serialization :
        $include: lib/stuff.dart lib/more_stuff.dart
        format: <lists|maps> // If omitted, defaults to lists

For each library 'foo' listed in the $include section this will
generate a `foo_serialization_rules.dart` library with serialization
rules for those classes. Depending on the value of format, those rules
will generate the output as either lists (more efficient) or maps
(easier to read for debugging.) You can use these like:

    import 'package:my_package/stuff_serialization_rules.dart' as foo;
    ...
    var serialization = new Serialization();
    foo.rules.values.forEach(serialization.addRule);

[example]: https://github.com/alan-knight/minimal_serialization_example
[pkg]: https://pub.dartlang.org/packages/serialization
