//: [Previous](@previous)
/*: # Operators

 The `F` from `FRP` means `Functional` as in `Functional` Programming

Operators are the bread and butter when dealing with FRP. They allows us to manipulate and transform the streams of values
 in a functional way.
 You can find an exhaustiv list of operators in the [Publisher's documentation](https://developer.apple.com/documentation/combine/publisher).

I invite you also to take a look at http://reactivex.io/documentation/operators.html
 
 ## Basic operators

 ### map

 A basic operator is `map` that behaves exactly like its correspondant inside the swift iterators.
 You can transform an `Observable<T>` to some `Observable<U>`
 */
import Combine

do {
	print("⚙️ map ")
	let base = [1, 2, 3, 4, 5].publisher
	let subscription = base.map { $0 + 1 }
		.sink { print("\($0)" ) }
	subscription.cancel()
}

//: Exercise - What does the upper code prints?


// WRITE HERE

/*:
 ### filter

 As its name implies, it filters values out of the stream of values.
 */

do {
	print("⚙️ filter ")
	let base = stride(from: 0, to: 10, by: 1).publisher
	let subscription = base.filter { $0.isMultiple(of: 2) }
		.sink { print("\($0)" ) }
	subscription.cancel()
}

//: Exercise - What does the upper code prints?


// WRITE HERE


/*:
 ### removeDuplicates

 As its name implies, it removes contiguous similar values
 */

do {
	print("⚙️ removeDuplicates ")
	let base =  [1, 2, 2, 3, 3, 4, 5].publisher
	let subscription = base.removeDuplicates()
		.sink { print("\($0)" ) }
	subscription.cancel()

}

//: Exercise - What does the upper code prints?
// WRITE HERE

/*:
 ### Others

 //: Exercise - Go on [ReactiveX.io](http://reactivex.io/documentation/operators.html) and try to explain with words what
  are doing the following operators:

 - `do`
 - `take`
 - `reduce`
 - `combineLatest`
 - `flatMap`
 - `switchToLatest`
 
 Then go [here](https://github.com/CombineCommunity/rxswift-to-combine-cheatsheet) and find the equivalent in Combine
 // WRITE HERE

 ## Chaining operators

 As in the functional paradigm, you can chain operators to create more complex streams
 */

do {
	print("⚙️ Chaining")
	let sub = stride(from: 0, to: 20, by: 1).publisher
		.filter { $0 != 0 }
		.map { $0*2 }
		.removeDuplicates()
		.sink { print("Value: \($0)") }
	sub.cancel()
}

/*:
 You need to think the chained operators as a completely new publisher. And again, most of the times it will not start producing
 values until you subscribe to it.

 This also means if any of the element of the chain is producing an error or complete, this error will be propagated as the error of the whole chain
 and cause the unsubscription.
 */

do {
	struct ChainError: Error { }
	print("⚙️ Chaining error")
	let sub = stride(from: 0, to: 20, by: 1)
		.publisher
		.filter { $0 != 0 }
		.map { $0*2 }
		.setFailureType(to: ChainError.self)
		.flatMap { previous -> AnyPublisher<Int, ChainError> in
			if previous == 20 {
				return Fail(outputType: Int.self, failure: ChainError()).eraseToAnyPublisher()
			}
			return Just(previous).setFailureType(to: ChainError.self).eraseToAnyPublisher()
		}
		.sink { completion in
			switch completion {
			case .finished:
				print("finished")
			case .failure(let error):
				print("Error: \(error)")
			}
		} receiveValue: { print("Value: \($0)") }

	sub.cancel()
}

import PlaygroundSupport
/*
 ## Error operators

 Some operators exists to handle/transform/react in case there is an error that is propagated to the chain. We mainly use `catch/tryCatch` and `retry` operator.

 //: Exercise: take a look at the documentation of those operators in the "Handling Errors" categories of Publisher and transform this `Publisher` into a new one successfully producing
 // values from 0 to 1 without editing the code of the `flatMap` function.
 */

do {
	print("⚙️ Error with catch")

	struct MultipleError: Error {
		let value: Int
	}
	let _ = stride(from: 0, to: 10, by: 1).publisher
		.setFailureType(to: MultipleError.self)
		.flatMap { i -> AnyPublisher<Int, MultipleError> in
			if i > 1 && (i % 2 == 0 || i % 3 == 0) {
				return Fail(outputType: Int.self, failure: MultipleError(value: i)).eraseToAnyPublisher()
			} else {
				return Just(i).setFailureType(to: MultipleError.self).eraseToAnyPublisher()
			}
			
		}
		.sink { completion in
			switch completion {
			case .finished:
				print("finished")
			case .failure(let error):
				print("Error: \(error)")
			}
		} receiveValue: { print("Value: \($0)") }
}

//: Exercise: Transform the following observable that it prints "Youpi!" (using retry(_ maxAttemptCount))
do {
	print("⚙️ Error with retry")
	struct TriggerError: Error {
		let attemptToSucceed: Int
	}

	class TriggerSubscription<S: Subscriber>: Subscription where S.Input == String, S.Failure == TriggerError {
		private var subscriber: S?
		private let trigger: Int
		
		init(subscriber: S, trigger: Int) {
			self.subscriber = subscriber
			self.trigger = trigger
		}
		
		func request(_ demand: Subscribers.Demand) {
			
			// We check that demand exists
				if self.trigger < 0 {
					self.subscriber?.receive(completion: .failure(TriggerError(attemptToSucceed: self.trigger)))
					self.subscriber = nil
					return
				} else {
					_ = self.subscriber?.receive("Youpi!!!")
					self.subscriber?.receive(completion: .finished)
				}
		}
		
		func cancel() {
			self.subscriber = nil
		}
	}

	class NegativeErrorPublisher: Publisher {

		private var trigger = -29
		func receive<S>(subscriber: S) where S : Subscriber, TriggerError == S.Failure, String == S.Input {
			
			let sub = TriggerSubscription(subscriber: subscriber, trigger: trigger)
			subscriber.receive(subscription: sub)
			self.trigger += 1
		}
		
		typealias Output = String
		typealias Failure = TriggerError
	}
}

//: [Next](@next)
