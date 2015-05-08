
"""Provides a mechanism for receiving push-based notifications.
   
   After an Observer calls an [[Observable]]'s [[subscribe|Observable.subscribe]] method, the
   `Observable` calls the Observer's [[onNext]] method to provide notifications. A well-behaved
   `Observable` will call an Observer's [[onCompleted]] method exactly once or the Observer's
   [[onError]] method exactly once.
   
   `<T>` - the type of item the Observer expects to observe
   
   See [ReactiveX documentation: Observable](http://reactivex.io/documentation/observable.html)
   """
see (`interface Observable`)
by ("Tako Schotanus")
shared interface Observer<in Element> satisfies Destroyable {
    
    """Notifies the `Observer` that the [[Observable]] might start at any moment to send notifications.
       
       The [[Observable]] will call this method exactly once before calling [[onNext]] or
       [[onCompleted]] but [[onError]] might be called first if something went wrong before
       the `Observer` could be started.
       """
    shared default void onStart() {}
    
    """Provides the `Observer` with a new item to observe.
       
       The [[Observable]] may call this method 0 or more times.
       
       The `Observable` will not call this method again after it calls either [[onCompleted]] or
       [[onError]].
       """
    shared formal void onNext(
        "the item emitted by the Observable"
        Element element);
    
    """Notifies the `Observer` that the [[Observable]] has experienced an error condition.
       
       If the [[Observable]] calls this method, it will not thereafter call [[onNext]] or
       [[onCompleted]] and [[active]] will now return `false`.
       """
    shared default void onError(
        "the exception encountered by the Observable"
        Throwable error) {
        throw error;
    }
    
    """Notifies the `Observer` that the [[Observable]] has finished sending push-based notifications.
       
       The [[Observable]] will not call this method if it calls [[onError]]. No other methods
       will be called anymore after this call and [[active]] will now return `false`.
       """
    shared default void onCompleted() {}
    
    """Is used to determine if the `Observer` is still accepting notifications"""
    shared default Boolean active => true;
    
    """Destroys the `Observer` and unsubsribes it from its [[Observable]]. No notifications
       will be received anymore after this call and [[active]] will now return `false`.
       """
    shared actual default void destroy(Throwable? error) {}
}
