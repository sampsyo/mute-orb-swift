import CoreBluetooth

let SERVICE = CBUUID.init(string: "ffe0")
let BUTTON_CHAR = CBUUID.init(string: "ffe1")

class TagManager: NSObject, CBPeripheralDelegate {
    var finder: Finder?
    var characterizer: Characterizer?
    var cm: CBCentralManager?
    var deviceId: String
    var tag: CBPeripheral?
    var svc: CBService?
    var btnChar: CBCharacteristic?

    init(id: String) {
        deviceId = id
    }

    func start() {
        characterizer = nil
        finder = nil
        cm = nil

        let ch = Characterizer() { periph, svc in
            print("characterized")
            print(periph)
            print(svc)
            self.svc = svc
            guard let char = getChar(service: svc, charId: BUTTON_CHAR) else {
                fatalError("missing button characteristic")
            }
            print(char)
            self.tag = periph
            periph.delegate = self
            self.btnChar = char
            // sleep(1)
            periph.readValue(for: char)
            print("read!", char)
            print("prop", char.properties.contains(CBCharacteristicProperties.notify))
        }
        characterizer = ch

        finder = Finder(deviceName: "iTAG            ",
                        deviceId: deviceId) { periph in
            print("connected", periph.identifier)
            periph.delegate = ch
            print("will discover...")
            // sleep(1)
            print("OK!")
            periph.discoverServices([SERVICE])
        }

        cm = CBCentralManager.init(delegate: finder, queue: nil)
    }

    // Peripheral delegate methods.

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?) {
        print("updated!", characteristic, error ?? "no error")

        print("will discover desc...")
        // sleep(1)
        peripheral.discoverDescriptors(for: characteristic)
    }

    func peripheral(_ peripheral: CBPeripheral,
        didUpdateNotificationStateFor characteristic: CBCharacteristic,
        error: Error?) {
        print("notif state", characteristic, error ?? "no error")
    }

    func peripheral(_ peripheral: CBPeripheral,
        didReadRSSI: NSNumber, error: Error?) {
        print("got rssi", didReadRSSI)
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverDescriptorsFor characteristic: CBCharacteristic,
                    error: Error?) {
        print("did discover desc", characteristic, error ?? "no error");
        print(characteristic.descriptors!)
        sleep(5)
        peripheral.setNotifyValue(true, for: characteristic)
        print("set")
    }
}

let DEVICE = "DB15D8A5-C8D2-4391-97F6-07AFB4BCB493"

let manager = TagManager(id: DEVICE)
manager.start()

while RunLoop.current.run(
    mode: RunLoop.Mode.default,
    before: Date.distantFuture) { }
