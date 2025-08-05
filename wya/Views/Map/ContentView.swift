import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject var eventViewModel = EventViewModel()
    @StateObject var locationManager = LocationManager()
    
    @State private var tracking: MapUserTrackingMode = .follow
    @State private var selectedEvent: Event?
    
    var body: some View {
        Map(coordinateRegion: $locationManager.region,
            interactionModes: [.all],
            showsUserLocation: true,
            userTrackingMode: $tracking,
            annotationItems: eventViewModel.events) { event in
            
            MapAnnotation(coordinate: event.coordinate) {
                Button {
                    print("📍 Map pin tapped: \(event.title)")
                    selectedEvent = event
                } label: {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(event.isPrivate ? .gray : .blue)
                        .font(.title)
                }
            }
        }
            .edgesIgnoringSafeArea(.all)
            .sheet(item: $selectedEvent) { event in
                EventOverlayView(event: event)
                    .onAppear {
                        print("🟢 Showing overlay for event: \(event.title)")
                    }
            }
    }
}
