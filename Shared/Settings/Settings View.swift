//
//  Settings View.swift
//  whf001
//
//  Created by Scott Lucas on 12/9/20.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State var lowVal: Double = 55
    @State var highVal: Double = 75
    @State var allowLocation: Bool = false
    
    var body: some View {
        ZStack {
            Color.main
                .ignoresSafeArea()
            VStack {
                SettingsBackgound()
                List {
                    Section(header: Text("Location")) {
                        Toggle(isOn: $allowLocation) {
                            Text("Allow location").foregroundColor(.main)
                        }
                    }
                    Section(header: Text("Outside temperature alerts")) {
                        Toggle(isOn: $allowLocation) {
                            Text("Enable").foregroundColor(.main)
                        }
                    }
                }
                .background(Color.main)
                .foregroundColor(.white)
                Spacer()
//                if viewModel.currentTemp != nil {
//                    Text(viewModel.currentTemp!)
//                }
//                if viewModel.locationAvailable == true && viewModel.location != nil {
//                    Text("Latitude: \(viewModel.location!.lat), Longitude: \(viewModel.location!.lon)")
//                }
            }
        }
        .listStyle(GroupedListStyle())
    }
    
    init () {
        viewModel = SettingsViewModel()
    }
}

struct TemperatureSelector: View {
    @Binding var lowTemp: Double
    @Binding var highTemp: Double
    private let min = 40.0
    private let max = 85.0
    
    var body: some View {
        RangeSlider(
            selectedLow: $lowTemp,
            selectedHigh: $highTemp,
            minimum: min,
            maximum: max,
            barFormatter: { style in
                style.barInsideFill = .white
                style.barOutsideStrokeColor = .white
                style.barOutsideStrokeWeight = 0.75
                style.barHeight = 7.0
            },
            rightHandleFormatter: { style in
                style.size = CGSize(width: 30, height: 30)
                style.strokeColor = .red
                style.strokeWeight = 2.0
                style.labelOffset = CGSize(width: 0, height: -30)
                style.labelStyle = RangeSlider.LabelStyle()
                style.labelStyle?
                    .numberFormat
                    .positiveFormat = "##\u{00B0}"
                style.labelStyle?.color = .white
            },
            leftHandleFormatter: { style in
                style.size = CGSize(width: 30, height: 30)
                style.strokeColor = .blue
                style.strokeWeight = 2.0
                style.labelOffset = CGSize(width: 0, height: -30)
                style.labelStyle = RangeSlider.LabelStyle()
                style.labelStyle?
                    .numberFormat
                    .positiveFormat = "##\u{00B0}"
                style.labelStyle?.color = .white
            })
    }
}

struct SettingsBackgound: View {
    var body: some View {
        ZStack {
            VStack (alignment: .center, spacing: 0) {
                HStack (alignment: .firstTextBaseline) {
                    Text("Settings").font(.largeTitle)
                        .foregroundColor(Color.background)
                    Spacer()
                }
                Divider()
                    .frame(width: nil, height: 1, alignment: .center)
                    .background(Color.background)
            }
            .padding()
        }
    }
}

struct Settings_View_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
