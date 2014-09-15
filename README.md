This provides a minimal transformer that generates CustomRule subclasses
for serialization of Dart struct objects (only public fields required
for serialization, no constructor parameters).

For an example of usage, see 
http://www.dartdocs.org/documentation/minimal_serialization_example/latest

Basic usage is 
In your pubpsec
      transformers:
        - minimal_serialization :
          $include: lib/stuff.dart lib/more_stuff.dart
 For each library 'foo' listed in the $include section this will
 generate a 'foo_serialization_rules.dart' library with serialization
 rules for those classes. You can use these like
       import 'package:my_package/stuff_serialization_rules.dart' as foo;
       ...
       var serialization = new Serialization();
       foo.rules.values.forEach(serialization.addRule);
