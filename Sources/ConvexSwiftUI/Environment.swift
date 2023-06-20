import ConvexWebSocket
import SwiftUI

private struct ConvexClientKey: EnvironmentKey {
    static let defaultValue: ConvexClient? = nil
}

public extension EnvironmentValues {
    var convexClient: ConvexClient? {
        get { self[ConvexClientKey.self] }
        set { self[ConvexClientKey.self] = newValue }
    }
}

public extension View {
    func convexClient(_ convexClient: ConvexClient) -> some View {
        environment(\.convexClient, convexClient)
    }
}
