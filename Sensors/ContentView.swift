//
//  ContentView.swift
//  Sensors
//
//  Created by Devin Sewell on 11/2/25.

import SwiftUI
import CoreMotion

class SensorManager: ObservableObject {
    private let motion = CMMotionManager()
    private let altimeter = CMAltimeter()
    
    @Published var accel = (x: 0.0, y: 0.0, z: 0.0)
    @Published var gyro = (x: 0.0, y: 0.0, z: 0.0)
    @Published var mag = (x: 0.0, y: 0.0, z: 0.0)
    @Published var gravity = (x: 0.0, y: 0.0, z: 0.0)
    @Published var pressure = 0.0
    @Published var altitude = 0.0
    
    init() { start() }
    
    func start() {
        motion.deviceMotionUpdateInterval = 0.1
        motion.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
            guard let d = data else { return }
            self?.accel = (d.userAcceleration.x, d.userAcceleration.y, d.userAcceleration.z)
            self?.gyro = (d.rotationRate.x, d.rotationRate.y, d.rotationRate.z)
            self?.mag = (d.magneticField.field.x, d.magneticField.field.y, d.magneticField.field.z)
            self?.gravity = (d.gravity.x, d.gravity.y, d.gravity.z)
        }
        
        if CMAltimeter.isRelativeAltitudeAvailable() {
            altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, _ in
                guard let d = data else { return }
                self?.pressure = d.pressure.doubleValue
                self?.altitude = d.relativeAltitude.doubleValue
            }
        }
    }
}

struct SensorTile: View {
    var title: String
    var values: [Double]
    var colorA: Color
    var colorB: Color
    
    func colorMix(_ val: Double) -> Color {
        let t = min(max(abs(val) / 1.5, 0), 1)
        let c1 = UIColor(colorA)
        let c2 = UIColor(colorB)
        var r1: CGFloat=0,g1:CGFloat=0,b1:CGFloat=0,a1:CGFloat=0
        var r2: CGFloat=0,g2:CGFloat=0,b2:CGFloat=0,a2:CGFloat=0
        c1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        c2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return Color(red: Double(r1+(r2-r1)*CGFloat(t)),
                     green: Double(g1+(g2-g1)*CGFloat(t)),
                     blue: Double(b1+(b2-b1)*CGFloat(t)))
    }
    
    var body: some View {
        let avg = values.map { abs($0) }.reduce(0,+) / Double(values.count)
        ZStack {
            LinearGradient(colors: [colorMix(avg), colorMix(-avg)], startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                if values.count == 3 {
                    Text(String(format: "x:%+.2f y:%+.2f z:%+.2f", values[0], values[1], values[2]))
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.white.opacity(0.9))
                } else {
                    Text(String(format: "%+.2f", values[0]))
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .padding()
        }
    }
}

struct SensorGridView: View {
    @StateObject private var s = SensorManager()
    
    var body: some View {
        GeometryReader { geo in
            let cols = 2
            let rows = 3
            let tileW = geo.size.width / CGFloat(cols)
            let tileH = geo.size.height / CGFloat(rows)
            
            VStack(spacing: 0) {
                ForEach(0..<rows, id: \.self) { r in
                    HStack(spacing: 0) {
                        ForEach(0..<cols, id: \.self) { c in
                            let i = r * cols + c
                            let tiles: [(String,[Double],Color,Color)] = [
                                ("Accelerometer", [s.accel.x,s.accel.y,s.accel.z], .purple, .pink),
                                ("Gyroscope", [s.gyro.x,s.gyro.y,s.gyro.z], .orange, .red),
                                ("Magnetometer", [s.mag.x,s.mag.y,s.mag.z], .blue, .cyan),
                                ("Gravity", [s.gravity.x,s.gravity.y,s.gravity.z], .yellow, .orange),
                                ("Pressure", [s.pressure], .green, .mint),
                                ("Altitude", [s.altitude], .indigo, .teal)
                            ]
                            if i < tiles.count {
                                let t = tiles[i]
                                SensorTile(title: t.0, values: t.1, colorA: t.2, colorB: t.3)
                                    .frame(width: tileW, height: tileH)
                            } else {
                                Color.black.frame(width: tileW, height: tileH)
                            }
                        }
                    }
                }
            }
            .ignoresSafeArea()
            .background(Color.black)
        }
    }
}
