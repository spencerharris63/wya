import Foundation
import CoreLocation

struct Event: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let coordinate: CLLocationCoordinate2D
    let startTime: Date
    let endTime: Date
    let isPrivate: Bool
    let photoURLs: [String]  // URLs for uploaded images
    let creatorId: String
    var attendees: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case latitude
        case longitude
        case startTime
        case endTime
        case isPrivate
        case photoURLs
        case creatorId
        case attendees
    }

    // Manually decode CLLocationCoordinate2D from latitude and longitude
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(String.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.description = try container.decode(String.self, forKey: .description)
        let lat = try container.decode(CLLocationDegrees.self, forKey: .latitude)
        let lng = try container.decode(CLLocationDegrees.self, forKey: .longitude)
        self.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        self.startTime = try container.decode(Date.self, forKey: .startTime)
        self.endTime = try container.decode(Date.self, forKey: .endTime)
        self.isPrivate = try container.decode(Bool.self, forKey: .isPrivate)
        self.photoURLs = try container.decode([String].self, forKey: .photoURLs)
        self.creatorId = try container.decode(String.self, forKey: .creatorId)
        self.attendees = try container.decode([String].self, forKey: .attendees)
    }

    // Manually encode CLLocationCoordinate2D as latitude and longitude
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(endTime, forKey: .endTime)
        try container.encode(isPrivate, forKey: .isPrivate)
        try container.encode(photoURLs, forKey: .photoURLs)
        try container.encode(creatorId, forKey: .creatorId)
        try container.encode(attendees, forKey: .attendees)
    }

    // Init for use in code (when not decoding from Firestore)
    init(id: String = UUID().uuidString,
         title: String,
         description: String,
         coordinate: CLLocationCoordinate2D,
         startTime: Date,
         endTime: Date,
         isPrivate: Bool,
         photoURLs: [String] = [],
         creatorId: String,
         attendees: [String] = []) {
        self.id = id
        self.title = title
        self.description = description
        self.coordinate = coordinate
        self.startTime = startTime
        self.endTime = endTime
        self.isPrivate = isPrivate
        self.photoURLs = photoURLs
        self.creatorId = creatorId
        self.attendees = attendees
    }
}
