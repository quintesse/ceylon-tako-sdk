import org.codejive.ceylon.options { ... }
import ceylon.test { ... }

test
shared void posixDIYParserNoArgs() {
	testPosixDIYParser({""}, false, null, [""], []);
}

test
shared void posixDIYParserOneParam() {
	testPosixDIYParser({"foo"}, false, null, ["foo"], []);
}

test
shared void posixDIYParserShortOptionsAndParams() {
	testPosixDIYParser({"foo", "-h", "-f", "test.txt", "bar", "--", "baz", "--unknown"}, true, "test.txt", ["foo", "bar"], ["baz", "--unknown"]);
}

test
shared void posixDIYParserLongOptionsAndParams() {
	testPosixDIYParser({"foo", "--help", "--file", "test.txt", "bar", "--", "baz", "--unknown"}, true, "test.txt", ["foo", "bar"], ["baz", "--unknown"]);
}

test
shared void posixDIYParserUnknownOption() {
	testPosixDIYParser({"foo", "-h", "-f", "test.txt", "bar", "--unknown", "--", "baz"}, true, "", [], [], Exception("Unknown option unknown"));
}

test
shared void posixParserNoArgs() {
	testPosixParser({""}, false, [], [""]);
}

test
shared void posixParserOneParam() {
	testPosixParser({"foo"}, false, [], ["foo"]);
}

test
shared void posixParserShortOptionsAndParams() {
	testPosixParser({"foo", "-h", "-f", "test.txt", "bar", "--", "baz", "-x"}, false, ["help"->true, "file"->"test.txt"], ["foo", "bar", "baz", "-x"]);
}

test
shared void posixParserLongOptionsAndParams() {
	testPosixParser({"foo", "--help", "--file", "test.txt", "bar", "--", "baz", "--unknown"}, false, ["help"->true, "file"->"test.txt"], ["foo", "bar", "baz", "--unknown"]);
}

test
shared void posixParserUnknownOption() {
	testPosixParser({"foo", "-h", "-f", "test.txt", "bar", "--unknown", "--", "baz"}, false, [], [], Exception("Unknown option unknown"));
}

test
shared void posixParserShortOptionsCombined1() {
	testPosixParser({"-ffh", "test.txt", "bar"}, true, ["file"->"test.txt", "file"->"bar", "help"->true], []);
}

test
shared void posixParserShortOptionsCombined2() {
	testPosixParser({"-ffh", "test.txt", "bar"}, false, ["file"->"fh"], ["test.txt", "bar"]);
}

test
shared void posixDefaultParserNoArgs() {
	testPosixDefaultParser({""}, [], [""]);
}

test
shared void posixDefaultParserOneParam() {
	testPosixDefaultParser({"foo"}, [], ["foo"]);
}

test
shared void posixDefaultParserShortOptionsAndParams() {
	testPosixDefaultParser({"foo", "-h", "-ftest.txt", "bar", "--", "baz", "-x"}, ["h"->"h", "f"->"test.txt"], ["foo", "bar", "baz", "-x"]);
}

test
shared void posixDefaultParserLongOptionsAndParams() {
	testPosixDefaultParser({"foo", "--help", "--file=test.txt", "bar", "--", "baz", "--unknown"}, ["help"->"help", "file"->"test.txt"], ["foo", "bar", "baz", "--unknown"]);
}

// This is an example of using the `PosixArgumentParser` where
// the parser determines what are options and what are parameters
// and passes them to the handling functions one by one. We still
// store the results locally ourselves.
void testPosixDIYParser({String*} args, Boolean expHelp, String? expFile, [String*] expParams, [String*] expRest, Exception? expEx = null) {
	
	variable Boolean help = false; 
	variable String? file = null;
	variable String[] params = [];
	
	value posix = PosixArgumentParser(
		void(ArgumentParser.Context ctx, String arg) {
			if (arg == "h" || arg == "help") {
				help = true;
			} else if (arg == "f" || arg == "file") {
				file = ctx.next();
			} else {
				throw Exception("Unknown option " + arg);
			}
		},
		void(ArgumentParser.Context ctx, String arg) {
			params = params.withTrailing(arg);
		}
	);
	
	try {
		value ctx = posix.parse(args);
		
		assert(help == expHelp);
		assert(testEq(file, expFile));
		assert(params.sequence == expParams);
		assert(ctx.parameters == expRest);
	} catch (Exception ex) {
		if (exists expEx) {
			assert(ex.string == expEx.string);
		} else {
			throw ex;
		}
	}
}

// This is an example of using the `PosixArgumentParser` where
// the parser determines what are options and what are parameters
// and passes them to the handling functions one by one but we use
// the parser's context to store the results
void testPosixParser({String*} args, Boolean combinedOpts, [<String->Object>*] expOptions, [String*] expParams, Exception? expEx = null) {
	Nothing die(Exception ex) {
		throw ex;
	}
	
	String required(String option, String? val) {
		return val else die(Exception("Missing argument for " + option));
	}
	
	value posix = PosixArgumentParser {
		void onOption(ArgumentParser.Context ctx, String arg) {
			if (arg == "h" || arg == "help") {
				ctx.option("help", true);
			} else if (arg == "f" || arg == "file") {
				ctx.option("file", required("file", ctx.next()));
			} else {
				throw Exception("Unknown option " + arg);
			}
		}
		allowCombinedShortArguments = combinedOpts;
	};
	
	try {
		value ctx = posix.parse(args);
		
		assert(ctx.options == expOptions);
		assert(ctx.parameters == expParams);
	} catch (Exception ex) {
		if (exists expEx) {
			assert(ex.string == expEx.string);
		} else {
			throw ex;
		}
	}
}

// This is an example of using the `PosixArgumentParser` where
// we leave everything to the parser. It determines what are
// options and what are parameters and stores them in the context.
// This is the least work to set up but any validation of arguments
// and values will have to be performed as a separate step after
// parsing has finished.
void testPosixDefaultParser({String*} args, [<String->Object>*] expOptions, [String*] expParams) {
	
	value posix = PosixArgumentParser();
	
	value ctx = posix.parse(args);
	
	assert(ctx.options == expOptions);
	assert(ctx.parameters == expParams);
}