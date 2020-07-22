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

class OrbManager: NSObject, CBPeripheralDelegate {
    var finder: Finder?
    var characterizer: Characterizer?
    var cm: CBCentralManager?
    var orb: Orb?

    func start(cbk: @escaping (Orb) -> ()) {
        characterizer = nil
        finder = nil
        cm = nil

        let ch = Characterizer() { periph, svc in
            guard let char = getChar(service: svc, charId: COLOR_CHAR) else {
                fatalError("missing color characteristic")
            }
            let orb = Orb(peripheral: periph, service: svc, colorChar: char)
            self.orb = orb
            periph.delegate = self
            cbk(orb)
        }
        characterizer = ch
        
        finder = Finder() { periph in
            print("connected", periph.identifier)
            periph.delegate = ch
            periph.discoverServices([SERVICE])
        }
        
        cm = CBCentralManager.init(delegate: finder, queue: nil)
    }

    // Peripheral delegate methods.
    
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        print("got a value", characteristic.value!)
        orb?.didRead(characteristic)
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

class Orb {
    let peripheral: CBPeripheral
    let service: CBService
    let colorChar: CBCharacteristic
    var colorCbk: ((Color) -> ())?
    
    init(peripheral: CBPeripheral, service: CBService, colorChar: CBCharacteristic) {
        self.peripheral = peripheral
        self.service = service
        self.colorChar = colorChar
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
    
    func didRead(_ char: CBCharacteristic) {
        if (char == colorChar) {
            guard let cbk = colorCbk else {
                fatalError("got color without asking for it")
            }
            cbk(parseColor(colorChar.value!))
            colorCbk = nil
        }
    }
}
