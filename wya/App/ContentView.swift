import SwiftUI
import MapKit
import CoreLocation
import FirebaseFirestore
import FirebaseAuth

struct FriendLocation: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
}

// A class to manage location permission and updates
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var db = Firestore.firestore( )
    
    @Published var friends: [FriendLocation] = []

    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    @Published var location: CLLocationCoordinate2D?  // Store last known location
    @Published var shouldFollowUser = true             // Controls auto-centering

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        startListeningForFriends()  // Start listening for friends' locations
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.first else { return }

        DispatchQueue.main.async {
            self.location = latest.coordinate
            if self.shouldFollowUser {
                self.region = MKCoordinateRegion(
                    center: latest.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            }
            self.uploadLocation(latest.coordinate)
        }
    }

    // Upload user location to Firestore
    private func uploadLocation(_ coordinate: CLLocationCoordinate2D) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let locationData: [String: Any] = [
            "lat": coordinate.latitude,
            "lng": coordinate.longitude,
            "updatedAt": Date().timeIntervalSince1970
        ]

        db.collection("users").document(uid).setData(["location": locationData], merge: true)
    }
    
    func startListeningForFriends() {
        db.collection("users").addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else {
                print("No documents or error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            guard let currentUserID = Auth.auth().currentUser?.uid else { return }

            let newFriends = documents.compactMap { doc -> FriendLocation? in
                if doc.documentID == currentUserID { return nil }

                if let loc = doc.data()["location"] as? [String: Any],
                   let lat = loc["lat"] as? CLLocationDegrees,
                   let lng = loc["lng"] as? CLLocationDegrees {

                    return FriendLocation(id: doc.documentID, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng))
                }
                return nil
            }

            DispatchQueue.main.async {
                self.friends = newFriends
            }
        }
    }
}

// Unified map item enum to represent both friends and events
enum MapItem: Identifiable {
    case friend(FriendLocation)
    case event(Event)

    var id: String {
        switch self {
        case .friend(let f): return "friend-\(f.id)"
        case .event(let e): return "event-\(e.id)"
        }
    }

    var coordinate: CLLocationCoordinate2D {
        switch self {
        case .friend(let f): return f.coordinate
        case .event(let e): return e.coordinate
        }
    }
}

//Map Initializer and Controls
struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var tracking: MapUserTrackingMode = .follow
    @StateObject private var eventViewModel = EventViewModel()
    @State private var selectedEvent: Event?
    @State private var showEventDetail = false

    var body: some View {
        ZStack {
            let allMapItems: [MapItem] = locationManager.friends.map { .friend($0) } + eventViewModel.events.map { .event($0) }

            Map(coordinateRegion: $locationManager.region,
                interactionModes: [.all],
                showsUserLocation: true,
                userTrackingMode: $tracking,
                annotationItems: allMapItems) { item in
                if case .friend(let friend) = item {
                    AnyView(
                        MapAnnotation(coordinate: friend.coordinate) {
                            Circle()
                                .fill(Color.pink)
                                .frame(width: 14, height: 14)
                        }
                    )
                } else if case .event(let event) = item {
                    AnyView(
                        MapAnnotation(coordinate: event.coordinate) {
                            Button {
                                selectedEvent = event
                                showEventDetail = true
                            } label: {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(event.isPrivate ? .gray : .blue)
                                    .font(.title)
                            }
                        }
                    )
                }
            }
            .edgesIgnoringSafeArea(.all)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if locationManager.shouldFollowUser {
                            locationManager.shouldFollowUser = false
                            tracking = .none
                        }
                    }
            )
            .fullScreenCover(isPresented: $showEventDetail) {
                if let selectedEvent = selectedEvent {
                    EventOverlayView(event: selectedEvent)
                }
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        // Zoom in button
                        Button(action: {
                            withAnimation {
                                zoom(factor: 0.5)
                                locationManager.shouldFollowUser = false
                                tracking = .none
                            }
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 18))
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.8))
                                .clipShape(Circle())
                                .shadow(radius: 3)
                        }

                        // Zoom out button
                        Button(action: {
                            withAnimation {
                                zoom(factor: 2.0)
                                locationManager.shouldFollowUser = false
                                tracking = .none
                            }
                        }) {
                            Image(systemName: "minus")
                                .font(.system(size: 18))
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.8))
                                .clipShape(Circle())
                                .shadow(radius: 3)
                        }
                        // Snap to current location button (inverted colors)
                        Button(action: {
                            if let userLocation = locationManager.location {
                                withAnimation {
                                    locationManager.region = MKCoordinateRegion(
                                        center: userLocation,
                                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                    )
                                    locationManager.shouldFollowUser = true
                                    tracking = .follow
                                }
                            }
                        }) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 18))
                                .frame(width: 35, height: 35)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue.opacity(0.9))
                                .clipShape(Circle())
                                .shadow(radius: 3)
                        }
                    }
                }
                .padding(.trailing, 16)
                .padding(.bottom, 0)
            }
        }
    }

    private func zoom(factor: Double) {
        let currentRegion = locationManager.region
        let newSpan = MKCoordinateSpan(
            latitudeDelta: currentRegion.span.latitudeDelta * factor,
            longitudeDelta: currentRegion.span.longitudeDelta * factor
        )
        locationManager.region = MKCoordinateRegion(center: currentRegion.center, span: newSpan)
    }
}

#Preview {
    ContentView()
}
