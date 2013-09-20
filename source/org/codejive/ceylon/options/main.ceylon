
import ceylon.collection { HashMap }

"Defines a single command line option"
shared class Option(
        name,
        matches,
        docs,
        hasValue=false,
        hasOptionalValue=false,
        defaultOptionalValue="true",
        required=false,
        multiple=false) {
    "The name of the option. Can be used to look it up in the result"
    shared String name;
    "The list of possible options strings, usually in the form of
     for example `f` or `file`.
         
     There's a distinction between 'short form' options (single letter options)
     and 'long form' options (more than a single letter, normally entire words);
     short forms are preceded by a single dash and are case sensitive while long
     forms are preceded by a double dash and are case insensitive (eg. `-f` and
     `-F` are different options while `--file` and `--FILE` are the same)."
    shared Sequence<String> matches;
    "A description of the option"
    shared String docs;
    "Determines if the option has an associated required value (default `false`).
     Options with required values are free to use the two forms of
     specifying a value: as the next argument or appended to
     the option itself with an equals sign
     (eg. either `--file filename.txt` or `--file=filename.txt`)"
    shared Boolean hasValue;
    "Determines if the option has an associated optional value (default `false`).
     Options with optional values either have no value at all
     or they *must* have a value that is appended to the option
     itself using an equals sign
     (eg. either `--verbose` or `--verbose=info`)"
    shared Boolean hasOptionalValue;
    "The value that will be used for an option that required no value
     or for an optional value that has been left empty (default `\"true\"`)"
    shared String defaultOptionalValue;
    "Determines if the option is required or not (default `false`)"
    shared Boolean required;
    "Determines if the option can have multiple values or not
         (this means that the option + its value can appear multiple
         times in the argument list, default `false`)"
    shared Boolean multiple;
}

"An easy-to-use parser for command line arguments that takes
 a list of [[Option]] classes defining the possible options accepted
 by the parser and returns a [[OptionsResult]] containing a map of
 options that were found and their values, as well as the list of
 remaining arguments. Or in the case of an error it will return an
 [[Error]] containing a list of problem descriptions."
shared class Options(
        usage=null,
        noArgsHelp=null,
        options=[]) {
    "Very short text showing how to use the program"
    String? usage;
    "Text to show when no arguments are being passed.
     If specified and no arguments are passed this text will
     be printed along with the text defined by `usage` and
     an exit exception will be thrown"
    shared String? noArgsHelp;
    "`Option` objects defining all the available options"
    shared Option* options;
    
    String optionStart = "-";
    String valueSeparator = "=";

    "The result returned by a successful invocation of the `Options.parse()` method"
    shared abstract class Result() {
        "The options that have been found in the argument list"
        shared formal Map<String, Sequence<String>> options;
        "The remaining arguments that are not options"
        shared formal variable String[] arguments;
        shared actual String string {
            return "Result(``options``, ``arguments``)";
        }
    }
    
    class InternalResult(options, arguments) extends Result() {
        shared actual HashMap<String, Sequence<String>> options;
        shared actual variable String[] arguments;
    }
    
    "The result returned by an unsuccessful invocation of the `Options.parse()` method"
    shared abstract class Error() {
        shared formal String[] messages;
        shared actual String string {
            return "Error(``messages``)";
        }
    }
    
    "The result returned by an unsuccessful invocation of the `Options.parse()` method"
    class InternalError(String? initialMessage) extends Error() {
        value msgs = SequenceBuilder<String>();
        
        if (exists initialMessage) {
            msgs.append(initialMessage);
        }
        
        shared void append(String message) {
            msgs.append(message);
        }
        shared actual String[] messages {
            return msgs.sequence;
        }
    }
    
    "Parses the passed arguments looking for options and parameters
     and returns the result into OptionsResult which contains a map of options
     and the remaining arguments or a OptionsError with error messages if
     the arguments could not be parsed correctly"
    shared Result|Error parse(
            "The arguments to parse"
            String[] arguments) {
        // Show a special message if no parameters are passed and
        // a special help message was defined for such a case 
        if (arguments.empty) {
            if (exists noArgsHelp) {
                return InternalError("``usage else ""``\n``noArgsHelp``");
            }
        }
        
        value optmap = HashMap<String, Sequence<String>>(); 
        value result = InternalResult(optmap, arguments);
        while (nonempty args=result.arguments) {
            if (args.first.startsWith(optionStart)) {
                value err = parseOpt(result, args);
                if (exists err) {
                    return err;
                }
            } else {
                break;
            }
        }
        
        return result;
    }
    
    "Takes a OptionsResult returned by a previous call to `parse()`
     and checks it for further errors"
    shared Error? validate(Result result) {
        for (Option opt in options) {
            if (result.options.defines(opt.name)) {
            } else {
                if (opt.required) {
                    value err = InternalError("Option ``matchesString(opt.matches)`` is required");
                    return err;
                }
            }
        }
        return null;
    }
    
    "Print usage text"
    shared void printUsage() {
        if (exists usage) {
            print(usage);
        }
    }
    
    "Print help text for all options"
    shared void printHelp() {
        for (Option opt in options) {
            print("    ``matchesString(opt.matches)``\t\t``opt.docs``");
        }
    }
    
    Error? parseOpt(InternalResult result, Sequence<String> args) {
        for (Option opt in options) {
            for (String match in opt.matches) {
                String actualMatch = matchString(match);
                String matchArg = (match.size == 1) then args.first else args.first.lowercased;
                variable String? val = null;
                variable String[]? rest = null;
                if ((!opt.hasValue || opt.hasOptionalValue) && matchArg == actualMatch) {
                    val = opt.defaultOptionalValue;
                    rest = args.rest;
                } else if (opt.hasValue || opt.hasOptionalValue) {
                    String actualMatchJoined = actualMatch + valueSeparator;
                    if (matchArg == actualMatch) {
                        // We have an option of the form "-k value" or "--key value"
                        if (nonempty therest=args.rest) {
                            val = therest.first;
                            rest = therest.rest;
                        } else {
                            return InternalError("Missing value for option ``actualMatch``");
                        }
                    } else if (args.first.startsWith(actualMatchJoined)) {
                        // We have an option of the form "-k=value" or  "--key=value"
                        val = args.first.terminal(args.first.size-actualMatchJoined.size);
                        rest = args.rest;
                    }
                }
                if (exists v=val) {
                    value err = setOpt(result, opt, v);
                    if (is Error err) {
                        return err;
                    }
                    result.arguments = rest else {};
                    return null;
                }
            }
        }
        return InternalError("Unknown option ``args.first``");
    }
    
    Error? setOpt(InternalResult result, Option opt, String val) {
        value curr = result.options[opt.name];
        if (exists curr) {
            if (opt.multiple) {
                value b = SequenceAppender<String>(curr);
                b.append(val);
                result.options.put(opt.name, b.sequence);
            } else {
                return InternalError("Multiple values not allowed for option ``matchesString(opt.matches)``");
            }
        } else {
            result.options.put(opt.name, [val]);
        }
        return null;
    }
    
    String matchesString(Sequence<String> matches) {
        if (matches.size == 1) {
            return matchString(matches.first);
        } else if (matches.size == 2) {
            assert(nonempty rest=matches.rest);
            return matchString(matches.first) + " or " + matchString(rest.first);
        } else {
            assert(nonempty rest=matches.rest);
            return matchString(matches.first) + ", " + matchesString(rest);
        }
    }
    
    String matchString(String match) {
        if (match.size == 1) {
            return optionStart + match;
        } else {
            return optionStart + optionStart + match;
        }
    }
}
