import SwiftUI

struct ContentView: View {
    @StateObject private var settings = GridSettings()
    @State private var showingSettings = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            DotGridView(
                settings: settings,
                ripplePoints: []
            )
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let startLocation = value.startLocation
                        let translation = value.translation
                        
                        // Detect upward swipe
                        if translation.height < -50 && abs(translation.width) < 100 {
                            showingSettings = true
                        }
                    }
            )
        }
        .sheet(isPresented: $showingSettings) {
            SettingsSheet(settings: settings)
                .presentationDetents([.height(480)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(36)
                .presentationBackground(.clear)
        }
    }

}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
