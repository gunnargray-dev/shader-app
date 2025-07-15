import SwiftUI

struct ContentView: View {
    @StateObject private var settings = GridSettings()
    @State private var showingSettings = true // Always show sheet
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            DotGridView(
                settings: settings,
                ripplePoints: []
            )
        }
        .sheet(isPresented: $showingSettings) {
            SettingsSheet(settings: settings)
                .presentationDetents([.height(120), .height(450)]) // Reduced height - just enough for color slider at bottom
                .presentationCornerRadius(36)
                .presentationBackground(.clear)
                .presentationDragIndicator(.hidden) // Hide the default drag indicator
                .interactiveDismissDisabled() // Prevent accidental dismissal
        }
    }

}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
