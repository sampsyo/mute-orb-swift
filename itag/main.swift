import CoreBluetooth

let SERVICE = CBUUID.init(string: "ffe0")
let BUTTON_CHAR = CBUUID.init(string: "ffe1")

class TagManager: NSObject, CBPeripheralDelegate {
    var finder: Finder?
    var characterizer: Characterizer?
    var cm: CBCentralManager?
    var deviceId: String

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
            guard let char = getChar(service: svc, charId: BUTTON_CHAR) else {
                fatalError("missing button characteristic")
            }
            print(char)
            periph.delegate = self
            periph.setNotifyValue(true, for:char)
        }
        characterizer = ch

        finder = Finder(deviceName: "iTAG            ",
                        deviceId: deviceId) { periph in
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
        print("updated!")
    }
}

let DEVICE = "DF39718D-D4A7-4632-ABE0-85ECE89904F1"

let manager = TagManager(id: DEVICE)
manager.start()

while RunLoop.current.run(
    mode: RunLoop.Mode.default,
    before: Date.distantFuture) { }
