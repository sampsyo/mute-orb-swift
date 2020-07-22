import CoreBluetooth

let DEVICE = "073D8EDC-A732-4029-BACB-F893D3E9C7E3"

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

class Finder: NSObject, CBCentralManagerDelegate {
    let callback: ((CBPeripheral) -> ())
    var peripheral: CBPeripheral?

    init(cbk: @escaping (CBPeripheral) -> ()) {
        callback = cbk
    }

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
        callback(peripheral)
    }

    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        print("failed to connect", peripheral)
    }
}

class Characterizer: NSObject, CBPeripheralDelegate {
    let callback: ((CBPeripheral, CBService) -> ())

    init(cbk: @escaping (CBPeripheral, CBService) -> ()) {
        callback = cbk
    }

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
        callback(peripheral, service)
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
    }
}
