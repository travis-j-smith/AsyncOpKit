/// AsyncOperation is provided for compatability with objective c

import Foundation

extension QualityOfService {
    
    /// returns a GCD serial queue for the corresponding QOS
    func createSerialDispatchQueue(_ label: String) -> DispatchQueue {
        return DispatchQueue(label: label, qos: dispatchQueueAttributes())
    }

    /// returns GCD's corresponding QOS class
    private func dispatchQueueAttributes() -> DispatchQoS {
        switch (self) {
        case .background:
            return .background
        case .default:
            return .default
        case .userInitiated:
            return .userInitiated
        case .userInteractive:
            return .userInteractive
        case .utility:
            return .utility
        }
    }
    
}
