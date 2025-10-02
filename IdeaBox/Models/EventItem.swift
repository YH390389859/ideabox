import Foundation
import SwiftUI

enum EventType {
    case link
    case textDiary
    case voiceDiary
}

struct EventItem: Identifiable {
    let id = UUID()
    let type: EventType
    let time: String
    let title: String
    let subtitle: String
    let backgroundColor: Color
    let borderColor: Color
    let accentColor: Color
    let logoColor: Color
}

