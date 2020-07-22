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

class Finder: NSObject, CBCentralManagerDelegate {
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
