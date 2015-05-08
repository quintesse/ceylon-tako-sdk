
import ceylon.test { ... }
import ceylon.test.core {
    DefaultLoggingListener
}

void run() {
    createTestRunner([`module test.options`], [DefaultLoggingListener()]).run();
}

Boolean testEq(Object? o1, Object? o2) {
    if (exists o1, exists o2, o1 == o2) {
        return true;
    } else {
        return o1 exists == o2 exists;
    }
}
