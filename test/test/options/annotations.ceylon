import org.codejive.ceylon.options { option, Option, PosixArgumentParser, ArgumentParser }
import ceylon.language.meta { optionalAnnotation }
import ceylon.test { test }
import ceylon.language.meta.declaration { ValueDeclaration }

shared class OptionClass(shared String foo, shared String? bar, shared {String*} item, shared String baz="test") {}

shared class OptionClass2() {
	variable shared String foo = "XXX"; // We can't do proper is-required checking in this case
	variable shared String? bar = null;
	variable shared {String*} item = {};
	variable shared String baz = "test";
}

test
shared void createOptionClass() {
	value classDecl = `class OptionClass`;
	//print(optionalAnnotation(`Option`, classDecl));
	//print(classDecl.parameterDeclarations);
	
	
	value posix = PosixArgumentParser(
		void(ArgumentParser.Context ctx, String arg) {
			for (pd in classDecl.parameterDeclarations) {
				// Determine the name of the command line flag
				// that's associated with this parameter
				variable String name = pd.name; 
				if (is ValueDeclaration pd) {
					value opt = optionalAnnotation(`Option`, pd);
					if (exists opt, opt.name.size > 0) {
						name = opt.name;
					}
				} else {
					throw Exception("Function parameters not supported");
				}
				
				// Is it the one we're looking for?
				if (name == arg) {
					if (pd.openType.equals(`Boolean`) && !ctx.pushedArgument exists) {
						ctx.option(name, true);
					} else {
						if (exists val=ctx.next()) {
							ctx.option(name, val);
						} else {
							throw Exception("Missing value for option '``arg``'");
						}
					}
				}
			}
			throw Exception("Unknown option '``arg``'");
		}
	);
	
	value ctx = posix.parse({});
	value ctx2 = posix.parse({"--foo", "fooz"});
}
