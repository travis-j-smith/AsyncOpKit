import Foundation
import Quick
import Nimble
import AsyncOpKit

class AsyncClosureOpKitTests: AsyncOpKitTests {
    
    override internal func getOperationInstance() -> JDAsyncOperation {
        return JDAsyncClosureOperation()
    }
    
    override func spec() {
        // make sure we pass all the current specs
        super.spec()
        
        describe("Handle Async Closures") {
            
            var subject : JDAsyncClosureOperation? = nil
            var resultsObject : JDAsyncOperationResults? = nil
            var resultsHandlerCompleted : Bool? = nil
            var numberOfAsyncClosuresFinished : Int?
            
            beforeEach {
                numberOfAsyncClosuresFinished = 0
                resultsObject = nil
                resultsHandlerCompleted = false
                
                subject = self.getOperationInstance() as? JDAsyncClosureOperation
                subject?.completionHandler = {
                    result in
                    resultsObject = result
                    resultsHandlerCompleted = true
                }
            }
            
            afterEach {
                resultsObject = nil
                resultsHandlerCompleted = nil
                subject?.completionHandler = nil
                subject = nil
                numberOfAsyncClosuresFinished = nil
            }
            
            context("when there is one closure that finishes synchronously") {
                
                beforeEach {
                    subject?.addAsyncClosure {
                        op, closureIdentifier in
                        numberOfAsyncClosuresFinished?++
                        op.markClosureWithIdentifierFinished(closureIdentifier)
                    }
                    subject?.start()
                }
                
                it("should execute one closure") {
                    expect(numberOfAsyncClosuresFinished).toEventually(equal(1))
                }
                
                it("should eventually mark itself as finished") {
                    expect(subject?.finished).toEventually(beTrue())
                }
            }
            
            context("when there are ten closures that finish synchronously") {
                
                beforeEach {
                    for _ in 0...9 {
                        subject?.addAsyncClosure {
                            op, closureIdentifier in
                            numberOfAsyncClosuresFinished?++
                            op.markClosureWithIdentifierFinished(closureIdentifier)
                        }
                    }
                    
                    subject?.start()
                }
                
                it("should execute ten closures") {
                    expect(numberOfAsyncClosuresFinished).toEventually(equal(10))
                }
                
                it("should eventually mark itself as finished") {
                    expect(subject?.finished).toEventually(beTrue())
                }
            }
            
            context("when there are ten closures that finish asynchronously") {
                
                beforeEach {
                    for _ in 0...9 {
                        subject?.addAsyncClosure {
                            op, closureIdentifier in
                            dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
                                numberOfAsyncClosuresFinished?++
                                op.markClosureWithIdentifierFinished(closureIdentifier)

                            }
                        }
                    }
                    
                    subject?.start()
                }
                
                it("should execute ten closures") {
                    expect(numberOfAsyncClosuresFinished).toEventually(equal(10))
                }
                
                it("should eventually mark itself as finished") {
                    expect(subject?.finished).toEventually(beTrue())
                }
            }
            
            context("when a closure adds 9 new closures") {
                
                beforeEach {
                        subject?.addAsyncClosure {
                            op, closureIdentifier in
                            
                            for _ in 0...9 {
                                op.addAsyncClosure {
                                    op, closureIdentifier in
                                    dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
                                        numberOfAsyncClosuresFinished?++
                                        op.markClosureWithIdentifierFinished(closureIdentifier)
                                        
                                    }

                                }
                            }

                            dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
                                numberOfAsyncClosuresFinished?++
                                op.markClosureWithIdentifierFinished(closureIdentifier)
                                
                            }
                    }
                    
                    subject?.start()
                }
                
                it("should execute ten total closures") {
                    expect(numberOfAsyncClosuresFinished).toEventually(equal(10))
                }
                
                it("should eventually mark itself as finished") {
                    expect(subject?.finished).toEventually(beTrue())
                }
            }
            
            context("when the operation is cancelled after executing five closures but there are ten closures that finish asynchronously") {
                
                var numberOfCancellations = 0
                
                beforeEach {
                    for _ in 0...9 {
                        subject?.addAsyncClosure {
                            op, closureIdentifier in
                            if op.cancelled {
                                numberOfCancellations++
                                op.markClosureWithIdentifierFinished(closureIdentifier)
                                return
                            }
                            dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
                                numberOfAsyncClosuresFinished?++
                                if (numberOfAsyncClosuresFinished == 5) {
                                    op.cancel()
                                }
                                op.markClosureWithIdentifierFinished(closureIdentifier)
                                
                            }
                        }
                    }
                    
                    subject?.start()
                }
                
                afterEach {
                    numberOfCancellations = 0
                    subject?.finish()
                    subject = nil
                }
                
                it("should execute five uncancelled closures") {
                    expect(numberOfAsyncClosuresFinished).toEventually(equal(5))
                }
                
                it("should eventually mark itself as finished") {
                    expect(subject?.finished).toEventually(beTrue())
                }
                
                it("should eventually mark itself as canceled") {
                    expect(subject?.cancelled).toEventually(beTrue())
                }
                
                it("should tell 5 of the closures that it was cancelled") {
                    expect(numberOfCancellations).toEventually(equal(5))
                }
            }
            
        }
        
    }

}