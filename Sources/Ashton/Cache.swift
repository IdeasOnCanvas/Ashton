import Foundation


public final class Cache<Key: Hashable, Value> {

    private var elements: [Key: Value]

    // MARK: - Lifecycle

    init(_ elements: [Key: Value] = [:]) {
        self.elements = elements
    }

    // MARK: - Cache

    subscript(key: Key) -> Value? {
        get { self.elements[key] }
        set { self.elements[key] = newValue }
    }
}
