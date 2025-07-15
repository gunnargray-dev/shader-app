# ShaderApp 🎨

A mesmerizing SwiftUI iOS application that creates stunning animated dot patterns using Metal shaders and real-time GPU rendering.

[![iOS](https://img.shields.io/badge/iOS-17.6%2B-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-green.svg)](https://developer.apple.com/xcode/swiftui/)
[![Metal](https://img.shields.io/badge/Metal-3.0-red.svg)](https://developer.apple.com/metal/)
[![Xcode](https://img.shields.io/badge/Xcode-15.0%2B-blue.svg)](https://developer.apple.com/xcode/)

## ✨ Features

- **13 Unique Shader Patterns**: From flowing waves to hypnotic spirals, each pattern offers a unique visual experience
- **Real-time GPU Rendering**: Powered by Metal shaders for smooth 60fps performance
- **Interactive Controls**: Intuitive settings panel with real-time parameter adjustments
- **Customizable Parameters**:
  - Density (grid spacing)
  - Dot size
  - Animation speed
  - Color hue with HSV color picker
  - Bloom intensity and radius
  - Brightness control
- **Dark Mode Optimized**: Designed specifically for dark environments
- **Smooth Animations**: Fluid transitions and responsive controls

## 🎯 Pattern Types

| Pattern | Description |
|---------|-------------|
| **Wave** | Flowing ocean-like wave patterns |
| **Pulse** | Hypnotic breathing pulse effects |
| **Spiral** | Galactic spiral vortex animations |
| **Noise** | Organic perlin noise movements |
| **Cellular** | Cellular automata-inspired patterns |
| **Flow Field** | Vector field-based dot movements |
| **Gravity** | Gravitational force simulations |
| **Fractal** | Mathematical fractal visualizations |
| **Kaleidoscope** | Symmetric kaleidoscope effects |
| **Magnetic** | Magnetic field-inspired patterns |
| **Growth** | Organic growth simulations |
| **Tunnel** | 3D tunnel depth effects |
| **Interference** | Wave interference patterns |

## 📱 Screenshots

*Add screenshots of your app here to showcase the different patterns and UI*

## 🚀 Installation

### Prerequisites

- **Xcode 15.0+**
- **iOS 17.6+** deployment target
- **macOS 14.0+** (for development)
- **Metal-compatible device** (iPhone 6s or newer)

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/ShaderApp.git
   cd ShaderApp
   ```

2. **Open in Xcode**
   ```bash
   open ShaderApp.xcodeproj
   ```

3. **Build and Run**
   - Select your target device or simulator
   - Press `⌘ + R` to build and run

### Bundle Identifier

The app uses the bundle identifier: `com.ggray225-gmail.ShaderApp`

## 🎮 Usage

1. **Launch the app** - The app opens with a beautiful wave pattern by default
2. **Access settings** - The settings panel automatically appears at the bottom
3. **Select patterns** - Scroll through the pattern buttons to switch between different effects
4. **Adjust parameters**:
   - **Density**: Controls the spacing between dots
   - **Dot Size**: Adjusts the size of individual dots
   - **Speed**: Controls animation speed
   - **Color**: Toggle color mode and adjust hue with the rainbow slider
   - **Bloom**: Adds glow effects (expand settings for full controls)
   - **Brightness**: Overall brightness multiplier

## 🔧 Technical Details

### Architecture

- **Framework**: SwiftUI with Metal integration
- **Rendering**: Real-time GPU shaders using Metal Shading Language
- **State Management**: ObservableObject pattern with Combine
- **Animation**: TimelineView for smooth 60fps updates

### Key Components

#### `DotGridView`
- Main rendering view that applies Metal shaders
- Handles shader parameter binding and real-time updates
- Implements safety checks for Metal rendering

#### `GridSettings`
- Observable settings model with published properties
- Manages all shader parameters and pattern selection
- Provides pattern-specific default values

#### `DotPatterns.metal`
- Metal shader implementations for all 13 patterns
- Optimized GPU functions for perfect circular dot rendering
- Advanced effects including bloom, HSV color conversion, and noise functions

#### `SettingsSheet`
- Adaptive UI that adjusts based on available space
- Custom color picker with rainbow gradient
- Smooth animations and responsive controls

### Performance

- **60fps** smooth animations on all supported devices
- **GPU-accelerated** rendering using Metal shaders
- **Memory efficient** with minimal CPU overhead
- **Responsive** real-time parameter updates

## 🛠️ Development

### Code Structure

```
ShaderApp/
├── Models/
│   └── GridSettings.swift          # Settings and state management
├── Views/
│   ├── ContentView.swift           # Main app view
│   ├── DotGridView.swift           # Shader rendering view
│   └── SettingsSheet.swift         # Control panel UI
├── Shaders/
│   └── DotPatterns.metal           # Metal shader implementations
└── Assets.xcassets/                # App icons and assets
```

### Adding New Patterns

1. **Add pattern case** to `PatternType` enum in `GridSettings.swift`
2. **Implement shader** function in `DotPatterns.metal`
3. **Add switch case** in `DotGridView.swift` shader selection
4. **Set default parameters** in `GridSettings.swift`

### Metal Shader Guidelines

- Use `perfectCircularDot()` function for consistent dot rendering
- Implement `applyBloom()` for glow effects
- Follow the established parameter structure:
  - `float2 size` - Screen dimensions
  - `float time` - Animation time
  - `float density` - Grid density
  - `float dotSize` - Dot size multiplier
  - `float colorHue` - Color hue value
  - `float colorEnabled` - Color toggle
  - `float bloomIntensity` - Bloom intensity
  - `float bloomRadius` - Bloom radius
  - `float brightness` - Brightness multiplier

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/new-pattern
   ```
3. **Make your changes**
4. **Test thoroughly** on device
5. **Submit a pull request**

### Contribution Ideas

- New shader patterns
- Performance optimizations
- UI/UX improvements
- Additional customization options
- iPad support
- macOS compatibility

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Gunnar Gray**
- Email: ggray225@gmail.com
- GitHub: [@yourusername](https://github.com/yourusername)

## 🙏 Acknowledgments

- Apple's Metal documentation and examples
- SwiftUI community for inspiration
- Mathematical patterns and shader techniques from the graphics programming community

## 📚 Resources

- [Apple Metal Programming Guide](https://developer.apple.com/metal/)
- [SwiftUI Documentation](https://developer.apple.com/xcode/swiftui/)
- [Metal Shading Language Specification](https://developer.apple.com/metal/Metal-Shading-Language-Specification.pdf)

---

*Built with ❤️ using SwiftUI and Metal* 