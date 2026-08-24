import SwiftUI

enum AISkinMotion {
    static let quickDuration = 0.18
    static let standardDuration = 0.30
    static let relaxedDuration = 0.45

    static let standard = Animation.easeInOut(duration: standardDuration)
    static let emphasized = Animation.spring(response: 0.34, dampingFraction: 0.82)
}
