import org.codejive.ceylon.options { ... }
import ceylon.test { ... }

test
shared void simpleDIYParserNoArgs() {
	testSimpleDIYParser({""}, false, null, [""], []);
}

test
shared void simpleDIYParserOneParam() {
	testSimpleDIYParser({"foo"}, false, null, ["foo"], []);
}

test
shared void simpleDIYParserShortOptionsAndParams() {
	testSimpleDIYParser({"foo", "-h", "-f", "test.txt", "bar", "--", "baz"}, true, "test.txt", ["foo", "bar"], ["baz"]);
}

test
shared void simpleDIYParserLongOptionsAndParams() {
	testSimpleDIYParser({"foo", "--help", "--file", "test.txt", "bar", "--", "baz"}, true, "test.txt", ["foo", "bar"], ["baz"]);
}

test
shared void simpleParserNoArgs() {
	testSimpleParser({""}, [], [""]);
}

test
shared void simpleParserOneParam() {
	testSimpleParser({"foo"}, [], ["foo"]);
}

test
shared void simpleParserShortOptionsAndParams() {
	testSimpleParser({"foo", "-h", "-f", "test.txt", "bar", "--", "baz"}, ["help"->true, "file"->"test.txt"], ["foo", "bar", "baz"]);
}

test
shared void simpleParserLongOptionsAndParams() {
	testSimpleParser({"foo", "--help", "--file", "test.txt", "bar", "--", "baz"}, ["help"->true, "file"->"test.txt"], ["foo", "bar", "baz"]);
}

// This is just an example of using the basic `ArgumentParser` where
// we still do mostly everything ourselves. The parser just gives us
// the arguments one by one and we check wether we're dealing with
// options or parameters and store them locally.
void testSimpleDIYParser({String*} args, Boolean expHelp, String? expFile, [String*] expParams, [String*] expRest) {
	
	variable Boolean help = false; 
	variable String? file = null;
	variable String[] params = [];
	
	value simple = SimpleArgumentParser(
		void(ArgumentParser.Context ctx, String arg) {
			if (arg == "-h" || arg == "--help") {
				help = true;
			} else if (arg == "-f" || arg == "--file") {
				file = ctx.next();
			} else if (arg == "--") {
				ctx.done();
			} else {
				params = params.withTrailing(arg);
			}
		}
	);
	
	value ctx = simple.parse(args);
	
	assert(help == expHelp);
	assert(testEq(file, expFile));
	assert(params.sequence == expParams);
	assert(ctx.parameters == expRest);
}

// This is just an example of using the basic `ArgumentParser` where
// we still determine ourselves what are options and what are arguments
// but we use the parser's context to store the results
void testSimpleParser({String*} args, [<String->Object>*] expOptions, [String*] expParams) {
	Nothing die(Exception ex) {
		throw ex;
	}
	
	String required(String option, String? val) {
		return val else die(Exception("Missing argument for " + option));
	}
	
	value simple = SimpleArgumentParser(
		void(ArgumentParser.Context ctx, String arg) {
			if (arg == "-h" || arg == "--help") {
				ctx.option("help", true);
			} else if (arg == "-f" || arg == "--file") {
				ctx.option("file", required("file", ctx.next()));
			} else if (arg == "--") {
				ctx.done();
			} else {
				ctx.parameter(arg);
			}
		}
	);
	
	value ctx = simple.parse(args);
	
	assert(ctx.options == expOptions);
	assert(ctx.parameters == expParams);
}