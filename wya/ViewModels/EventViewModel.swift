import Foundation
import FirebaseFirestore
import CoreLocation
import Combine
import SwiftUI

class EventViewModel: ObservableObject {
    @Published var events: [Event] = []
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?

    init() {
        fetchEvents()
    }

    deinit {
        listener?.remove()
    }

    func fetchEvents() {
        listener = db.collection("events").addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error fetching events: \(error.localizedDescription)")
                return
            }

            guard let documents = snapshot?.documents else {
                print("No event documents found")
                return
            }

            let fetchedEvents: [Event] = documents.compactMap { doc in
                let data = doc.data()
                guard
                    let title = data["title"] as? String,
                    let description = data["description"] as? String,
                    let lat = data["latitude"] as? CLLocationDegrees,
                    let lng = data["longitude"] as? CLLocationDegrees,
                    let startTimestamp = data["startTime"] as? Timestamp,
                    let endTimestamp = data["endTime"] as? Timestamp,
                    let isPrivate = data["isPrivate"] as? Bool,
                    let photoURLs = data["photoURLs"] as? [String],
                    let creatorId = data["creatorId"] as? String,
                    let attendees = data["attendees"] as? [String]
                else {
                    return nil
                }

                return Event(
                    id: doc.documentID,
                    title: title,
                    description: description,
                    coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                    startTime: startTimestamp.dateValue(),
                    endTime: endTimestamp.dateValue(),
                    isPrivate: isPrivate,
                    photoURLs: photoURLs,
                    creatorId: creatorId,
                    attendees: attendees
                )
            }

            DispatchQueue.main.async {
                self.events = fetchedEvents
            }
        }
    }
}
