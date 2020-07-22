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
    var done = false
    var cm: CBCentralManager?
    var peripheral: CBPeripheral?

    func centralManager(_ central: CBCentralManager,
                        didDiscover periph: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        if periph.name == "PLAYBULB sphere" {
            peripheral = periph
            central.stopScan()
            done = true
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

    func scan() -> CBPeripheral? {
        cm = CBCentralManager.init(delegate: self, queue: nil)
        while !done && RunLoop.current.run(
            mode: RunLoop.Mode.default,
            before: Date.distantFuture) { }
        return peripheral
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
if let orb = scanner.scan() {
    print(orb)

    let delegate = OrbDelegate()
    orb.delegate = delegate
    orb.discoverServices(nil)

    let done = false
    while !done && RunLoop.current.run(
        mode: RunLoop.Mode.default,
        before: Date.distantFuture) { }
}
