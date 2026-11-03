import SwiftUI

@main
struct IllusionApp: App {
    @StateObject private var studio = Studio()
    var body: some Scene {
        WindowGroup { StudioView().environmentObject(studio).tint(Color(red: 0.40, green: 0.49, blue: 0.27)) }
    }
}
