import CoreBluetooth

let SERVICE = CBUUID.init(string: "ff0f")
let COLOR_CHAR = CBUUID.init(string: "fffc")

var done = false

class Characterizer: NSObject, CBPeripheralDelegate {
    var callback: ((CBPeripheral, CBService) -> ())?

    func peripheral(_ peripheral: CBPeripheral,
         didDiscoverServices error: Error?) {
        print("discovered services")
        guard let svcs = peripheral.services else {
            print("still missing services?!")
            return
        }
        guard svcs.count == 1 else {
            print("expected one service")
            return
        }
        let orbSvc = svcs[0]

        peripheral.discoverCharacteristics(nil, for: orbSvc)
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        print("discovered characteristics")
        if let cbk = callback {
            cbk(peripheral, service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        print("got a value", characteristic.value!)
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didWriteValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        print("finished writing")
    }

    func peripheralIsReady(
        toSendWriteWithoutResponse peripheral: CBPeripheral) {
        print("ready")
        done = true
    }
}

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

let scanner = Finder()
let delegate = Characterizer()
delegate.callback = { orb, svc in
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

scanner.scan() { orb in
    print("connected to orb", orb.identifier,
          "in state", orb.state.rawValue)

    orb.delegate = delegate
    orb.discoverServices([SERVICE])
}

let cm = CBCentralManager.init(delegate: scanner, queue: nil)

while !done && RunLoop.current.run(
    mode: RunLoop.Mode.default,
    before: Date.distantFuture) { }
