//: [Previous](@previous)

/*:
 # Subjects

 Once one `Publisher` is created (see [Previous](@previous)), you can only act on it by subscribing to events.
 */
import Combine

// Declare the observable
let publisher = Just(1)

// Now the only option we have is to subscribe to it to receive events

/*:
 FRP framworks provide a kind of `Publisher` that can be manipulated in an easier way than the previous implementation
 
 Those elements are named `Subjects`. We also say that they act as both a Publisher and a Subscriber object (they can accept new events).

 The following list of `Subject` is not exhaustive and only present the most used in day to day work.
 */

/*:
 ## PassthroughSubject

 This kind of subject simply transfer the events to already subscribed observer. Observers may loses event if they subscribed too late.
 */

do {
	print("🚀 PassthroughSubject")
	let subject = PassthroughSubject<Int, Never>()

	let sub1 = subject.sink { print("Sub 1: \($0)")}

	subject.send(1)
	subject.send(2)

	let sub2 = subject.sink { print("Obs 2: \($0)")}
	subject.send(3)

	sub1.cancel()
	sub2.cancel()
}

//: Excercise: What would be the output here?
// WRITE HERE

/*:
 ## CurrentValueSubject

 This subject has the notion of behavior and always start with a value. The last value it has ever produced
 is passed to new subscribers as soon as they subscribe.
 */

do {
	print("🚀 CurrentValueSubject")
	let subject = CurrentValueSubject<Int, Never>(1)

	let sub1 = subject.sink { print("Sub 1: \($0)") }
	subject.send(2)

	let sub2 = subject.sink { print("Sub 2: \($0)") }
	subject.send(3) // Alternative to `onNext`
	subject.send(completion: .finished)

	sub1.cancel()
	sub2.cancel()
}


//: Excercise: What would be the output here?
// WRITE HERE:
