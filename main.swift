import Foundation
import CoreBluetooth

let manager = OrbManager() { orb in
    orb.getColor()

    orb.setColor(mkColor(
        w: 255,
        r: UInt8.random(in: 0...255),
        g: UInt8.random(in: 0...255),
        b: UInt8.random(in: 0...255)
    ))
}

while RunLoop.current.run(
    mode: RunLoop.Mode.default,
    before: Date.distantFuture) { }
