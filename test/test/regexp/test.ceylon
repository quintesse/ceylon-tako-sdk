import ceylon.test { ... }
import ceylon.test.core {
    DefaultLoggingListener
}
import org.codejive.ceylon.regexp { ... }

shared void run() {
    createTestRunner([`module test.regexp`], [DefaultLoggingListener()]).run();
}

String input = "De aap is uit de (mouw): het was een broodje aap! Ben ik mooi in de aap gelogeerd!";
String expected1 = "MatchResult[3-6 'aap' []]";
String expected2 = "[MatchResult[3-6 'aap' []], MatchResult[45-48 'aap' []], MatchResult[68-71 'aap' []]]";

test
shared void testCreateNoFlags() {
    value re = regExp("");
    assertFalse(re.global);
    assertFalse(re.ignoreCase);
    assertFalse(re.multiLine);
}

test
shared void testCreateWithFlags() {
    value re = regExp("", global, ignoreCase, global, multiLine);
    assertTrue(re.global);
    assertTrue(re.ignoreCase);
    assertTrue(re.multiLine);
}

test
shared void testCreatePatternError() {
    try {
        regExp("\\");
        assertFalse(true, "We shouldn't be here");
    } catch (Exception ex) {
        assertThatException(RegExpException());
    }
}

test
shared void testFind() {
    value result = regExp("a+p").find(input);
    print(result);
    assertEquals(result?.string, expected1);
}

test
shared void testFindGlobal() {
    value result = regExp("a+p", global).find(input);
    print(result);
    assertEquals(result?.string, expected1);
}

test
shared void testFindIgnoreCase() {
    value result = regExp("AAP", ignoreCase).find(input);
    print(result);
    assertEquals(result?.string, expected1);
}

test
shared void testFindAll() {
    value result = regExp("a+p").findAll(input);
    print(result);
    assertEquals(result.string, expected2);
}

test
shared void testFindAllGlobal() {
    value result = regExp("a+p", global).findAll(input);
    print(result);
    assertEquals(result.string, expected2);
}

test
shared void testFindAllGroups() {
    value result = regExp("a+p").findAll(input);
    print(result);
    assertEquals(result.string, expected2);
}

test
shared void testNotFound() {
    value result = regExp("burritos").find(input);
    assertNull(result);
}

test
shared void testQuote() {
    value q = quote("$.*[]^\\");
    print(q);
    assertEquals(q, "\\Q$.*[]^\\\\E");
}

test
shared void testReplace() {
    value result = regExp("aap").replace(input, "noot");
    print(result);
    assertEquals(result, "De noot is uit de (mouw): het was een broodje aap! Ben ik mooi in de aap gelogeerd!");
    value result2 = regExp("[0-9]+ years").replace("90 years old", "very");
    print(result2);
    assertEquals(result2, "very old");
}

test
shared void testReplaceGlobal() {
    value result = regExp("aap", global).replace(input, "noot");
    print(result);
    assertEquals(result, "De noot is uit de (mouw): het was een broodje noot! Ben ik mooi in de noot gelogeerd!");
}

test
shared void testReplaceError() {
    try {
        regExp("aap").replace(input, "$'");
        assertFalse(true, "We shouldn't be here");
    } catch (Exception ex) {
        assertThatException(RegExpException());
    }
}

test
shared void testSplit() {
    value result = regExp(" ", global).split(input);
    print(result);
    assertEquals(result, ["De", "aap", "is", "uit", "de", "(mouw):", "het", "was", "een", "broodje", "aap!", "Ben", "ik", "mooi", "in", "de", "aap", "gelogeerd!"]);
}

test
shared void testTest() {
    assertTrue(regExp("a+p").test(input));
    assertTrue(regExp("^de.*RD!$", ignoreCase).test(input));
    assertTrue(regExp("[0-9]+ years").test("90 years old"));
}

test
shared void testTestQuoted() {
    assertFalse(regExp(" (mouw): ").test(input));
    assertTrue(regExp(quote(" (mouw): ")).test(input));
}

shared void runAll() {
    testCreateNoFlags();
    testCreateWithFlags();
    testCreatePatternError();
    testFind();
    testFindGlobal();
    testFindIgnoreCase();
    testFindAll();
    testFindAllGlobal();
    testFindAllGroups();
    testNotFound();
    testQuote();
    testReplace();
    testReplaceGlobal();
    testReplaceError();
    testSplit();
    testTest();
    testTestQuoted();
}
