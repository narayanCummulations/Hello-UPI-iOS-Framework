import Foundation
import SwiftUI

// MARK: - SDK Configuration

public struct SDKConfiguration {
    let environment: String
    let language: Language
    let email: String
    let bic: String
    let subscriptionKey: String
    let image1: UIImage
    let image2: UIImage
    let image3: UIImage
    let onDismiss: () -> Void
    
    public init(environment: String, language: Language, email: String, bic: String, subscriptionKey: String, image1: UIImage, image2: UIImage, image3: UIImage, onDismiss: @escaping () -> Void) {
        self.environment = environment
        self.language = language
        self.email = email
        self.bic = bic
        self.subscriptionKey = subscriptionKey
        self.image1 = image1
        self.image2 = image2
        self.image3 = image3
        self.onDismiss = onDismiss
    }
}

// MARK: - Main SDK Class

public class MySDK {
    public static let shared = MySDK()
    var configuration: SDKConfiguration?
    
    @Binding var showBottomSheet : Bool

    private init() {
        self._showBottomSheet = Binding.constant(false)
    }
    
    public func initialize(with config: SDKConfiguration) {
        self.configuration = config
        // Perform any necessary initialization logic here
        print("SDK initialized with configuration: \(config)")
    }
    
    public func getSDKView() -> some View {
        guard let config = configuration else {
            return AnyView(Text("SDK not initialized"))
        }
        return AnyView(BottomSheetView(config: config, content: {
            EmptyView()
        }))
    }
}

// MARK: - SDK Test Main View

struct SDKTestMainView: View {
    let config: SDKConfiguration
    
    var body: some View {
        VStack {
            Text("SDK Environment: \(config.environment)")
            Text("Language: \(config.language)")
            Text("Email: \(config.email)")
            Text("BIC: \(config.bic)")
            
            HStack {
                Image(uiImage: config.image1)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 50)
                Image(uiImage: config.image2)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 50)
                Image(uiImage: config.image3)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 50)
            }
        }
    }
}
