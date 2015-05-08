import ceylon.collection {
    linked,
    HashSet
}

see (`interface Observer`)
by ("Tako Schotanus")
shared interface Observable<out Element> {
    shared formal void onSubscribe(Observer<Element> observer);
    
    shared formal Destroyable observe(Observer<Element> observer);
    
    shared Destroyable subscribe(Anything next(Element element), Anything error(Throwable error) => defaultOnError, Anything completed() => defaultOnCompleted, Anything start() => defaultOnStart) {
        return observe(FunctionsObserver(next, error, completed, start));
    }
    
    "Lifts a function to the current `Observable` and returns a new `Observable`
     that when subscribed to will pass the values of the current `Observable`
     through the [[transformer]] function."
    Observable<OUT> lift<OUT>(
        "A function that given an [[Observer]] will return an [[Observer]] that
         applies a certain transformation on the source stream."
        Observer<Element>(Observer<OUT>) transformer) {
        return observables.create<OUT>(void(Observer<OUT> observer) {
            onSubscribe(transformer(observer));
        });
    }
    
    Observable<OUT> liftFunc<OUT>(
        "A function that given an [[Element]] and a target [[Observer]] will
         decide to emit the element as-is, transform it first, replace it with
         another, emit new elements or do nothing at all."
        Anything(Element, Observer<OUT>) transformer) {
        class LiftFunc<U>(Observer<OUT> observer) extends TransformingObserver<U, OUT>(observer) {
            shared actual void onNext(U element) {
                if (is Element element) {
                    transformer(element, delegate);
                }
            }
        }
        return lift<OUT>(LiftFunc<Element>);
    }
    
    "Determines if there is at least one element of this 
     stream that satisfies the given [[predicate 
     function|selecting]]. If the stream is empty, returns 
     `false`. For an infinite stream, this operation might 
     not terminate."
    see (`function every`)
    shared default 
    Observable<Boolean> any(
        "The predicate that at least one element must 
         satisfy."
        Boolean selecting(Element element)) {
        class Any<U>(Observer<Boolean> observer) extends TransformingObserver<U, Boolean>(observer) {
            shared actual void onNext(U element) {
                if (is Element element, selecting(element)) {
                    delegate.onNext(true);
                    delegate.onCompleted();
                    destroy(null);
                }
            }
            shared actual void onCompleted() {
                delegate.onNext(false);
                delegate.onCompleted();
            }
        }
        return lift(Any<Element>);
    }
    
    "Produces a stream containing every [[step]]th element 
     of this stream. If the step size is `1`, the resulting
     stream contains the same elements as this stream.
     
     For example, the expression
     
         observables.fromIterable(0..10).by(3)
     
     results in the stream `0, 3, 6, 9`.
     
     The step size must be greater than zero."
    throws (`class AssertionError`, 
        "if the given step size is nonpositive, 
         i.e. `step<1`")
    shared default 
    Observable<Element> by(Integer step) {
        "step size must be greater than zero"
        assert (step > 0);
        if (step == 1) {
            return this;
        } 
        else {
            variable Integer index = 0;
            return liftFunc<Element>(void(elem, obs) {
                if (index++ % step == 0) {
                    obs.onNext(elem);
                }
            });
        }
    }
    
    "Produces a stream containing the elements of this 
     stream, replacing every `null` element with the [[given 
     default value|defaultValue]]. The resulting stream does 
     not have the value `null`.
     
     For example, the expression
     
         observables.fromIterable({ \"123\", \"abc\", \"456\" })
                .map(parseInteger).defaultNullElements(0)
     
     results in the stream `123, 0, 456`."
    see (`value coalesced`)
    shared default 
    Observable<Element&Object|Default>
            defaultNullElements<Default>(
        "A default value that replaces `null` elements."
        Default defaultValue)
        given Default satisfies Object
            => liftFunc<Element&Object|Default>(void(elem, obs)
                => obs.onNext(elem else defaultValue));
    
    "The non-null elements of this stream, in the order in
     which they occur in this stream. For null elements of 
     the original stream, there is no entry in the resulting 
     stream.
     
     For example, the expression
     
         observables.fromIterable({ \"123\", \"abc\", \"456\"})
                .map(parseInteger).coalesced
     
     results in the stream `123, 456`."
    shared default 
    Observable<Element&Object> coalesced
            => liftFunc<Element&Object>(void(elem, obs) {
                if (exists elem) {
                    obs.onNext(elem);
                }
            });
    
    "Returns `true` if the iterator for this stream produces
     the given element, or `false` otherwise. In the case of 
     an infinite stream, this operation might never terminate;
     furthermore, this default implementation iterates all
     the elements until found (or not), which might be very
     expensive."
    shared default
    Observable<Boolean> contains(Object element) 
            => any((e) => if (exists e) then e==element else false);
    
    "Produces the number of elements in this stream that 
     satisfy the [[given predicate function|selecting]].
     For an infinite stream, this method never terminates."
    shared default 
    Observable<Integer> count(
        "The predicate satisfied by the elements to be 
         counted."
        Boolean selecting(Element element)) {
        class Count<U>(Observer<Integer> observer) extends TransformingObserver<U, Integer>(observer) {
            variable value count = 0;
            shared actual void onNext(U element) {
                if (is Element element, selecting(element)) {
                    count++;
                }
            }
            shared actual void onCompleted() {
                delegate.onNext(count);
                delegate.onCompleted();
            }
        }
        return lift(Count<Element>);
    }
    
    "Call the given [[function|step]] for each element of 
     this stream, passing the elements in the order they 
     occur in this stream.
     
     For example:
     
         words.each(void (word) {
             print(word.lowercased);
             print(word.uppercased);
         });
     
     This is an alias for [[subscribe]] with the caveat that
     it only passes the `onNext()` function and that there is
     no way to cancel the subscription."
    shared default void each(
        "The function to be called for each element in the
         stream."
        void step(Element element)) {
        subscribe(step);
    }
    
    "Determines if the stream is empty, that is to say, if 
     the iterator returns no elements."
    shared default
    Observable<Boolean> empty {
        class Empty<U>(Observer<Boolean> observer) extends TransformingObserver<U, Boolean>(observer) {
            shared actual void onNext(U element) {
                delegate.onNext(false);
                delegate.onCompleted();
                destroy(null);
            }
            shared actual void onCompleted() {
                delegate.onNext(true);
                delegate.onCompleted();
            }
        }
        return lift(Empty<Element>);
    }
    
    "Determines if all elements of this stream satisfy the 
     given [[predicate function|selecting]]. If the stream
     is empty, return `true`. For an infinite stream, this 
     operation might not terminate."
    see (`function any`)
    shared default 
    Observable<Boolean> every(
        "The predicate that all elements must satisfy."
        Boolean selecting(Element element)) {
        class Every<U>(Observer<Boolean> observer) extends TransformingObserver<U, Boolean>(observer) {
            shared actual void onNext(U element) {
                if (is Element element, !selecting(element)) {
                    delegate.onNext(false);
                    delegate.onCompleted();
                    destroy(null);
                }
            }
            shared actual void onCompleted() {
                delegate.onNext(true);
                delegate.onCompleted();
            }
        }
        return lift(Every<Element>);
    }
    
    "A stream containing all but the last element of this 
     stream."
    shared default
    Observable<Element> exceptLast {
        variable Boolean first = true;
        variable Element? previous = null;
        return liftFunc<Element>(void(elem, obs) {
            if (first) {
                first = false;
            } else if (is Element p=previous) {
                obs.onNext(p);
            }
            previous = elem;
        });
    }
    
    "Produces a stream containing the elements of this 
     stream that satisfy the given [[predicate 
     function|selecting]]."
    shared default
    Observable<Element> filter(
        "The predicate the elements must satisfy."
        Boolean selecting(Element element))
            => liftFunc<Element>(void(elem, obs) {
                if (selecting(elem)) {
                    obs.onNext(elem);
                }
            });
    
    "The first element of this stream which satisfies the 
     [[given predicate function|selecting]], if any. For
     an infinite stream, this method might not terminate.
     
     For example, the expression
     
         observables.fromIterable(-10..10).find(Integer.positive)
     
     produces `1`."
    shared default 
    Observable<Element> find(
        "The predicate the element must satisfy."
        Boolean selecting(Element&Object element))
            => liftFunc<Element&Object>(void(elem, obs) {
                if (is Element&Object elem, selecting(elem)) {
                    obs.onNext(elem);
                }
            });
    
    "The last element of this stream which satisfies the 
     [[given predicate function|selecting]], if any. For
     an infinite stream, this method will not terminate.
     
     For example, the expression
     
         observables.fromIterable(-10..10).findLast(3.divides)
     
     evaluates to `9`."
    shared default 
    Observable<Element> findLast(
        "The predicate the element must satisfy."
        Boolean selecting(Element&Object element)) {
        class FindLast<U>(Observer<U> observer) extends TransformingObserver<U, U>(observer) {
            variable U? last = null;
            variable Boolean found = false;
            shared actual void onNext(U element) {
                if (is Element&Object element, selecting(element)) {
                    last = element;
                    found = true;
                }
            }
            shared actual void onCompleted() {
                if (found, exists l=last) {
                    delegate.onNext(l);
                }
                delegate.onCompleted();
            }
        }
        return lift(FindLast<Element>);
    }
    
    "The first element returned by the iterator, if any, or 
     `null` if this stream is empty."
    shared default
    Observable<Element> first {
        class First<U>(Observer<U> observer) extends TransformingObserver<U, U>(observer) {
            shared actual void onNext(U element) {
                if (is Element element) {
                    delegate.onNext(element);
                    delegate.onCompleted();
                    destroy(null);
                }
            }
        }
        return lift(First<Element>);
    }
    
    """Given a [[mapping function|collecting]] that accepts an 
       [[Element]] and returns a stream of [[Result]]s, 
       produces a new stream containing all elements of every 
       `Result` stream that results from applying the function 
       to the elements of this stream.
       
       For example, the expression
       
           observables.fromIterable({ "Hello", "World" })
                   .flatMap(String.lowercased)
       
       results in this stream:
       
           'h', 'e', 'l', 'l', 'o', 'w', 'o', 'r,' 'l', 'd'
       
       The expression
           
           observables.fromIterable({ "hello"->"hola", "world"->"mundo" })
                   .flatMap(Entry<String,String>.pair)
       
       produces this stream:
       
           "hello", "hola", "world", "mundo""""
    see (`function observables.expand`)
    shared default 
    Observable<Result> flatMap<Result>(
            "The mapping function to apply to the elements 
             of this stream, that produces a new stream of 
             [[Result]]s."
            Observable<Result> collecting(Element element))
            => observables.expand(map(collecting));
    
    "A stream containing all [[entries|Entry]] of form 
     `index->element` where `element` is an element of this
     stream, and `index` is the position at which `element` 
     occurs in this stream, ordered by increasing `index`.
     
     For example, the expression 
     
         observables.fromIterable({ \"hello\", null, \"world\" })
                .indexed
     
     results in the stream `0->\"hello\", 1->null, 2->\"world\"`."
    shared default 
    Observable<<Integer->Element>> indexed {
        variable Integer index = 0;
        return liftFunc<<Integer->Element>>(void(elem, obs) {
            if (exists elem) {
                obs.onNext(index++->elem);
            }
        });
    }
    
    "Produces a stream containing the results of applying 
     the given [[mapping|collecting]] to the elements of 
     this stream.
     
     For example, the expression
     
         observables.fromIterable(0..4).map(10.power)
     
     results in the stream `1, 10, 100, 1000, 10000`."
    shared default 
    Observable<Result> map<Result>(
        "The mapping to apply to the elements."
        Result collecting(Element element))
            => liftFunc<Result>(void(elem, obs) {
                obs.onNext(collecting(elem));
            });
    
    "Provides an implementation of [[Observer]] where all calls to all methods
     are passed on to a delegate `Observer`."
    abstract class DestroyableObserver<U>() satisfies Observer<U> {
        variable Boolean isActive = true;
        
        shared actual default Boolean active => isActive;
        
        shared actual default void destroy(Throwable? error) {
            isActive = false;
        }
        
        shared void deactivate() {
            isActive = false;
        }
    }
    
    "Provides an implementation of [[Observer]] where all calls to any of the methods
     are passed on to their respective handler functions."
    class FunctionsObserver<U>(Anything onNextFunc(U element), Anything onErrorFunc(Throwable error), Anything onCompletedFunc(), Anything onStartFunc()) extends DestroyableObserver<U>() {
        shared actual void onStart() {
            if (active) {
                onStartFunc();
            }
        }
        
        shared actual void onNext(U element) {
            if (active) {
                onNextFunc(element);
            }
        }
        
        shared actual void onError(Throwable error) {
            if (active) {
                deactivate();
                onErrorFunc(error);
            }
        }
        
        shared actual void onCompleted() {
            if (active) {
                onCompletedFunc();
            }
        }
        
    }
    
    "Provides an implementation of [[Observer]] where all calls to all methods
     are passed on to a delegate `Observer`."
    abstract class TransformingObserver<IN, OUT>(shared Observer<OUT> delegate) extends DestroyableObserver<IN>() {
        
        shared actual default void onStart() {
            if (active) {
                delegate.onStart();
            }
        }
        
        shared actual default void onError(Throwable error) {
            if (active) {
                deactivate();
                delegate.onError(error);
            }
        }
        
        shared actual default void onCompleted() {
            if (active) {
                delegate.onCompleted();
            }
        }
        
        shared actual default Boolean active => super.active && delegate.active;
        
        shared actual default void destroy(Throwable? error) {
            super.destroy(error);
            delegate.destroy(error);
        }
    }
    
    void defaultOnStart() {
        // Default implementation does nothing
    }
    
    void defaultOnError(Throwable error) {
        // The default implementation just rethrows the exception
        throw error;
    }
    
    void defaultOnCompleted() {
        // Default implementation does nothing
    }
}

see (`interface Observer`)
by ("Tako Schotanus")
shared class MultiObservable<T>(Anything(Observer<T>) subscribe) satisfies Observable<T> {
    value observers = HashSet<Observer<T>>(linked);
    
    onSubscribe(Observer<T> observer) => subscribe(observer);
    
    shared actual Destroyable observe(Observer<T> observer) {
        observers.add(observer);
        return object satisfies Destroyable {
            shared actual void destroy(Throwable? error) {
                observers.remove(observer);
                observer.destroy(error);
            }
        };
    }
}

shared object observables {
    
    shared Observable<Element> create<Element>(Anything(Observer<Element>) subscribe) {
        class DirectObservable<T>(Anything(Observer<T>) subscribe) satisfies Observable<T> {
            
            onSubscribe(Observer<T> observer) => subscribe(observer);
            
            shared actual Destroyable observe(Observer<T> observer) {
                observer.onStart();
                onSubscribe(observer);
                return observer;
            }
            
        }
        return DirectObservable<Element>(subscribe);
    }
    
    shared Observable<Element> fromIterable<Element>(Iterable<Element> elements)
        => create<Element>(void(observer) {
            for (elem in elements) {
                observer.onNext(elem);
            }
            observer.onCompleted();
        });
        
    shared Observable<Nothing> empty
            = create<Nothing>(void(observer) {
        observer.onCompleted();
    });
    
    shared Observable<Element> expand<Element>(Observable<Observable<Element>> elements) {
        // TODO
        return nothing;
    }
}
