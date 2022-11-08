/*:
 # FRP with Combine - A gentle introduction

  Combine is a Functional Reactive Programming (FRP) framework as RxSwift or ReactiveSwift.

  This playground intends to be a gentle introduction to reactive programming
  using Combine. For details information about the library, you're invited to
  take the watch the wwdc video and apple documentation on the subject.
  
  I would recommend to also read the Combine or/and RxSwift book(s) on raywenderlich

 *   [Combine](Combine)
 *   [Subjects](Subjects)
 *   [Operators](Operators)

*/
import Combine

var bag: Set<AnyCancellable> = []
(0 ..< 20).map {_ in Just(42)}
	.combineLatest()
	.sink { value in
		print("Value: \(value)")
		bag.removeAll()
	}
	.store(in: &bag)
