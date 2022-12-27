//
//  PartialModalViewBuilder.swift
//  SwiftUILab
//
//  Created by 박종우 on 2022/12/27.
//

import SwiftUI

enum PartialPresentStyle {
    case leftSlide
    case rightSlide
    case bottomPresent
}

struct PartialModal<PresentingView: View>: ViewModifier {
    
    @Binding var isPresented: Bool
    @State private var show: Bool = false
    @State var startAnimation: Bool = false
    @State var backgroundColor: Color = Color(uiColor: .systemBackground)
    
    let presentingView: PresentingView
    let presentStyle: PartialPresentStyle
    
    func body(content: Content) -> some View {
        GeometryReader { proxy in
            ZStack {
                content
                backgroundColor
                    .edgesIgnoringSafeArea(.all)
                    .opacity(startAnimation ? 1 : 0)
                    .onTapGesture { dismiss() }
                switch presentStyle {
                case .leftSlide, .rightSlide:
                    VStack(spacing: 0){
                        Spacer()
                        HStack(spacing: 0) {
                            if presentStyle == .rightSlide { Spacer() }
                            presentingView
                            if presentStyle == .leftSlide { Spacer() }
                        }
                        Spacer()
                    }
                case .bottomPresent:
                    VStack(spacing: 0) {
                        Spacer()
                        presentingView
                    }
                }
            }
            .onChange(of: isPresented) { newValue in
                if newValue {
                    self.show = true
                    withAnimation {
                        self.startAnimation = true
                    }
                }
                else {
                    withAnimation {
                        self.startAnimation = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.show = false
                    }
                }
            }
        }
    }
    
    
    private func dismiss() {
        isPresented = false
    }
    
    private func offset(_ geometryProxy: GeometryProxy) -> (x: CGFloat, y: CGFloat) {
        switch presentStyle {
        case .leftSlide:
            return startAnimation ? (0, 0) : (viewWidth(geometryProxy), 0)
        case .rightSlide:
            return startAnimation ? (0, 0) : (-viewWidth(geometryProxy), 0)
        case .bottomPresent:
            return startAnimation ? (0, 0) : (0, viewHeight(geometryProxy))
        }
    }
    
    private func viewHeight(_ geometry: GeometryProxy) -> CGFloat {
        return geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom
    }
    
    private func viewWidth(_ geometry: GeometryProxy) -> CGFloat {
        return geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing
    }
}


struct ViewPresentaionModeKey: EnvironmentKey {
    static let defaultValue: Binding<ViewPresentationMode> = .constant(ViewPresentationMode(dismissBinding: .constant(false)))
}

public extension EnvironmentValues {
    var viewPresentationMode: Binding<ViewPresentationMode> {
        get {
            self[ViewPresentaionModeKey.self]
        }
        set {
            self[ViewPresentaionModeKey.self] = newValue
        }
    }
}

public struct ViewPresentationMode {
    let dismissBinding: Binding<Bool>
    
    public var isPresented: Bool {
        dismissBinding.wrappedValue
    }
    
    public func dismiss() {
        withAnimation(.easeInOut) {
            dismissBinding.wrappedValue = false
        }
    }
}

extension View {
    func viewModal<Content: View>(isPresented: Binding<Bool>, style: PartialPresentStyle, @ViewBuilder view: () -> Content) -> some View {
        modifier(PartialModal(isPresented: isPresented, presentingView: view(), presentStyle: style))
            .environment(\.presentationMode, isPresented)
    }
    
    func viewModel<Content: View>(isPresented: Binding<Bool>, backgroundColor: Color, style: PartialPresentStyle, @ViewBuilder view: () -> Content) -> some View {
        modifier(PartialModal(isPresented: isPresented, backgroundColor: backgroundColor, presentingView: view(), presentStyle: style))
            .environment(\.viewPresentationMode, .constant(ViewPresentationMode(dismissBinding: isPresented)))
    }
}

