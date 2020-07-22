import CoreBluetooth

let SERVICE = CBUUID.init(string: "ff0f")
let COLOR_CHAR = CBUUID.init(string: "fffc")

typealias Color = (w: UInt8, r: UInt8, g: UInt8, b: UInt8)

func mkColor(_ color: Color) -> Data {
    var data = Data.init(count: 4)
    data[0] = color.w
    data[1] = color.r
    data[2] = color.g
    data[3] = color.b
    return data
}

class OrbManager {
    let finder: Finder
    let characterizer: Characterizer
    let cm: CBCentralManager

    init(cbk: @escaping (Orb) -> ()) {
        let ch = Characterizer() { orb, svc in
            let orb = Orb(peripheral: orb, service: svc)
            cbk(orb)
        }
        characterizer = ch

        finder = Finder() { orb in
            print("connected to orb", orb.identifier)

            orb.delegate = ch
            orb.discoverServices([SERVICE])
        }

        cm = CBCentralManager.init(delegate: finder, queue: nil)
    }
}

class Orb {
    let peripheral: CBPeripheral
    let service: CBService
    let colorChar: CBCharacteristic
    
    init(peripheral: CBPeripheral, service: CBService) {
        self.peripheral = peripheral
        self.service = service

        guard let char = getChar(service: service, charId: COLOR_CHAR) else {
            fatalError("missing color characteristic")
        }
        colorChar = char
    }
    
    func getColor() {
        peripheral.readValue(for: colorChar)
    }
    
    func setColor(_ color: Color) {
        peripheral.writeValue(mkColor(color), for: colorChar,
                              type: CBCharacteristicWriteType.withoutResponse)
        print("sent write")
    }
}
