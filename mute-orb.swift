import CoreBluetooth

let DEVICE = "d4-97-4b-1a-ac-e6"


func getDevice() {
    guard let uuid = UUID.init(uuidString: DEVICE) else {
        print("bad UUID")
        return
    }

    let cm = CBCentralManager()
    let peripherals = cm.retrievePeripherals(withIdentifiers: [
        uuid
    ])
    print(peripherals)
}
/* getDevice() */

class Scanner: NSObject, CBCentralManagerDelegate {
    var cm: CBCentralManager?
    var callback: ((CBPeripheral) -> ())?

    func centralManager(_ central: CBCentralManager,
                        didDiscover periph: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        if periph.name == "PLAYBULB sphere" {
            central.stopScan()
            guard let cbk = callback else {
                print("discovered device before callback assigned")
                return
            }
            cbk(periph)
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("scanning")
            central.scanForPeripherals(withServices: nil)
        default:
            print("some other state")
        }
    }

    func scan(cbk: @escaping (CBPeripheral) -> ()) {
        callback = cbk

        // Maybe this should be "reusable" with an `if cm` check?
        cm = CBCentralManager.init(delegate: self, queue: nil)
    }
}

class OrbDelegate: NSObject, CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral,
         didDiscoverServices error: Error?) {
        print("discovered services")
        print(peripheral)
    }
}

let scanner = Scanner()
scanner.scan() { orb in
    print("found orb", orb.identifier)
    let delegate = OrbDelegate()
    orb.delegate = delegate
    orb.discoverServices(nil)
}

while RunLoop.current.run(
    mode: RunLoop.Mode.default,
    before: Date.distantFuture) { }
