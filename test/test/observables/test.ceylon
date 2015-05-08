import ceylon.test { ... }
import ceylon.test.core {
    DefaultLoggingListener
}
import org.codejive.ceylon.observables { ... }

shared void run() {
    createTestRunner([`module test.observables`], [DefaultLoggingListener()]).run();
}

Observable<Integer> ints = observables.fromIterable(0 : 10);
Observable<String?> strings = observables.fromIterable(["aap", null, "noot", "mies", null]);

test
shared void testAny() {
    ints.any(Integer.even).subscribe(print);
    ints.any(13.equals).subscribe(print);
}

test
shared void testBy() {
    ints.by(3).subscribe(print);
}

test
shared void testDefaultNullElements() {
    strings.defaultNullElements("foobar").subscribe(print);
}

test
shared void testCoalesced() {
    strings.coalesced.subscribe(print);
}

test
shared void testContains() {
    strings.contains("noot").subscribe(print);
}

test
shared void testCount() {
    strings.count((e) => !e exists).subscribe(print);
}

test
shared void testEach() {
    strings.each(print);
}

test
shared void testEmpty() {
    strings.empty.subscribe(print);
    observables.empty.empty.subscribe(print);
}

test
shared void testEvery() {
    ints.every(Integer.even).subscribe(print);
    ints.every(0.notLargerThan).subscribe(print);
}

test
shared void testExceptLast() {
    ints.exceptLast.subscribe(print);
}

test
shared void testFilter() {
    ints.filter(Integer.even).subscribe(print);
}

test
shared void testFind() {
    ints.find(5.smallerThan).subscribe(print);
}

test
shared void testFindLast() {
    ints.findLast(3.divides).subscribe(print);
}

test
shared void testFirst() {
    strings.first.subscribe(print);
}

test
shared void testIndexed() {
    strings.indexed.subscribe(print);
}

test
shared void testMap() {
    ints.map(2.power).subscribe(print);
}

test
shared void testSubscribe() {
    strings.subscribe(print, print, () => print("The End."), () => print("Starting..."));
}

shared void runAll() {
    testAny();
    testBy();
    testDefaultNullElements();
    testCoalesced();
    testContains();
    testCount();
    testEach();
    testEmpty();
    testEvery();
    testExceptLast();
    testFilter();
    testFind();
    testFindLast();
    testFirst();
    testIndexed();
    testMap();
    testSubscribe();
}
