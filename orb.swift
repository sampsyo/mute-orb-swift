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

func parseColor(_ data: Data) -> Color {
    return (
        w: data[0],
        r: data[1],
        g: data[2],
        b: data[3]
    )
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

class Orb: NSObject, CBPeripheralDelegate {
    let peripheral: CBPeripheral
    let service: CBService
    let colorChar: CBCharacteristic
    var colorCbk: ((Color) -> ())?
    
    init(peripheral: CBPeripheral, service: CBService) {
        self.peripheral = peripheral
        self.service = service

        guard let char = getChar(service: service, charId: COLOR_CHAR) else {
            fatalError("missing color characteristic")
        }
        colorChar = char

        // Switch delegate to point here for subsequent events.
        super.init()
        peripheral.delegate = self
    }
    
    func getColor(cbk: @escaping (Color) -> ()) {
        guard colorCbk == nil else {
            fatalError("tried to read with read outstanding")
        }
        colorCbk = cbk
        peripheral.readValue(for: colorChar)
        print("sent read")
    }
    
    func setColor(_ color: Color) {
        peripheral.writeValue(mkColor(color), for: colorChar,
                              type: CBCharacteristicWriteType.withoutResponse)
        print("sent write")
    }

    // Peripheral delegate methods.
    
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        print("got a value", characteristic.value!)
        if (characteristic == colorChar) {
            guard let cbk = colorCbk else {
                fatalError("got color without asking for it")
            }
            cbk(parseColor(colorChar.value!))
            colorCbk = nil
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didWriteValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        print("finished writing")
    }

    func peripheralIsReady(
        toSendWriteWithoutResponse peripheral: CBPeripheral) {
        print("ready")
    }
}
