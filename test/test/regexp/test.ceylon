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
String expected3 = "[MatchResult[3-6 'aap' [aap]], MatchResult[45-48 'aap' [aap]], MatchResult[68-71 'aap' [aap]]]";
String expected4 = "[MatchResult[0-9 'De aap is' [De, is]], MatchResult[65-81 'de aap gelogeerd' [de, gelogeerd]]]";

test
shared void testCreateNoFlags() {
    value re = regexp("");
    assertFalse(re.global);
    assertFalse(re.ignoreCase);
    assertFalse(re.multiLine);
}

test
shared void testCreateWithFlags() {
    value re = regexp{expression=""; global=true; ignoreCase=true; multiLine=true;};
    assertTrue(re.global);
    assertTrue(re.ignoreCase);
    assertTrue(re.multiLine);
}

test
shared void testCreatePatternError() {
    try {
        regexp("\\");
        assertFalse(true, "We shouldn't be here");
    } catch (Exception ex) {
        assertThatException(ex).hasType(`RegExpException`);
        assertThatException(ex).hasMessage("Problem found within regular expression");
    }
}

test
shared void testFind() {
    value result = regexp{expression="a+p"; global=true;}.find(input);
    print(result);
    assertEquals(result?.string, expected1);
}

test
shared void testFindGlobal() {
    value result = regexp{expression="a+p"; global=true;}.find(input);
    print(result);
    assertEquals(result?.string, expected1);
}

test
shared void testFindIgnoreCase() {
    value result = regexp{expression="AAP"; ignoreCase=true;}.find(input);
    print(result);
    assertEquals(result?.string, expected1);
}

test
shared void testFindAll() {
    value result = regexp("a+p").findAll(input);
    print(result);
    assertEquals(result.string, expected2);
}

test
shared void testFindAllGlobal() {
    value result = regexp{expression="a+p"; global=true;}.findAll(input);
    print(result);
    assertEquals(result.string, expected2);
}

test
shared void testFindAllGroup() {
    value result = regexp("(a+p)").findAll(input);
    print(result);
    assertEquals(result.string, expected3);
}

test
shared void testFindAllGroups() {
    value result = regexp("""(\w+)\saap\s(\w+)""").findAll(input);
    print(result);
    assertEquals(result.string, expected4);
}

test
shared void testNotFound() {
    value result = regexp("burritos").find(input);
    assertNull(result);
}

test
shared void testQuote() {
    value q = quote("""$.*[]^\""");
    assertEquals(q, """\$\.\*\[\]\^\\""");
}

test
shared void testQuote2() {
    value q = quote("""\E\Q\E""");
    print(q);
    assertEquals(q, """\\E\\Q\\E""");
}

test
shared void testReplace() {
    value result = regexp("aap").replace(input, "noot");
    print(result);
    assertEquals(result, "De noot is uit de (mouw): het was een broodje aap! Ben ik mooi in de aap gelogeerd!");
    value result2 = regexp("[0-9]+ years").replace("90 years old", "very");
    print(result2);
    assertEquals(result2, "very old");
}

test
shared void testReplaceGlobal() {
    value result = regexp{expression="aap"; global=true;}.replace(input, "noot");
    print(result);
    assertEquals(result, "De noot is uit de (mouw): het was een broodje noot! Ben ik mooi in de noot gelogeerd!");
}

test native
shared void testReplaceError();

test native("jvm")
shared void testReplaceError() {
    try {
        regexp("aap").replace(input, "$'");
        assertFalse(true, "We shouldn't be here");
    } catch (Exception ex) {
        assertThatException(ex).hasType(`RegExpException`);
        assertThatException(ex).hasMessage("$\` and $' replacements are not supported");
    }
}

test native("js")
shared void testReplaceError() {
}

test
shared void testSplit() {
    value result = regexp{expression=" "; global=true;}.split(input);
    print(result);
    assertEquals(result, ["De", "aap", "is", "uit", "de", "(mouw):", "het", "was", "een", "broodje", "aap!", "Ben", "ik", "mooi", "in", "de", "aap", "gelogeerd!"]);
}

test
shared void testTest() {
    assertTrue(regexp("a+p").test(input));
    assertTrue(regexp{expression="^de.*RD!$"; ignoreCase=true;}.test(input));
    assertTrue(regexp("[0-9]+ years").test("90 years old"));
}

test
shared void testTestQuoted() {
    assertFalse(regexp(" (mouw): ").test(input));
    print(quote(" (mouw): "));
    assertTrue(regexp(quote(" (mouw): ")).test(input));
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
    testFindAllGroup();
    testFindAllGroups();
    testNotFound();
    testQuote();
    testQuote2();
    testReplace();
    testReplaceGlobal();
    testReplaceError();
    testSplit();
    testTest();
    testTestQuoted();
}
