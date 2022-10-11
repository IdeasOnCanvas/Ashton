import Foundation


public final class Cache<Key: Hashable, Value> {

    private var elements: [Key: Value]

    // MARK: - Properties

    var isEmpty: Bool { self.elements.isEmpty }

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
