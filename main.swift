import CoreBluetooth

let DEVICE = "d4-97-4b-1a-ac-e6"

// The service with all the interesting stuff.
let SERVICE = CBUUID.init(string: "ff0f")

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
    var callback: ((CBPeripheral) -> ())? // XXX
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
            print("scanning")
            central.scanForPeripherals(withServices: nil)
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
    func peripheral(_ peripheral: CBPeripheral,
         didDiscoverServices error: Error?) {
        print("discovered services")
        print(peripheral.services)
    }
}

let scanner = Scanner()
let delegate = OrbDelegate()
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
