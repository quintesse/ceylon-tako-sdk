
import ceylon.collection { MutableMap, HashMap }

doc "Defines a single command line option"
shared class Option(
        name,
        matches,
        docs,
        hasValue=false,
        required=false,
        multiple=false) {
    doc "The name of the option. Can be used to look it up in the result"
    shared String name;
    doc "The literal text used to match the option, usually in the form of
    for example `-f` or `--file`. Multiple possible matches can passed.
    If an option has a value it is by default assumed to be the next
    argument in the argument list, but if the matching literal ends with
    the defined separator (default `=`) the value is assumed to have been
    appended to the option itself. An example, the option `--file=` would
    match the argument `--file=filename.txt`"
    shared Sequence<String> matches;
    doc "A description of the option"
    shared String docs;
    doc "Determines if the option has an associated value"
    shared Boolean hasValue;
    doc "Determines if the option is required or not"
    shared Boolean required;
    doc "Determines if the option can have multiple values or not
    (this means that the option + its value can appear multiple
    times in the argument list)"
    shared Boolean multiple;
}

doc "An easy-to-use parser for command line arguments that takes
a list of Option classes defining the possible options accepted
by the parser and returns a OptionsResult containing a map of
options that were found and their values, as well as the list of
remaining arguments"
shared class Options(
        usage=null,
        noArgsHelp=null,
        Option... _options) {
    doc "Very short text showing how to use the program"
    String? usage;
    doc "Text to show when no arguments are being passed.
    If specified and no arguments are passed this text will
    be printed along with the text defined by `usage` and
    an exit exception will be thrown"
    shared String? noArgsHelp;
    doc "`Option` objects defining all the available options"
    shared Iterable<Option> options = _options;
    
    String optionStart = "-";
    String valueSeparator = "=";

    doc "The result returned by a successful invocation of the `Options.parse()` method"
    shared class Result(
            options,
            arguments) {
        doc "The options that have been found in the argument list"
        shared MutableMap<String, Sequence<String>> options;
        doc "The remaining arguments that are not options"
        shared variable String[] arguments;
        shared actual String string {
            return "OptionsResult(" options ", " arguments ")";
        }
    }
    
    doc "The result returned by an unsuccessful invocation of the `Options.parse()` method"
    shared class Error(String? initialMessage) {
        StringBuilder msgs = StringBuilder();
        
        if (exists initialMessage) {
            msgs.append(initialMessage);
        }
        
        shared void append(String message) {
            msgs.append(message);
            msgs.append("\n");
        }
        shared String messages {
            return msgs.string;
        }
        shared actual String string {
            return "OptionsError(" msgs.string ")";
        }
    }
    
    doc "Parses the passed arguments looking for options and parameters
    and returns the result into OptionsResult which contains a map of options
    and the remaining arguments or a OptionsError with error messages if
    the arguments could not be parsed correctly"
    shared Result|Error parse(
            doc "The arguments to parse"
            String[] arguments) {
        // Show a special message if no parameters are passed and
        // a special help message was defined for such a case 
        if (arguments.empty) {
            if (exists noArgsHelp) {
                return Error("" usage?"" "\n" noArgsHelp "");
            }
        }
        
        value optmap = HashMap<String, Sequence<String>>(); 
        value result = Result(optmap, arguments);
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
    
    doc "Takes a OptionsResult returned by a previous call to `parse()`
    and checks it for further errors"
    shared Error? validate(Result result) {
        for (Option opt in options) {
            if (result.options.defines(opt.name)) {
            } else {
                if (opt.required) {
                    value err = Error("Option " matchesString(opt.matches) " is required");
                    return err;
                }
            }
        }
        return null;
    }
    
    doc "Print usage text"
    shared void printUsage() {
        if (exists usage) {
            print(usage);
        }
    }
    
    doc "Print help text for all options"
    shared void printHelp() {
        for (Option opt in options) {
            print("    " matchesString(opt.matches) "\t\t" opt.docs "");
        }
    }
    
    Error? parseOpt(Result result, Sequence<String> args) {
        for (Option opt in options) {
            for (String match in opt.matches) {
                variable String? val := null;
                variable String[]? rest := null;
                if (opt.hasValue) {
                    if (match.endsWith(valueSeparator)) {
                        // We have an option of the form "-key=value"
                        if (args.first.startsWith(match)) {
                            val := args.first.terminal(args.first.size-match.size);
                            rest := args.rest;
                        } else {
                            String m = match.initial(match.size-1);
                            if (args.first.startsWith(m)) {
                                return Error("Missing value for option " m "");
                            }
                        }
                    } else {
                        // We have an option of the form "-key value"
                        if (args.first == match) {
                            if (nonempty therest=args.rest) {
                                val := therest.first;
                                rest := therest.rest;
                            } else {
                                return Error("Missing value for option " match "");
                            }
                        }
                    }
                } else {
                    if (args.first == match) {
                        val := "true";
                        rest := args.rest;
                    }
                }
                if (exists v=val) {
                    value err = setOpt(result, opt, v);
                    if (is Error err) {
                        return err;
                    }
                    result.arguments := rest?{};
                    return null;
                }
            }
        }
        return Error("Unknown option " args.first "");
    }
    
    Error? setOpt(Result result, Option opt, String val) {
        value curr = result.options[opt.name];
        if (exists curr) {
            if (opt.multiple) {
                value b = SequenceAppender<String>(curr);
                b.append(val);
                result.options.put(opt.name, b.sequence);
            } else {
                return Error("Multiple values not allowed for option " matchesString(opt.matches) "");
            }
        } else {
            result.options.put(opt.name, {val});
        }
        return null;
    }
    
    String matchesString(Sequence<String> matches) {
        if (matches.size == 1) {
            return matches.first;
        } else if (matches.size == 2) {
            assert(nonempty rest=matches.rest);
            return "" matches.first " or " rest.first "";
        } else {
            assert(nonempty rest=matches.rest);
            return "" matches.first ", " matchesString(rest) "";
        }
    }
}
