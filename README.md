This provided a minimal transformer that generates CustomRule subclasses
for serialization of Dart struct objects (only public fields required
for serialization, no constructor parameters).

It has now been folded into the general serialization package,
https://pub.dartlang.org/packages/serialization , use that instead.

