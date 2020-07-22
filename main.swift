import CoreBluetooth

let SERVICE = CBUUID.init(string: "ff0f")
let COLOR_CHAR = CBUUID.init(string: "fffc")

var done = false

func getChar(service: CBService, charId: CBUUID) -> CBCharacteristic? {
    guard let chars = service.characteristics else {
        return nil
    }
    for char in chars {
        if char.uuid == charId {
            return char
        }
    }
    return nil
}

func mkColor(w: UInt8, r: UInt8, g: UInt8, b: UInt8) -> Data {
    var data = Data.init(count: 4)
    data[0] = w
    data[1] = r
    data[2] = g
    data[3] = b
    return data
}

let finder = Finder() { orb in
    print("connected to orb", orb.identifier,
          "in state", orb.state.rawValue)

    orb.delegate = characterizer
    orb.discoverServices([SERVICE])
}

let characterizer = Characterizer() { orb, svc in
    guard let char = getChar(service: svc, charId: COLOR_CHAR) else {
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
    orb.writeValue(color, for: char,
                   type: CBCharacteristicWriteType.withoutResponse)
    print("sent write")
}

let cm = CBCentralManager.init(delegate: finder, queue: nil)

while !done && RunLoop.current.run(
    mode: RunLoop.Mode.default,
    before: Date.distantFuture) { }
