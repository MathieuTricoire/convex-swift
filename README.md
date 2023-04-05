# Convex client for Swift

Non official Swift client for [Convex](https://convex.dev/).

Convex is the TypeScript-native programmable database for the web. No need for
backend containers, caches, queues, and query languages. Convex replaces all of
them with a few simple APIs.

This Swift client can write and read data from a Convex backend with queries,
mutations, and actions. Get up and running at
https://docs.convex.dev/.

## Work in progress

At the moment this package provides some basic functionality and can be used with caution.
Breaking changes are expected with every release at this stage.

The current client is not "reactive" yet it doesn't supports websockets,
I'll implement that in the coming days.

## Basic usage

_Uses the backend functions from the Convex tutorial https://github.com/get-convex/convex-tutorial_

```swift
import Convex
import Foundation

let url = URL(string: "CONVEX PROJECT DEPLOYMENT URL")!
let client = Convex(url)

let author = "Mathieu"

// Recommended way that supports all Convex field values
let firstMessageArgs: ConvexValue = [
    "author": .string(author),
    "body": "Hi Convex!", // But if you have a string literal you can pass it directly
    // Example to pass a Set, update your Convex backend function and uncomment to see the result in your dashboard
    // "tags": .set(["Swift", "TypeScript", "Rust"])
]
_ = try await client.mutation("sendMessage", firstMessageArgs)

// You can use Swift types as long as Encodable but it's not the recommended way
// and some fields will not be set correctly on the Convex side (i.e. `Set`).
// I plan to fix that and probably create a `ConvexMap` struct in the future.
let secondMessageArgs = SendMessageArgs(
    author: author,
    body: "Here is a new Convex client for Swift"
)
_ = try await client.mutation("sendMessage", secondMessageArgs)

// List messages
let messages: [Message] = try await client.query("listMessages")
// or
// let messages: [ConvexValue] = try await client.query("listMessages")
for message in messages {
    print("\(message.author): \(message.body) (\(message._creationTime)) [id: \(message._id)]")
}

struct Message: Codable, ConvexIdentifiable {
    let _id: ConvexId
    @ConvexCreationTime
    var _creationTime: Date
    let author: String
    let body: String
}

struct SendMessageArgs: Encodable {
    var author: String
    var body: String
}
```

## Convex types

Convex backend functions are written in JavaScript, so arguments passed to
Convex RPC functions in Swift are serialized, sent over the network, and
deserialized into JavaScript objects. To learn about Convex's supported types
see https://docs.convex.dev/database/types.

In order to call a function that expects a JavaScript type, use the
corresponding Swift type inside a `ConvexValue`.

Have a look at the [tests](Tests/ConvexTests/ValueTests.swift) to have a better
understanding of the recommended way to use this client.

| JavaScript Type                   | Swift Type                                    | Example                                                            |
| --------------------------------- | --------------------------------------------- | ------------------------------------------------------------------ |
| [Id][JSType:Id]                   | [ConvexId](#ConvexId) (see below)             | `.id(ConvexId(tableName: tableName, id: id))`                      |
| [null][JSType:null]               | [ConvexNullable](#ConvexNullable) (see below) | `.null`                                                            |
| [bigint][JSType:bigint]           | [Int64][SwiftType:Int64]                      | `10`, `.int(10)`, `.int(intVar)`                                   |
| [number][JSType:number]           | [Double][SwiftType:Double]                    | `3.1`, `.float(3.1)`, `.float(floatVar)`                           |
| [boolean][JSType:boolean]         | [Bool][SwiftType:Bool]                        | `true`, `.bool(false)`, `.bool(boolVar)`                           |
| [string][JSType:string]           | [String][SwiftType:String]                    | `"abc"`, `.string("abc")`, `.string(stringVar)`                    |
| [ArrayBuffer][JSType:ArrayBuffer] | [Data][SwiftType:Data]                        | `.data(dataVar)`                                                   |
| [Array][JSType:Array]             | [Array][SwiftType:Array]                      | `[1, 3.2, "abc"]`, `.array([1, 3.2, "abc"])`, `.array(arrayVar)`   |
| [Set][JSType:Set]                 | [Set][SwiftType:Set]                          | `.set([1, 2])`, `.set(Set([1, 2]))`, `.set(setVar)`                |
| [Map][JSType:Map]                 | [Dict][SwiftType:Dict]                        | `.map(["a": 1, "b": 2])`, `.map(mapVar)`                           |
| [object][JSType:object]           | [Dict][SwiftType:Dict]                        | `["a": 1, "b": 2]`, `.object(["a": 1, "b": 2])`, `.object(mapVar)` |

### ConvexId

Id objects represent references to Convex documents. They contain a `table_name`
string specifying a Convex table (tables can be viewed in
[the dashboard](https://dashboard.convex.dev)) and a globably unique `id`
string. If you'd like to learn more about the `id` string's format, see
[our docs](https://docs.convex.dev/api/classes/values.GenericId).

### ConvexNullable

A `ConvexNullable` value will send the encapsulated value if defined or `null` if not.
This is different than an `Optional` that will send nothing if `nil`.
Using `ConvexNullable` you can unset a value on the Convex side.
This is the adopted state for now, I've been playing with Convex for a week,
I don't know if this fits the Convex philosophy, it might change in the future.

---

## License

Licensed under Apache License, Version 2.0, (LICENSE-APACHE or <https://www.apache.org/licenses/LICENSE-2.0>)

## Contribution

Unless you explicitly state otherwise, any contribution intentionally submitted
for inclusion in the work by you, as defined in the Apache-2.0 license, shall
be dual licensed as above, without any additional terms or conditions.


[JSType:Id]: https://docs.convex.dev/api/classes/values.GenericId
[JSType:null]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Data_structures#null_type
[JSType:bigint]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Data_structures#bigint_type
[JSType:number]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Data_structures#number_type
[JSType:boolean]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Data_structures#boolean_type
[JSType:string]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Data_structures#string_type
[JSType:ArrayBuffer]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/ArrayBuffer
[JSType:Array]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array
[JSType:Set]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Set
[JSType:Map]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Map
[JSType:object]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Data_structures#objects

[SwiftType:Bool]: https://developer.apple.com/documentation/swift/bool
[SwiftType:Int64]: https://developer.apple.com/documentation/swift/int64
[SwiftType:Double]: https://developer.apple.com/documentation/swift/double
[SwiftType:String]: https://developer.apple.com/documentation/swift/string
[SwiftType:Array]: https://developer.apple.com/documentation/swift/array
[SwiftType:Dict]: https://developer.apple.com/documentation/swift/dictionary
[SwiftType:Set]: https://developer.apple.com/documentation/swift/set
[SwiftType:Data]: https://developer.apple.com/documentation/foundation/data
