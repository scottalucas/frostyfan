//
//  Utilities.swift
//  whf001
//
//  Created by Scott Lucas on 12/10/20.
//

import Foundation
import SwiftUI
import Combine

extension Image {
    static var fanLarge = Image("fanLarge")
    static var fanIcon = Image("fanIcon")
    static var flame = Image(systemName: "flame.fill")
    static var interlock = Image(systemName: "wind")
    static var leaf = Image(systemName: "leaf.arrow.circlepath")
    static var network = Image(systemName: "link")
    static var question = Image(systemName: "questionmark")
    static var settings = Image(systemName: "gear")
    static var speed = Image(systemName: "speedometer")
    static var thermometer = Image(systemName: "thermometer")
    static var timer = Image(systemName: "timer")
    static var rainDrops =  Image(systemName: "cloud.sun")
    static var bell = Image(systemName: "bell")
}

extension UIColor {
    static var main = #colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1)
    static var alarm = #colorLiteral(red: 0.6840745905, green: 0.0425841135, blue: 0.1318473293, alpha: 0.7751843718)
    static var background = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
}

extension Color {
    static var main = Color(UIColor.main)
    static var alarm = Color(UIColor.alarm)
    static var background = Color(UIColor.background)
}

extension View {
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
}


struct RefreshableScrollView<Content: View>: View {
    @State private var previousScrollOffset: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var frozen: Bool = false
    @State private var rotation: Angle = .degrees(0)
    
    var threshold: CGFloat = 80
    @Binding var refreshing: Bool
    let content: Content

    init(height: CGFloat = 80, refreshing: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self.threshold = height
        self._refreshing = refreshing
        self.content = content()

    }
    
    var body: some View {
        return VStack {
            ScrollView {
                ZStack(alignment: .top) {
                    MovingView()
                    
                    VStack { self.content }.alignmentGuide(.top, computeValue: { d in (self.refreshing && self.frozen) ? -self.threshold : 0.0 })
                    
                    SymbolView(height: self.threshold, loading: self.refreshing, frozen: self.frozen, rotation: self.rotation)
                }
            }
            .background(FixedView())
            .onPreferenceChange(RefreshableKeyTypes.PrefKey.self) { values in
                self.refreshLogic(values: values)
            }
        }
    }
    
    func refreshLogic(values: [RefreshableKeyTypes.PrefData]) {
        DispatchQueue.main.async {
            // Calculate scroll offset
            let movingBounds = values.first { $0.vType == .movingView }?.bounds ?? .zero
            let fixedBounds = values.first { $0.vType == .fixedView }?.bounds ?? .zero
            
            self.scrollOffset  = movingBounds.minY - fixedBounds.minY
            
            self.rotation = self.symbolRotation(self.scrollOffset)
            
            // Crossing the threshold on the way down, we start the refresh process
            if !self.refreshing && (self.scrollOffset > self.threshold && self.previousScrollOffset <= self.threshold) {
                self.refreshing = true
            }
            
            if self.refreshing {
                // Crossing the threshold on the way up, we add a space at the top of the scrollview
                if self.previousScrollOffset > self.threshold && self.scrollOffset <= self.threshold {
                    self.frozen = true

                }
            } else {
                // remove the sapce at the top of the scroll view
                self.frozen = false
            }
            
            // Update last scroll offset
            self.previousScrollOffset = self.scrollOffset
        }
    }
    
    func symbolRotation(_ scrollOffset: CGFloat) -> Angle {
        
        // We will begin rotation, only after we have passed
        // 60% of the way of reaching the threshold.
        if scrollOffset < self.threshold * 0.60 {
            return .degrees(0)
        } else {
            // Calculate rotation, based on the amount of scroll offset
            let h = Double(self.threshold)
            let d = Double(scrollOffset)
            let v = max(min(d - (h * 0.6), h * 0.4), 0)
            return .degrees(180 * v / (h * 0.4))
        }
    }
    
    struct SymbolView: View {
        var height: CGFloat
        var loading: Bool
        var frozen: Bool
        var rotation: Angle
        
        
        var body: some View {
            Group {
                if self.loading { // If loading, show the activity control
                    VStack {
                        Spacer()
                        ActivityRep()
                        Spacer()
                    }.frame(height: height).fixedSize()
                        .offset(y: -height + (self.loading && self.frozen ? height : 0.0))
                } else {
                    Image(systemName: "arrow.down") // If not loading, show the arrow
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: height * 0.25, height: height * 0.25).fixedSize()
                        .padding(height * 0.375)
                        .rotationEffect(rotation)
                        .offset(y: -height + (loading && frozen ? +height : 0.0))
                }
            }
        }
    }
    
    struct MovingView: View {
        var body: some View {
            GeometryReader { proxy in
                Color.clear.preference(key: RefreshableKeyTypes.PrefKey.self, value: [RefreshableKeyTypes.PrefData(vType: .movingView, bounds: proxy.frame(in: .global))])
            }.frame(height: 0)
        }
    }
    
    struct FixedView: View {
        var body: some View {
            GeometryReader { proxy in
                Color.clear.preference(key: RefreshableKeyTypes.PrefKey.self, value: [RefreshableKeyTypes.PrefData(vType: .fixedView, bounds: proxy.frame(in: .global))])
            }
        }
    }
}

struct RefreshableKeyTypes {
    enum ViewType: Int {
        case movingView
        case fixedView
    }

    struct PrefData: Equatable {
        let vType: ViewType
        let bounds: CGRect
    }

    struct PrefKey: PreferenceKey {
        static var defaultValue: [PrefData] = []

        static func reduce(value: inout [PrefData], nextValue: () -> [PrefData]) {
            value.append(contentsOf: nextValue())
        }

        typealias Value = [PrefData]
    }
}

struct ActivityRep: UIViewRepresentable {
    func makeUIView(context: UIViewRepresentableContext<ActivityRep>) -> UIActivityIndicatorView {
        return UIActivityIndicatorView()
    }
    
    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityRep>) {
        uiView.startAnimating()
    }
}

struct RangeSliderHandle: View {
    enum HandlePosition { case lower, upper }
    @Binding var value: Double
    var handleSize: CGSize = CGSize(width: 27.0, height: 27.0)
    var shadowColor: Color = Color.black.opacity(0.2)
    var shadowRadius: CGFloat
    var shadowOffset: CGSize
    var fill: Color = .white
    var strokeColor: Color = .gray
    var strokeLineWidth: CGFloat = 0.0
//    var style: RangeSliderStyle
    
    var body: some View {
        Circle ()
            .size(handleSize)
            .fill(fill)
            .overlay(Circle()
                        .size(handleSize)
                        .stroke(lineWidth: strokeLineWidth)
                        .foregroundColor(strokeColor))
            .overlay(Text(String(format: "%3.0f\u{00B0}", value))
                        .offset(x: 0, y: -handleSize.height * 1.5)
                        .frame(width: 50, height: nil, alignment: .center))
            .shadow(color: shadowColor, radius: shadowRadius, x: shadowOffset.width, y: shadowOffset.height)
            .frame(width: handleSize.width, height: handleSize.height, alignment: .center)
    }
    
    init(_ value: Binding<Double>, position pos: HandlePosition = .lower, style: RangeSlider.Style = RangeSlider.Style()) {
        _value = value
        handleSize = CGSize(width: style.handleSize, height: style.handleSize)
        shadowColor = style.handleShadowColor
        shadowRadius = style.handleShadowRadius
        shadowOffset = style.handleShadowOffset
        if pos == .lower {
            fill = style.lowHandleFill
            strokeColor = style.lowHandleStrokeColor
            strokeLineWidth = style.lowHandleStrokeWeight
        } else {
            fill = style.highHandleFill
            strokeColor = style.highHandleStrokeColor
            strokeLineWidth = style.highHandleStrokeWeight
        }
    }
}

struct WidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct SizeModifier: ViewModifier {
    private var sizeView: some View {
        GeometryReader { geometry in
            Color.clear.preference(key: WidthPreferenceKey.self, value: geometry.size.width)
        }
    }

    func body(content: Content) -> some View {
        content.background(sizeView)
    }
}

extension RangeSlider {
    struct Style {
        var lowActualValue: Double = 0
        var highActualValue: Double = 1
        var barBackgroundColor = Color.black.opacity(0.15)
        var barStrokeColor: Color = .clear
        var barStrokeWeight: CGFloat = 0.0
        var barSelectedColor: Color = Color(UIColor.systemBlue)
        var barSelectedStrokeColor = Color(UIColor.clear)
        var barSelectedStrokeWeight: CGFloat = 0.0
        var handleSize: CGFloat = 27.0
        var handleShadowColor: Color = Color.black.opacity(0.15)
        var handleShadowRadius: CGFloat = 2.0
        var handleShadowOffset: CGSize = CGSize(width: 1, height: 1)
        var barHeight: CGFloat = 4.0
        var lowHandleFill: Color = .white
        var lowHandleStrokeColor: Color = .clear
        var lowHandleStrokeWeight: CGFloat = 0.5
        var highHandleFill: Color = .white
        var highHandleStrokeColor: Color = .clear
        var highHandleStrokeWeight: CGFloat = 0.5
        var minHandleSeparation: Double { //percent
            set {
                if newValue < 0.01 { _minHandleSeparation = 0.01
                } else if newValue > 0.99 {
                    _minHandleSeparation = 0.99
                } else {
                    _minHandleSeparation = newValue
                }
                
            }
            get {
                return _minHandleSeparation
            }
        }
        private var _minHandleSeparation: Double = 0.2
    }
}

struct RangeSlider: View {
    //unit = base value
    @Binding var lowValue: Double
    {
        willSet {
            offsetLow = maxWidth * CGFloat((newValue - minValue) / (maxValue - minValue))
        }
    }
    @Binding var highValue: Double
    {
        willSet {
            offsetHigh = maxWidth * CGFloat((newValue - minValue) / (maxValue - minValue))
        }
    }
    var minValue: Double
    var maxValue: Double
    var style: Style
    
    //unit = pixel
    @State private var offsetLowBookmark: CGFloat = .zero
    @State private var offsetHighBookmark: CGFloat = .infinity
    @State private var offsetLow: CGFloat = .zero
    @State private var offsetHigh: CGFloat = .infinity
    @State private var maxWidth: CGFloat = .infinity
    
    //unit = percent
    private var lowerHandleUpperBound: Double {
        Double(offsetHigh / maxWidth) - style.minHandleSeparation
    }
    private var upperHandleLowerBound: Double {
        Double(offsetLow / maxWidth) + style.minHandleSeparation
    }
    
    var body: some View {
        ZStack (alignment: Alignment(horizontal: .leading, vertical: .center)) {
            Group {
                RoundedRectangle(cornerRadius: style.barHeight / 2)
                    .fill(style.barBackgroundColor)
                    .padding([.leading, .trailing], 5)
                Rectangle ()
                    .size(width: (offsetHigh - offsetLow), height: style.barHeight)
                    .fill(style.barSelectedColor)
                    .offset(x: offsetLow, y: 0)
            }
            .frame(width: nil, height: style.barHeight, alignment: .center)
            //low handle
            RangeSliderHandle($lowValue, position: .lower, style: style)
                .gesture(
                    DragGesture (minimumDistance: 0.0, coordinateSpace: .global)
                        .onChanged { drag in
                            let positionPercent = Double((offsetLowBookmark + drag.translation.width) / maxWidth).clamped(to: .zero...lowerHandleUpperBound)
                            lowValue = positionPercent * (maxValue - minValue) + minValue
                        }
                        .onEnded({ drag in
                            offsetLowBookmark = offsetLow
                        }))
                .offset(x: offsetLow, y: 0)
            //high handle
            RangeSliderHandle($highValue, position: .upper, style: style)
                .gesture (
                    DragGesture (minimumDistance: 0.0, coordinateSpace: .global)
                        .onChanged { drag in
                            let positionPercent = Double((offsetHighBookmark + drag.translation.width) / maxWidth).clamped(to: upperHandleLowerBound...1.0)
                            highValue = positionPercent * (maxValue - minValue) + minValue
                        }
                        .onEnded({ drag in
                            offsetHighBookmark = min (maxWidth, offsetHigh)
                        }))
                .offset(x: offsetHigh, y: 0)
        }
        .modifier(SizeModifier())
        .onPreferenceChange(WidthPreferenceKey.self) { width in
            maxWidth = width - style.handleSize
            offsetHigh = CGFloat( ( highValue - minValue) / (maxValue - minValue) ) * (maxWidth)
            offsetHighBookmark = offsetHigh
            offsetLow = CGFloat( ( lowValue - minValue) / (maxValue - minValue) ) * (maxWidth)
            offsetLowBookmark = offsetLow
        }
    }
    
    init (selectedLow low: Binding<Double>, selectedHigh high: Binding<Double>, minimum min: Double, maximum max: Double, _ style: () -> Style = { Style() }) {
        _lowValue = low
        _highValue = high
        minValue = min
        maxValue = max
        self.style = style()
    }
//    
//    func style(_ sliderStyle: () -> RangeSlider.Style) -> some View {
//        return RangeSlider(lowValue: $lowValue, highValue: $highValue, minValue: self.minValue, maxValue: self.maxValue, style: sliderStyle())
//    }
}

struct SliderTest: View {
    @Binding var sliderValue: Double

    var body: some View {
        Slider(value: $sliderValue)

    }
}

struct Utilities_Previews: PreviewProvider {
//        @ObservedObject var slider = CustomSlider(start: 10, end: 100)
    @State static var sliderVal: Double = 0.5
    @State static var lowVal: Double = 45
    @State static var highVal: Double = 80
    static var previews: some View {
//        HStack {
//            Spacer()
//            VStack {
////                Image.fanLarge
//                RangeSlider(lowValue: $lowVal, highValue: $highVal, minValue: 40, maxValue: 85)
//                    .padding(50)
////                    .frame(width: nil, height: nil, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                Text("Low: \(lowVal)")
//                Text("High: \(highVal)")
//            }
//            Spacer ()
//            VStack {
//                Spacer ()
//                Image.settings
//                Image.speed
//                Image.thermometer
//                Image.timer
//                Image.rainDrops
//                Color.main
//                    .frame(width: 25, height: 25, alignment: .center)
//            }
//            Spacer()
//        }
    }
}
