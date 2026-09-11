import SwiftUI

enum AISkinMotion {
    static let processingUpdateInterval = 0.1
    static let processingAdvance = Animation.linear(duration: processingUpdateInterval)

    static let standardDuration = 0.30

    static let standard = Animation.easeInOut(duration: standardDuration)
    static let emphasized = Animation.spring(response: 0.34, dampingFraction: 0.82)
}
