
//import fr.epardaud.collections { HashMap }
import java.util { Map, HashMap }

doc "Defines a single command line option"
shared class Option(
        name,
        match,
        docs,
        hasValue=false,
        required=false,
        multiple=false) {
    doc "The name of the option. Can be used to look it up in the result"
    shared String name;
    doc "The literal text used to match the option, usually in the form of
    for example `-f` or `--file`. Multiple possibilitues can be combined
    by using the defined separator (default `|`) like this `-f|--file`.
    If an option has a value it is by default assumed to be the next
    argument in the argument list, but if the matching literal ends with
    the defined separator (default `=`) the value is assumed to have been
    appended to the option itself. An example, the option `--file=` would
    match the argument `--file=filename.txt`"
    shared String match;
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

doc "The result returned by a successful invocation of the `Options.parse()` method"
shared class OptionsResult(
        options,
        arguments) {
    doc "The options that have been found in the argument list"
    shared Map<String, Sequence<String>> options;
    doc "The remaining arguments that are not options"
    shared variable String[] arguments;
    shared actual String string {
        return "OptionsResult(" options ", " arguments ")";
    }
}

doc "The result returned by an unsuccessful invocation of the `Options.parse()` method"
shared class OptionsError(String? initialMessage) {
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
    String matchSeparator = "|";
    String valueSeparator = "=";
    
    doc "Parses the passed arguments looking for options and parameters
    and returns the result into OptionsResult which contains a map of options
    and the remaining arguments or a OptionsError with error messages if
    the arguments could not be parsed correctly"
    shared OptionsResult|OptionsError parse(
            doc "The arguments to parse"
            String[] arguments) {
        // Show a special message if no parameters are passed and
        // a special help message was defined for such a case 
        if (arguments.empty) {
            if (exists noArgsHelp) {
                return OptionsError("" usage?"" "\n" noArgsHelp "");
            }
        }
        
        value optmap = HashMap<String, Sequence<String>>(); 
        value result = OptionsResult(optmap, arguments);
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
    shared OptionsError? validate(OptionsResult result) {
        for (Option opt in options) {
            if (result.options.containsKey(opt.name)) {
            } else {
                if (opt.required) {
                    value err = OptionsError("Option " opt.match " is required");
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
            print("    " opt.match "\t\t" opt.docs "");
        }
    }
    
    OptionsError? parseOpt(OptionsResult result, Sequence<String> args) {
        for (Option opt in options) {
            value matches = opt.match.split((Character c) matchSeparator.contains(c), true);
            for (String match in matches) {
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
                                return OptionsError("Missing value for option " m "");
                            }
                        }
                    } else {
                        // We have an option of the form "-key value"
                        if (args.first == match) {
                            if (nonempty therest=args.rest) {
                                val := therest.first;
                                rest := therest.rest;
                            } else {
                                return OptionsError("Missing value for option " match "");
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
                    if (is OptionsError err) {
                        return err;
                    }
                    result.arguments := rest?{};
                    return null;
                }
            }
        }
        return OptionsError("Unknown option " args.first "");
    }
    
    OptionsError? setOpt(OptionsResult result, Option opt, String val) {
        if (result.options.containsKey(opt.name)) {
            if (opt.multiple) {
                value b = SequenceAppender<String>(result.options.get(opt.name));
                b.append(val);
                result.options.put(opt.name, b.sequence);
            } else {
                return OptionsError("Multiple values not allowed for option " opt.match "");
            }
        } else {
            result.options.put(opt.name, {val});
        }
        return null;
    }
}
