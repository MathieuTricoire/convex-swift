import Foundation

@MainActor
class NewClient {
    var deploymentURL: URL

    init(deploymentURL: URL) {
        self.deploymentURL = deploymentURL
    }

    func subscribe(name: CanonicalizedUdfPath, args: FunctionArgs) {}
    func query(name: CanonicalizedUdfPath, args: FunctionArgs) {}
    func mutation(name: CanonicalizedUdfPath, args: FunctionArgs) {}
    func action(name: CanonicalizedUdfPath, args: FunctionArgs) {}

    func watchAll() {}
    func setAuth(token: String?) {}
    func setAdminAuth(deployKey: String, actingAs: String = "TODO type") {}
}