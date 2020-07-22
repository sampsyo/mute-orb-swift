import Foundation
import CoreBluetooth

let manager = OrbManager() { orb in
    guard let char = getChar(service: orb.service, charId: COLOR_CHAR) else {
        print("missing color characteristic")
        return
    }
    //orb.readValue(for: char)

    let color = mkColor(
        w: 255,
        r: UInt8.random(in: 0...255),
        g: UInt8.random(in: 0...255),
        b: UInt8.random(in: 0...255)
    )
    orb.peripheral.writeValue(color, for: char,
                              type: CBCharacteristicWriteType.withoutResponse)
    print("sent write")
}

while RunLoop.current.run(
    mode: RunLoop.Mode.default,
    before: Date.distantFuture) { }
