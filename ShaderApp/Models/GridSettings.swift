import SwiftUI
import Combine

class GridSettings: ObservableObject {
    @Published var density: Double = 0.6
    @Published var dotSize: Double = 0.7
    @Published var speed: Double = 1.0
    @Published var colorHue: Double = 0.5
    @Published var colorEnabled: Bool = true
    @Published var selectedPattern: PatternType = .wave
    @Published var bloomIntensity: Double = 1.0
    @Published var bloomRadius: Double = 1.0
    @Published var brightness: Double = 2.0
    
    enum PatternType: String, CaseIterable {
        case wave = "Wave"
        case pulse = "Pulse"
        case ripple = "Spiral"
        case noise = "Noise"
        case cellular = "Cellular"
        case flowField = "Flow Field"
        case gravity = "Gravity"
        case fractal = "Fractal"
        case kaleidoscope = "Kaleidoscope"
        case magnetic = "Magnetic"
        case growth = "Growth"
        case tunnel = "Tunnel"
        case interference = "Interference"
        
        var shaderFunction: String {
            switch self {
            case .wave: return "wavePattern"
            case .pulse: return "pulsePattern"
            case .ripple: return "ripplePattern"
            case .noise: return "noisePattern"
            case .cellular: return "cellularPattern"
            case .flowField: return "flowFieldPattern"
            case .gravity: return "gravityPattern"
            case .fractal: return "fractalPattern"
            case .kaleidoscope: return "kaleidoscopePattern"
            case .magnetic: return "magneticPattern"
            case .growth: return "growthPattern"
            case .tunnel: return "tunnelPattern"
            case .interference: return "interferencePattern"
            }
        }
        
        var defaultSpeed: Double {
            switch self {
            case .wave: return 1.0
            case .pulse: return 0.9
            case .ripple: return 1.3
            case .noise: return 1.1
            case .cellular: return 0.8
            case .flowField: return 1.2
            case .gravity: return 1.0
            case .fractal: return 0.7
            case .kaleidoscope: return 0.6
            case .magnetic: return 1.1
            case .growth: return 0.8
            case .tunnel: return 1.4
            case .interference: return 1.0
            }
        }
    }
    
    func updatePattern(_ pattern: PatternType) {
        selectedPattern = pattern
        speed = pattern.defaultSpeed
    }
}
