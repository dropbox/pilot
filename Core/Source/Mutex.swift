import Foundation

/// Simple wrapper providing a sane interface to pthread_mutex_t
internal class Mutex {
    init() {
        pthread_mutex_init(&mutex, nil)
    }

    deinit {
        pthread_mutex_destroy(&mutex)
    }

    @inline(__always)
    public func locked<R>(_ execute: () -> R) -> R {
        pthread_mutex_lock(&mutex); defer { pthread_mutex_unlock(&mutex) }
        return execute()
    }

    internal var mutex = pthread_mutex_t()
}
