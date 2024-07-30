//
//  BottomSheetView.swift
//  Hello UPI iOS Framework
//
//  Created by Narayan Shettigar on 22/07/24.
//

import SwiftUI

public struct BottomSheetView<Content: View>: View {
    let config: SDKConfiguration
    let content: () -> Content
    
    @State private var heightSizeForScrollView: CGFloat = .zero
    
    public var body: some View {
        ZStack {
            
            // Background dimming view
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
            
            // Bottom sheet content
            VStack {
                Spacer()
                
                VStack(spacing: 0) {
                    HStack{
                        Image("img2")
                            .resizable()
                            .frame(width: 40, height: 30)
                            .onTapGesture {
                                config.onDismiss()
                            }
                        Image("img1")
                            .resizable()
                            .frame(width: 125, height: 40)
                        Spacer()
                        Image("img3")
                            .resizable()
                            .frame(width: 60, height: 25)
                    }
                    .padding()
                    Divider()
                    content()
                    ContentViewContacts()
                    AudioRecorderContentView()
                    WebSocketView()
                    VStack{}
                        .frame(height: 20)
                    
                }
                .background(
                    GeometryReader { geometry in
                        Color.white
                            .cornerRadius(20, corners: [.topLeft, .topRight])
                            .shadow(radius: 10)
                            .frame(height: geometry.size.height)
                            .onAppear {
                                self.heightSizeForScrollView = geometry.size.height
                            }
                    }
                )
                
            }
            
        }
        .edgesIgnoringSafeArea(.bottom)
        
    }
}

// Extension for corner radius
extension View {
    public func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// Shape for rounded corners
public struct RoundedCorner: Shape {
    public var radius: CGFloat = .infinity
    public var corners: UIRectCorner = .allCorners
    
    public func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
