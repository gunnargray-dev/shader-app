import SwiftUI

struct SettingsSheet: View {
    @ObservedObject var settings: GridSettings
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Custom drag indicator
                RoundedRectangle(cornerRadius: 2)
                    .fill(.secondary)
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                
                // Pattern Selection - Always visible
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pattern")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 24)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(GridSettings.PatternType.allCases, id: \.self) { pattern in
                                Button(pattern.rawValue) {
                                    settings.updatePattern(pattern)
                                }
                                .buttonStyle(PatternButtonStyle(isSelected: settings.selectedPattern == pattern))
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
                
                // Full controls - Only show when there's enough space
                if geometry.size.height > 200 {
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
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    
                    Spacer(minLength: 20)
                }
            }
            .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 20)
        }
        .background(.ultraThinMaterial)
    }
}

struct PatternButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.callout, design: .rounded, weight: .medium))
            .foregroundColor(isSelected ? .black : .primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .fixedSize() // Prevents compression and ensures proper text sizing
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? .white : .clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
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
            
            // Always reserve space for the slider to prevent layout shifts
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
                .opacity(isEnabled ? 1.0 : 0.3)
                
                CustomColorSlider(value: $hue)
                    .disabled(!isEnabled)
                    .opacity(isEnabled ? 1.0 : 0.3)
            }
            .scaleEffect(isEnabled ? 1.0 : 0.95)
            .animation(.easeInOut(duration: 0.25), value: isEnabled)
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
