import Foundation
import ObjectiveC

extension NSObject {

    // MARK: Associated object runtime helpers

    public func setAssociatedObject<T: AnyObject>(_ object: T?, forKey key: UnsafeRawPointer) {
        objc_setAssociatedObject(
            self,
            key,
            object,
            objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    public func associatedObjectForKey<T: AnyObject>(_ key: UnsafeRawPointer) -> T? {
        return objc_getAssociatedObject(self, key) as? T
    }

    public func clearAssociatedObjectForKey(_ key: UnsafeRawPointer) {
        objc_setAssociatedObject(
            self,
            key,
            nil,
            objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    // MARK: Type-specific variants

    public func setAssociatedInt(_ int: Int, forKey key: UnsafeRawPointer) {
        let number = NSNumber(value: int as Int)
        setAssociatedObject(number, forKey: key)
    }

    public func associatedIntForKey(_ key: UnsafeRawPointer) -> Int? {
        if let number: NSNumber = associatedObjectForKey(key) {
            return number.intValue
        }
        return nil
    }

    public func setAssociatedDouble(_ double: Double, forKey key: UnsafeRawPointer) {
        let number = NSNumber(value: double as Double)
        setAssociatedObject(number, forKey: key)
    }

    public func associatedDoubleForKey(_ key: UnsafeRawPointer) -> Double? {
        if let number: NSNumber = associatedObjectForKey(key) {
            return number.doubleValue
        }
        return nil
    }
}
