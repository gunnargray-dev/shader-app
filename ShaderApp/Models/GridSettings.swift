import SwiftUI
import Combine

class GridSettings: ObservableObject {
    @Published var density: Double = 0.6
    @Published var dotSize: Double = 0.7
    @Published var speed: Double = 1.0
    @Published var colorHue: Double = 0.5
    @Published var colorEnabled: Bool = true
    @Published var selectedPattern: PatternType = .wave
    
    enum PatternType: String, CaseIterable {
        case wave = "Wave"
        case pulse = "Pulse"
        case ripple = "Spiral"
        case noise = "Noise"
        
        var shaderFunction: String {
            switch self {
            case .wave: return "wavePattern"
            case .pulse: return "pulsePattern"
            case .ripple: return "ripplePattern"
            case .noise: return "noisePattern"
            }
        }
        
        var defaultSpeed: Double {
            switch self {
            case .wave: return 1.0
            case .pulse: return 0.9
            case .ripple: return 1.3
            case .noise: return 1.1
            }
        }
    }
    
    func updatePattern(_ pattern: PatternType) {
        selectedPattern = pattern
        speed = pattern.defaultSpeed
    }
}
