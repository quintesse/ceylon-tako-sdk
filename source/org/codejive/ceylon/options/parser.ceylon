
import ceylon.collection { ArrayList }

shared abstract class ArgumentParser() {
    
    shared default class Context({String*} arguments) {
        Iterator<String> args = arguments.iterator();
        variable value stop = false;
        shared variable String? pushedArgument = null;
        value opts = ArrayList<String->Object>();
        value params = ArrayList<String>();
        
        shared default String? next() {
            if (!stop) {
                if (exists arg=pushedArgument) {
                    pushedArgument = null;
                    return arg;
                }
                String|Finished item = args.next();
                if (is String item) {
                    return item;
                }
            }
            return null;
        }
        
        shared Context option(String name, Object val) {
            opts.add(name->val);
            return this;
        }
        
        shared Context parameter(String val) {
            params.add(val);
            return this;
        }
        
        shared [<String->Object>*] options {
            return opts.sequence();
        }
        
        shared [String*] parameters {
            return params.sequence();
        }
        
        shared Context done() {
            while (exists n=next()) {
                parameter(n);
            }
            stop = true;
            return this;
        }
        
        shared Boolean stopped => stop;
    }
    
    shared Context parse({String*} arguments) {
        value ctx = Context(arguments);
        while (!ctx.stopped, is String a = ctx.next()) {
            parseArgument(ctx, a);
        }
        return ctx;
    }
    
    shared formal void parseArgument(Context ctx, String argument);
}

shared class SimpleArgumentParser(Anything(ArgumentParser.Context, String) onArgument) extends ArgumentParser() {
    shared actual void parseArgument(Context ctx, String argument) {
        onArgument(ctx, argument);
    }
}

shared class PosixArgumentParser(
            Anything onOption(ArgumentParser.Context ctx, String arg)
                    => ctx.option(arg, ctx.pushedArgument else arg),
            Anything onParameter(ArgumentParser.Context ctx, String arg)
                    => ctx.parameter(arg),
            Boolean doubleDashEndsParsing=true,
            Boolean allowCombinedShortArguments=false)
        extends ArgumentParser() {
    
    shared actual void parseArgument(ArgumentParser.Context ctx, String argument) {
        if (doubleDashEndsParsing && argument == "--") {
            ctx.done();
        } else if (argument.size > 2 && argument.startsWith("--")) {
            value p = argument.firstOccurrence('=');
            if (exists p, p > 2) {
                // Option of form --foo=VALUE
                String arg = argument.span(2, p - 1);
                String val = argument.spanFrom(p + 1);
                ctx.pushedArgument = val;
                onOption(ctx, arg);
                ctx.pushedArgument = null;
            } else {
                // Option of form --foo
                onOption(ctx, argument.spanFrom(2));
            }
        } else if (argument.size > 1 && argument.startsWith("-")) {
            if (allowCombinedShortArguments) {
                // Contains one or more short options like -x or -xT3dvMKoz
                for (c in argument.skip(1)) {
                    onOption(ctx, c.string);
                }
            } else {
                String arg = argument.span(1, 1);
                if (argument.size > 2) {
                    // Option of form -xVALUE
                    String val = argument.spanFrom(2);
                    ctx.pushedArgument = val;
                    onOption(ctx, arg);
                    ctx.pushedArgument = null;
                } else {
                    // Option of form -x
                    onOption(ctx, arg);
                }
            }
        } else {
            // Non-option arguments are collected here
            onParameter(ctx, argument);
        }
    }
    
}