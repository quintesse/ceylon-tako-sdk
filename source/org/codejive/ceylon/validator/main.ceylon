
"Base interface that must be implemented by all validators"
shared interface Validator<VAL> {
    "Determines if the value being passed is valid according to the rules set by the validator"
    shared formal Boolean validated(VAL val);
}

"A validator that checks a value against a sepecified minimum"
shared class MinValidator<VAL>(
            "The minimum value to validate against"
            VAL constraint,
            "Determines if the constraint value itself is valid or not"
            Boolean inclusive/*=true*/)
        satisfies Validator<VAL>
        given VAL satisfies Comparable<VAL> {

    shared actual Boolean validated(VAL val) {
        if (inclusive) {
            return val.compare(constraint) != smaller;
        } else {
            return val.compare(constraint) == larger;
        }
    }

}

"A validator that checks a value against a sepecified maximum"
shared class MaxValidator<VAL>(
            "The maximum value to validate against"
            VAL constraint,
            "Determines if the constraint value itself is valid or not"
            Boolean inclusive/*=true*/)
        satisfies Validator<VAL>
        given VAL satisfies Comparable<VAL> {
            
    shared actual Boolean validated(VAL val) {
        if (inclusive) {
            return val.compare(constraint) != larger;
        } else {
            return val.compare(constraint) == smaller;
        }
    }

}

// Tests
void run() {
    value v1 = MinValidator(5, true);
    print("10 >= 5 ``v1.validated(10)``");
    print("5 >= 5 ``v1.validated(5)``");
    print("4 >= 5 ``v1.validated(4)``");
    value v2 = MinValidator(5, false);
    print("10 > 5 ``v2.validated(10)``");
    print("5 > 5 ``v2.validated(5)``");
    print("4 > 5 ``v2.validated(4)``");
    value v3 = MaxValidator(5, true);
    print("10 <= 5 ``v3.validated(10)``");
    print("5 <= 5 ``v3.validated(5)``");
    print("4 <= 5 ``v3.validated(4)``");
    value v4 = MaxValidator(5, false);
    print("10 < 5 ``v4.validated(10)``");
    print("5 < 5 ``v4.validated(5)``");
    print("4 < 5 ``v4.validated(4)``");
}
