import SwiftUI

private struct ConvexClientKey: EnvironmentKey {
    static let defaultValue: Client? = nil
}

public extension EnvironmentValues {
    var convexClient: Client? {
        get { self[ConvexClientKey.self] }
        set { self[ConvexClientKey.self] = newValue }
    }
}

public extension View {
    func convexClient(_ client: Client) -> some View {
        environment(\.convexClient, client)
    }
}
