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
native("js")
shared RegExp regExp(
        "The regular expression to be used for all operations"
        String expression,
        "Flags to change the default behaviour"
        RegExpFlag* flags) {
    return RegExpJavascript(expression, *flags);
}

native("js")
shared String quote(String input) {
    return nothing;
}

native("js")
class RegExpJavascript(String expression, RegExpFlag* flags)
        extends RegExp(expression, *flags) {
    shared variable Integer lastIndex = 0;
    
    shared actual Boolean global => flags.contains(package.global);
    shared actual Boolean ignoreCase => flags.contains(package.ignoreCase);
    shared actual Boolean multiLine => flags.contains(package.multiLine);
    
    shared actual MatchResult? find(
        String input) {
        return nothing;
    }
    
    shared actual MatchResult[] findAll(
        String input) {
        return nothing;
    }
    
    shared actual String[] split(
        String input,
        Integer limit) {
        return nothing;
    }
    
    /**
     * Determines if the regular expression matches the given string. This call
     * affects the value returned by {@link #getLastIndex()} if the global flag is
     * set. Equivalent to: {@code exec(input) != null}
     *
     * @param input the string to apply the regular expression to
     * @return whether the regular expression matches the given string.
     */
    shared actual Boolean test(String input) {
        return find(input) exists;
    }
    
    shared actual String replace(
        String input,
        String replacement) {
        return nothing;
    }
}
