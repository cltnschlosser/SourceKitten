//
//  SourceKitObject.swift
//  SourceKitten
//
//  Created by Norio Nomura on 2/7/18.
//  Copyright © 2018 SourceKitten. All rights reserved.
//

import Foundation
#if SWIFT_PACKAGE
import SourceKit
#endif

// MARK: - SourceKitObjectConvertible

public protocol SourceKitObjectConvertible {
    var sourcekitdObject: SourceKitObject? { get }
}

extension Array: SourceKitObjectConvertible where Element: SourceKitObjectConvertible {
    public var sourcekitdObject: SourceKitObject? {
        let sourceKitObjects = map { $0.sourcekitdObject }
        let objects: [sourcekitd_object_t?] = sourceKitObjects.map { $0?._sourcekitdObject }
        return sourcekitd_request_array_create(objects, objects.count).map { SourceKitObject($0, otherToRetain: sourceKitObjects)}
    }
}

extension Dictionary: SourceKitObjectConvertible where Value: SourceKitObjectConvertible {
    public var sourcekitdObject: SourceKitObject? {
        let keys: [sourcekitd_uid_t?]
        if Key.self is UID.Type {
            keys = self.keys.map { ($0 as! UID).uid }
        } else if Key.self is String.Type {
            keys = self.keys.map { UID($0 as! String).uid }
        } else {
            fatalError("Dictionary conforms to SourceKitObjectConvertible when `Key` is `UID` or `String`!")
        }
        let sourceKitObjects = values.map { $0.sourcekitdObject }
        let values: [sourcekitd_object_t?] = sourceKitObjects.map { $0?._sourcekitdObject }
        return sourcekitd_request_dictionary_create(keys, values, count).map { SourceKitObject($0, otherToRetain: sourceKitObjects) }
    }
}

extension Int: SourceKitObjectConvertible {
    public var sourcekitdObject: SourceKitObject? {
        return sourcekitd_request_int64_create(Int64(self)).map(SourceKitObject.init)
    }
}

extension Int64: SourceKitObjectConvertible {
    public var sourcekitdObject: SourceKitObject? {
        return sourcekitd_request_int64_create(self).map(SourceKitObject.init)
    }
}

extension String: SourceKitObjectConvertible {
    public var sourcekitdObject: SourceKitObject? {
        return sourcekitd_request_string_create(self).map(SourceKitObject.init)
    }
}

// MARK: - SourceKitObject

/// Swift representation of sourcekitd_object_t
public final class SourceKitObject {
    let _sourcekitdObject: sourcekitd_object_t
    
    private let otherToRetain: [SourceKitObject?]
    
    convenience init(_ sourcekitdObject: sourcekitd_object_t) {
        self.init(sourcekitdObject, otherToRetain: [])
    }

    init(_ sourcekitdObject: sourcekitd_object_t, otherToRetain: [SourceKitObject?]) {
        self._sourcekitdObject = sourcekitdObject
        self.otherToRetain = otherToRetain
    }
    
    deinit {
        sourcekitd_request_release(_sourcekitdObject)
    }

    /// Updates the value stored in the dictionary for the given key,
    /// or adds a new key-value pair if the key does not exist.
    ///
    /// - Parameters:
    ///   - value: The new value to add to the dictionary.
    ///   - key: The key to associate with value. If key already exists in the dictionary, 
    ///     value replaces the existing associated value. If key isn't already a key of the dictionary
    public func updateValue(_ value: SourceKitObjectConvertible, forKey key: UID) {
        sourcekitd_request_dictionary_set_value(_sourcekitdObject, key.uid, value.sourcekitdObject!._sourcekitdObject)
    }

    public func updateValue(_ value: SourceKitObjectConvertible, forKey key: String) {
        updateValue(value, forKey: UID(key))
    }

    public func updateValue<T>(_ value: SourceKitObjectConvertible, forKey key: T) where T: RawRepresentable, T.RawValue == String {
        updateValue(value, forKey: UID(key.rawValue))
    }
}

extension SourceKitObject: SourceKitObjectConvertible {
    public var sourcekitdObject: SourceKitObject? {
        return self
    }
}

extension SourceKitObject: CustomStringConvertible {
    public var description: String {
        let bytes = sourcekitd_request_description_copy(_sourcekitdObject)!
        let length = Int(strlen(bytes))
        return String(bytesNoCopy: bytes, length: length, encoding: .utf8, freeWhenDone: true)!
    }
}

//extension SourceKitObject: ExpressibleByArrayLiteral {
//    public convenience init(arrayLiteral elements: SourceKitObject...) {
//        self.init(elements.sourcekitdObject)
//    }
//}

extension SourceKitObject: ExpressibleByDictionaryLiteral {
    public convenience init(dictionaryLiteral elements: (UID, SourceKitObjectConvertible)...) {
        let keys: [sourcekitd_uid_t?] = elements.map { $0.0.uid }
        let sourceKitObjects = elements.map { $0.1.sourcekitdObject }
        let values: [sourcekitd_object_t?] = sourceKitObjects.map { $0?._sourcekitdObject }
        self.init(sourcekitd_request_dictionary_create(keys, values, elements.count)!, otherToRetain: sourceKitObjects)
    }
}

//extension SourceKitObject: ExpressibleByIntegerLiteral {
//    public convenience init(integerLiteral value: IntegerLiteralType) {
//        self.init(value.sourcekitdObject)
//    }
//}
//
//extension SourceKitObject: ExpressibleByStringLiteral {
//    public convenience init(stringLiteral value: StringLiteralType) {
//       self.init(value.sourcekitdObject)
//    }
//}
