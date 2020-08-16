import CoreBluetooth

func getDevice(cm: CBCentralManager, id: String) -> CBPeripheral? {
    guard let uuid = UUID.init(uuidString: id) else {
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
    let deviceName: String
    let deviceId: String
    var peripheral: CBPeripheral?

    init(deviceName: String, deviceId: String,
         cbk: @escaping (CBPeripheral) -> ()) {
        callback = cbk
        self.deviceName = deviceName
        self.deviceId = deviceId
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover periph: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        if periph.name == deviceName {
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
            if let periph = getDevice(cm: central, id: deviceId) {
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

    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        print("disconnected")
    }
}

class Characterizer: NSObject, CBPeripheralDelegate {
    let discoverCbk: (CBPeripheral, CBService) -> ()

    init(cbk: @escaping (CBPeripheral, CBService) -> ()) {
        discoverCbk = cbk
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
        let svc = svcs[0]

        peripheral.discoverCharacteristics(nil, for: svc)
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        print("discovered characteristics")
        discoverCbk(peripheral, service)
    }
}
