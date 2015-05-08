import ceylon.language.meta.declaration { ClassDeclaration, ValueDeclaration }

"Marks an element as being a test. 
 Only nullary functions should be annotated with `test`."
shared annotation Option option(String name="") => Option(name);

"Annotation class for [[option]]."
shared final annotation class Option(shared String name) satisfies OptionalAnnotation<Option, ClassDeclaration|ValueDeclaration> {}
