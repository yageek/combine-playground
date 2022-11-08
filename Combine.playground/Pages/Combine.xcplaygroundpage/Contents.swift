/*: [Previous](@previous)
 # FRP

 The `R` from `FRP` means reactive and implies reaction to some element we could call `events`
 
 The main page about [Combine on Apple's website](https://developer.apple.com/documentation/combine) says:

 **The Combine framework provides a declarative Swift API for processing values over time. These values can represent many kinds of asynchronous events. Combine declares publishers to expose values that can change over time, and subscribers to receive those values from the publishers.**
 
 tl;dr: *Publishers* produces events and *Suscribers* consume them

 ----

 A Publisher is an object we can subscribe/unsubscribe from to retrieve a set of events.

 it can emit 3 types of events:
 - A value is produced
 - Completion + Subscription is released/disposed
 - Error + Subscription is released/disposed

Despite the unsubscription in case of completion/error, there is no determined schema about which events will be sent:
- We can have a publisher that produces no value, but just complete
- We can have a publisher that produces values but never completes or errored
- We can have a publisher that does nothing
- etc

Drawing the sequence of events along an axis, using a circle for a produced value, a cross for error and a dash for completion is called a marble diagram.

 Example:
	  Value   Value        Completion
-------(3)-----(2)------------|->
	  Value   Value          Error
-------(3)----(1)-------------x->

 Much more readable examples can be found on [RxMarble](https://rxmarbles.com/)

 ## Basics

 Let's start by importing the main reactive library
 */
import Foundation
import Combine


/*:
 In the very old days, ReactiveCocoa was an Objc FRP framework and all value and errors were simple ``id`` object. You were able to cast/throw different types of errors and values using the same publisher instance.
 
 The birth of Swift and generics gave the opportunity to have a more strict/safe usage of publishers. Implementation differs regarding the used framework:
 
 * ReactiveCocoa/RxSswift: Publishers object are called ``Observable`` objects.  They are constraint with one generic component T where T is the type of the values produced over time. In case of one error event, dynamic dispatch is used and we retrieved only objects conforming to the main swift ``Error`` protocol. (Observable<T>)
 * Combine: Combine uses two generic paramters for a publisher, one for the type of value produced, and one for the type of error produced. That's means in combine, you would be able to send more specific errors elements.(Publisher<T, E: Error>)
 
 
Now let's create some `Publisher` and let's try to get notified from them.
Let's create a new `Publisher` of int elements:
*/
struct SimpleError: Error { }

// Here we create a new that produces `Int` value and never fails
let simplePublisher = [1, 2, 3, 4, 5, 6].publisher

//: We can use other convenient initializer for creating publishers

let justOne = Just("Hello world")
let never = Empty<String, Never>(completeImmediately: false)
let justComplete = Empty<String, Never>()
let error = Fail<String, SimpleError>(error: SimpleError())

//: To receive the events mentioned above from a `Publisher`, you subscribes to it. This provides you an handle you can use to unsubscribe from it.

let subscription = simplePublisher.sink { completion in
	switch completion {
	case .failure(let simpleError):
		print("Error: \(simpleError)")
	case .finished:
		print("Completed")
	}
} receiveValue: { value in
	print("Value: \(value)")
}
//: At the end we can unsubscribe from the observer
subscription.cancel()

//: Exercise: Could you draw the marble diagrams for every observables declare under `SimpleError`?
// DRAW HERE:

/*: Exercise: Using the `subscribe` method, creates different subscriptions to the upper defined observables
 and execute a print statements on:
- `justOne` completion and producing value event
- `justComplete` completion
- `error` error event
*/

/*: Exercise:  Create a new set of publisher using `Never` as the `Failure` type. Explains how the API changes for this case
 and explain why.
*/

// CODE HERE:

/*:
 ## Publishers are typed

 There is an important thing to notice is that a publisher is a construction around two generic types (let's call them `Output` and `Failure`).
 Remembers the rules upwards? There is an event producing a value. What's kind of value does it produce? The answer is `Output`.
When there is an error event, what is the the type of error that is returned? The answer is `Failure`. (**NOTE**: Failure is constrained to implement the Swift.Error protocol
 
 This is a major difference with others FRP framework like RxSwift or ReactiveSwift.
 On the opposite, the error event is not generic (aka. does not use static dispatch) and uses instead polymorphism (aka. dynamic dispatch) to return any element conforming to the `Swift.Error` procotol.

 To sum up:
-   Publishers is a generic construction around two types: `Output` and `Failure`
-   When the publisher produces a value, it returns a value of type `Output`.
-   When the observable produces an error, it returns a value of type `Failure` who is constrained to implement `Swift.Error`

This implies that a `Publisher<String, SimplError>` is different type from a `Publisher<String, Error>` or `Publisher<Int, SimplError>`.
*/

//: Exercise: Create a publisher that produces several `Just<Int, Never>` values.
// CODE HERE:

//: Exercise+: By taking a look at the `RxSwift` documentation, try to translate the two previous exercise from `Combine` to `RxSwift`
// CODE HERE:

/*:
 ## Creating Publishers

 The previous constructions were just basic basic Publisher constructions. Let's use the canonical way of creating publishers.
 
 The underlying mechanism is much more sophisticated that in RxSwift or ReactiveSwift. This allows to implement somthing called `backpressure` that, from what the author knows, is missing in the other frameworks.
 
Publisher requires two other elements to be able to work: a `Subscriber` and a `Subscription`.

 ![Subscription mechanism](subscription.png "Title")
 
 Let's create a simple publisher of integer that will either sends the 5 next values if configured with an even number or the 3 if an odd number
 */

class IntegerSubscription<S: Subscriber>: Subscription where S.Input == Int {
	
	private var lastIncrement: Int
	private var subscriber: S?
	
	private var remaining: Subscribers.Demand
	private var requested: Subscribers.Demand
	
	init(subscriber: S, startInteger: Int) {
		self.lastIncrement = startInteger
		self.remaining = startInteger.isMultiple(of: 2) ? Subscribers.Demand.max(5) : Subscribers.Demand.max(3)
		
		self.subscriber = subscriber
		self.requested = .none
	}
	
	func request(_ demand: Subscribers.Demand) {
		
		// We check we have remaining elements to sends
		guard self.remaining > .none else { self.subscriber?.receive(completion: .finished); return }
		
		// We update the number of demands to fullfill
		self.requested += demand
		
		// We check that demand exists
		while self.subscriber != nil && self.requested != .none && self.remaining != .none {
			
			self.remaining -= 1
			self.requested -= 1
			
			self.subscriber?.receive(self.lastIncrement)
			self.lastIncrement += 1
		}
	
		if self.remaining == .none {
			self.subscriber?.receive(completion: .finished)
		}
	}
	
	func cancel() {
		self.subscriber = nil
	}
}

class SimpleIntegerPublisher: Publisher {
	
	let startInteger: Int
	init(startInteger: Int) {
		self.startInteger = startInteger
	}
	
	typealias Output = Int
	typealias Failure = Never
	
	func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, Int == S.Input {
		// We will need to create a subscription object and pass it to the subscriber
		
		let subscription = IntegerSubscription(subscriber: subscriber, startInteger: self.startInteger)
		subscriber.receive(subscription: subscription)
	}
}
/*:
 **NOTE**:
Most of the `Publisher` you work with, will not start to produce events unless a subscription has been created.
 
 */

let newSub = SimpleIntegerPublisher(startInteger: 7).sink { print("Value: \($0)") }

/*:
 ## Creating Subscribers
 
 The used `sink` method is a simple method that returns a `Subscriber` element. Combine allows us to create custom way of subscribing to event
 and handling backpressure. This is out of scope for now 😅. I invite you to check the Combine book on the [Chapter 18 - Custom publisher and back pressure](https://www.raywenderlich.com/books/combine-asynchronous-programming-with-swift/v3.0/chapters/18-custom-publishers-handling-backpressure)
 */

//: [Next](@next)
