import SwiftUI

struct DotGridView: View {
    @ObservedObject var settings: GridSettings
    let ripplePoints: [CGPoint]
    @State private var startTime = Date.now
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsedTime = startTime.distance(to: timeline.date) * settings.speed
            
            Rectangle()
                .fill(.black)
                .background(.black)
                .visualEffect { content, proxy in
                    content
                        .colorEffect(
                            getDotGridShader(
                                size: proxy.size,
                                time: Float(elapsedTime),
                                density: Float(settings.density),
                                dotSize: Float(settings.dotSize),
                                colorHue: Float(settings.colorHue),
                                colorEnabled: settings.colorEnabled,
                                pattern: settings.selectedPattern
                            )
                        )
                }
        }
    }
    
    private func getDotGridShader(
        size: CGSize,
        time: Float,
        density: Float,
        dotSize: Float,
        colorHue: Float,
        colorEnabled: Bool,
        pattern: GridSettings.PatternType
    ) -> Shader {
        
        // Ensure size is valid to prevent Metal errors
        let safeSize = CGSize(
            width: max(size.width, 1.0),
            height: max(size.height, 1.0)
        )
        
        let bloomIntensity = Float(settings.bloomIntensity)
        let bloomRadius = Float(settings.bloomRadius)
        let brightness = Float(settings.brightness)
        
        switch pattern {
        case .wave:
            return ShaderLibrary.dotGridWave(
                .float2(safeSize),
                .float(time),
                .float(density),
                .float(dotSize),
                .float(colorHue),
                .float(colorEnabled ? 1.0 : 0.0),
                .float(bloomIntensity),
                .float(bloomRadius),
                .float(brightness)
            )
        case .pulse:
            return ShaderLibrary.dotGridPulse(
                .float2(safeSize),
                .float(time),
                .float(density),
                .float(dotSize),
                .float(colorHue),
                .float(colorEnabled ? 1.0 : 0.0),
                .float(bloomIntensity),
                .float(bloomRadius),
                .float(brightness)
            )
        case .ripple:
            return ShaderLibrary.dotGridRipple(
                .float2(safeSize),
                .float(time),
                .float(density),
                .float(dotSize),
                .float(colorHue),
                .float(colorEnabled ? 1.0 : 0.0),
                .float(bloomIntensity),
                .float(bloomRadius),
                .float(brightness)
            )
        case .noise:
            return ShaderLibrary.dotGridNoise(
                .float2(safeSize),
                .float(time),
                .float(density),
                .float(dotSize),
                .float(colorHue),
                .float(colorEnabled ? 1.0 : 0.0),
                .float(bloomIntensity),
                .float(bloomRadius),
                .float(brightness)
            )
        case .cellular:
            return ShaderLibrary.dotGridCellular(
                .float2(safeSize),
                .float(time),
                .float(density),
                .float(dotSize),
                .float(colorHue),
                .float(colorEnabled ? 1.0 : 0.0),
                .float(bloomIntensity),
                .float(bloomRadius),
                .float(brightness)
            )
        case .flowField:
            return ShaderLibrary.dotGridFlowField(
                .float2(safeSize),
                .float(time),
                .float(density),
                .float(dotSize),
                .float(colorHue),
                .float(colorEnabled ? 1.0 : 0.0),
                .float(bloomIntensity),
                .float(bloomRadius),
                .float(brightness)
            )
        case .gravity:
            return ShaderLibrary.dotGridGravity(
                .float2(safeSize),
                .float(time),
                .float(density),
                .float(dotSize),
                .float(colorHue),
                .float(colorEnabled ? 1.0 : 0.0),
                .float(bloomIntensity),
                .float(bloomRadius),
                .float(brightness)
            )
        case .fractal:
            return ShaderLibrary.dotGridFractal(
                .float2(safeSize),
                .float(time),
                .float(density),
                .float(dotSize),
                .float(colorHue),
                .float(colorEnabled ? 1.0 : 0.0),
                .float(bloomIntensity),
                .float(bloomRadius),
                .float(brightness)
            )
        case .kaleidoscope:
            return ShaderLibrary.dotGridKaleidoscope(
                .float2(safeSize),
                .float(time),
                .float(density),
                .float(dotSize),
                .float(colorHue),
                .float(colorEnabled ? 1.0 : 0.0),
                .float(bloomIntensity),
                .float(bloomRadius),
                .float(brightness)
            )
        case .magnetic:
            return ShaderLibrary.dotGridMagnetic(
                .float2(safeSize),
                .float(time),
                .float(density),
                .float(dotSize),
                .float(colorHue),
                .float(colorEnabled ? 1.0 : 0.0),
                .float(bloomIntensity),
                .float(bloomRadius),
                .float(brightness)
            )
        case .growth:
            return ShaderLibrary.dotGridGrowth(
                .float2(safeSize),
                .float(time),
                .float(density),
                .float(dotSize),
                .float(colorHue),
                .float(colorEnabled ? 1.0 : 0.0),
                .float(bloomIntensity),
                .float(bloomRadius),
                .float(brightness)
            )
        case .tunnel:
            return ShaderLibrary.dotGridTunnel(
                .float2(safeSize),
                .float(time),
                .float(density),
                .float(dotSize),
                .float(colorHue),
                .float(colorEnabled ? 1.0 : 0.0),
                .float(bloomIntensity),
                .float(bloomRadius),
                .float(brightness)
            )
        case .interference:
            return ShaderLibrary.dotGridInterference(
                .float2(safeSize),
                .float(time),
                .float(density),
                .float(dotSize),
                .float(colorHue),
                .float(colorEnabled ? 1.0 : 0.0),
                .float(bloomIntensity),
                .float(bloomRadius),
                .float(brightness)
            )
        }
    }
}
