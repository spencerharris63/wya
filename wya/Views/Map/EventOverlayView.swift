import SwiftUI

struct EventOverlayView: View {
    let event: Event
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Event Title:")
                .font(.headline)

            Text(event.title)
                .font(.title)
                .bold()

            Text("Event Description:")
                .font(.headline)

            Text(event.description)
                .padding()

            Button("Close") {
                dismiss()
            }
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
        .background(Color.white)
    }
}
