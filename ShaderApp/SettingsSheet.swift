import SwiftUI

struct SettingsSheet: View {
    @ObservedObject var settings: GridSettings
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 32) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(.secondary)
                    .frame(width: 36, height: 4)
                    .padding(.top, 24)
                
                Text("Pattern Settings")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.primary)
            }
            
            // Pattern Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Pattern")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    ForEach(GridSettings.PatternType.allCases, id: \.self) { pattern in
                        Button(pattern.rawValue) {
                            settings.updatePattern(pattern)
                        }
                        .buttonStyle(PatternButtonStyle(isSelected: settings.selectedPattern == pattern))
                    }
                }
            }
            
            // Sliders
            VStack(spacing: 20) {
                SliderRow(
                    title: "Density",
                    value: $settings.density,
                    range: 0.2...1.0
                )
                
                SliderRow(
                    title: "Dot Size",
                    value: $settings.dotSize,
                    range: 0.1...1.0
                )
                
                SliderRow(
                    title: "Speed",
                    value: $settings.speed,
                    range: 0.1...2.0
                )
                
                ColorControlRow(
                    title: "Color",
                    hue: $settings.colorHue,
                    isEnabled: $settings.colorEnabled
                )
            }
            
            Spacer(minLength: 20)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 40)
        .background(.ultraThinMaterial)
    }
}

struct PatternButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .rounded, weight: .medium))
            .foregroundColor(isSelected ? .black : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? .white : .clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.secondary, lineWidth: isSelected ? 0 : 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SliderRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            Slider(value: $value, in: range)
                .tint(.white)
        }
    }
}

struct ColorControlRow: View {
    let title: String
    @Binding var hue: Double
    @Binding var isEnabled: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Toggle("", isOn: $isEnabled)
                    .labelsHidden()
            }
            
            if isEnabled {
                ZStack {
                    // Rainbow gradient background
                    LinearGradient(
                        colors: [
                            Color(hue: 0.0, saturation: 1.0, brightness: 1.0),
                            Color(hue: 0.17, saturation: 1.0, brightness: 1.0),
                            Color(hue: 0.33, saturation: 1.0, brightness: 1.0),
                            Color(hue: 0.5, saturation: 1.0, brightness: 1.0),
                            Color(hue: 0.67, saturation: 1.0, brightness: 1.0),
                            Color(hue: 0.83, saturation: 1.0, brightness: 1.0),
                            Color(hue: 1.0, saturation: 1.0, brightness: 1.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 30)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    
                    CustomColorSlider(value: $hue)
                }
                .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isEnabled)
    }
}

struct CustomColorSlider: UIViewRepresentable {
    @Binding var value: Double
    
    func makeUIView(context: Context) -> UISlider {
        let slider = UISlider()
        slider.minimumValue = 0.0
        slider.maximumValue = 1.0
        slider.value = Float(value)
        
        // Hide the track for this specific slider
        slider.minimumTrackTintColor = .clear
        slider.maximumTrackTintColor = .clear
        
        // White thumb
        slider.thumbTintColor = .white
        
        slider.addTarget(
            context.coordinator,
            action: #selector(Coordinator.valueChanged),
            for: .valueChanged
        )
        
        return slider
    }
    
    func updateUIView(_ uiView: UISlider, context: Context) {
        uiView.value = Float(value)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        let parent: CustomColorSlider
        
        init(_ parent: CustomColorSlider) {
            self.parent = parent
        }
        
        @objc func valueChanged(_ sender: UISlider) {
            parent.value = Double(sender.value)
        }
    }
}
