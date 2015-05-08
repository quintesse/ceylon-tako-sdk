/*
 * Copyright 2010 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not
 * use this file except in compliance with the License. You may obtain a copy of
 * the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 * License for the specific language governing permissions and limitations under
 * the License.
 */

"Factory method that returns an initialized [[RegExp]] object
 for the current backend. See the documentation for the `RegExp`
 object itself for more information.
 "
shared native RegExp regExp(
        "The regular expression to be used for all operations"
        String expression,
        "Flags to change the default behaviour"
        RegExpFlag* flags);

shared interface RegExpFlag
        of global, ignoreCase, multiLine { }
shared object global satisfies RegExpFlag {}
shared object ignoreCase satisfies RegExpFlag {}
shared object multiLine satisfies RegExpFlag {}

"""This method produces a `String` that can be used to create a
   `RegExp` that would match the string as if it were a literal
   pattern. Metacharacters or escape sequences in the input sequence
   will be given no special meaning.
   """
shared native String quote(
    "The string to be literalized"
    String input);

"""A class for cross-platform regular expressions modeled on Javascript's
   `RegExp`, plus some extra methods like Java's and Javascript `String`'s
   `replace` and `split` methods (taking a `RegExp` parameter) that are missing
   from Ceylon's version of [[String]].
   
   Example usage:
   
       value re = RegExp("[0-9]+ years");
       assert(re.test("90 years old"));
       print(re.replace("90 years old", "very"));
       
    There are a few small incompatibilities between the two implementations.
   Java-specific constructs in the regular expression syntax (e.g. [a-z&&[^bc]],
   (?<=foo), \A, \Q) work only on the JVM backend, while the Javascript-specific
   constructs $` and $' in the replacement expression work only on the Javascript
   backend, not the JVM backend, which rejects them. There are also sure to
   exist small differences between the different browser implementations,
   be sure to test thoroughly, especially when using more advanced features.
   """
shared sealed abstract class RegExp(expression, flags) {
    "The regular expression to be used for all operations"
    shared String expression;
    "Flags to change the default behaviour"
    RegExpFlag* flags;
    
    shared formal Boolean global;
    shared formal Boolean ignoreCase;
    shared formal Boolean multiLine;
    
    """Applies the regular expression to the given string. This call affects the
       value returned by {@link #getLastIndex()} if the global flag is set.
       Produces a [[match result|MatchResult]] if the string matches, else `null`.
       """
    shared formal MatchResult? find(
            "the string to apply the regular expression to"
            String input);
    
    """Applies the regular expression to the given string. Produces a sequence
       of [[match result|MatchResult]] containing all matches, or [[Empty]]
       if there was no match.
       """
    shared formal MatchResult[] findAll(
            "the string to apply the regular expression to"
            String input);
    
    """Splits the input string around matches of the regular expression. If the
       regular expression is completely empty, splits the input string into its
       constituent characters. If the regular expression is not empty but matches
       an empty string, the results are not well defined.
       
       Note: There are some browser inconsistencies with this implementation, as
       it is delegated to the browser, and no browser follows the spec completely.
       A major difference is that IE will exclude empty strings in the result.
       """
    shared formal String[] split(
            "the string to be split"
            String input,
            "the maximum number of strings to split off and return,
             ignoring the rest of the input string.
             If negative, there is no limit"
            Integer limit=-1);
    
    /**
     * Determines if the regular expression matches the given string. This call
     * affects the value returned by {@link #getLastIndex()} if the global flag is
     * set. Equivalent to: {@code exec(input) != null}
     *
     * @param input the string to apply the regular expression to
     * @return whether the regular expression matches the given string.
     */
    shared formal Boolean test(String input);
    
    """Returns the input string with the part(s) matching the regular expression
       replaced with the replacement string. If the global flag is set, replaces
       all matches of the regular expression. Otherwise, replaces the first match
       of the regular expression. As per Javascript semantics, backslashes in the
       replacement string get no special treatment, but the replacement string can
       use the following special patterns:
       
        - `$1`, `$2`, ... `$99` - inserts the n'th group matched by the regular
       expression.
        - `$&` - inserts the entire string matched by the regular expression.
        - `$$` - inserts a $.
       
       Note: "$`" and "$'" are *not* supported in the pure Java implementation,
       and throw an exception.
       """
    shared formal String replace(
            "the string in which the regular expression is to be searched"
            String input,
            "the replacement string"
            String replacement);
}

"The result of a call to [[RegExp.find]]"
shared class MatchResult(start, end, matched, groups) {
    "The zero-based index of the match in the input string"
    shared Integer start;
    "The zero-based index after the match in the input string"
    shared Integer end;
    "The matched string"
    shared String matched;
    "A sequence of matched groups or [[Empty]]"
    shared String[] groups;
    
    shared actual String string => "MatchResult[``start``-``end`` '``matched``' ``groups``]";
}

shared class RegExpException(String? description=null, Throwable? cause=null)
        extends Exception(description, cause) {}
