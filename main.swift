import CoreBluetooth

let DEVICE = "073D8EDC-A732-4029-BACB-F893D3E9C7E3"

let SERVICE = CBUUID.init(string: "ff0f")
let COLOR_CHAR = CBUUID.init(string: "fffc")

func getDevice(cm: CBCentralManager) -> CBPeripheral? {
    guard let uuid = UUID.init(uuidString: DEVICE) else {
        print("bad UUID")
        return nil
    }

    let peripherals = cm.retrievePeripherals(withIdentifiers: [
        uuid
    ])
    if peripherals.isEmpty {
        return nil
    } else {
        return peripherals[0]
    }
}

class Scanner: NSObject, CBCentralManagerDelegate {
    var callback: ((CBPeripheral) -> ())?
    var peripheral: CBPeripheral?

    func centralManager(_ central: CBCentralManager,
                        didDiscover periph: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        if periph.name == "PLAYBULB sphere" {
            central.stopScan()
            guard peripheral == nil else {
                print("found two orbs?!")
                return
            }
            peripheral = periph
            central.connect(periph)
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            // Try looking for a previously-connected device.
            if let periph = getDevice(cm: central) {
                peripheral = periph
                print("found existing")
                central.connect(periph)
            } else {
                print("scanning")
                central.scanForPeripherals(withServices: nil)
            }
        default:
            print("some other state")
        }
    }

    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {
        guard let cbk = callback else {
            print("connected before callback assigned")
            return
        }
        cbk(peripheral)
    }

    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        print("failed to connect", peripheral)
    }

    func scan(cbk: @escaping (CBPeripheral) -> ()) {
        callback = cbk
    }
}

class OrbDelegate: NSObject, CBPeripheralDelegate {
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

let scanner = Scanner()
let delegate = OrbDelegate()
delegate.callback = { orb, svc in
    guard let char = getChar(service: svc, charId: COLOR_CHAR) else {
        print("missing color characteristic")
        return
    }
    orb.readValue(for: char)

    let color = mkColor(
        w: 255,
        r: UInt8.random(in: 0...255),
        g: UInt8.random(in: 0...255),
        b: UInt8.random(in: 0...255)
    )
    orb.writeValue(color, for: char,
                   type: CBCharacteristicWriteType.withoutResponse)
}

scanner.scan() { orb in
    print("connected to orb", orb.identifier,
          "in state", orb.state.rawValue)

    orb.delegate = delegate
    orb.discoverServices([SERVICE])
}

let cm = CBCentralManager.init(delegate: scanner, queue: nil)

while RunLoop.current.run(
    mode: RunLoop.Mode.default,
    before: Date.distantFuture) { }
