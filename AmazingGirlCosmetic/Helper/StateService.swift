import Foundation
import Combine

@MainActor
final class StateService: ObservableObject {
    
    enum States {
        case request
        case support
        case loading
    }
    
    @Published private(set) var appState: States = .request
    let networkManager: NetworkService
    
    init(networkManager: NetworkService) {
        self.networkManager = networkManager
    }
    
    convenience init() {
        self.init(networkManager: NetworkService())
    }
    
    func stateRequest() {
        Task { @MainActor in
            do {
                if networkManager.petURL != nil {
                    appState = .support
                    return
                }
                
                let shouldShowWebView = try await networkManager.checkInitialURL()
                
                if shouldShowWebView {
                    appState = .support
                } else {
                    appState = .loading
                }
                
            } catch {
                appState = .loading
            }
        }
    }
}
