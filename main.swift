import Foundation

let DEVICE = "073D8EDC-A732-4029-BACB-F893D3E9C7E3"

func randColor() -> Color {
    return (
        255,
        UInt8.random(in: 0...255),
        UInt8.random(in: 0...255),
        UInt8.random(in: 0...255)
    )
}

let manager = OrbManager(id: DEVICE)
manager.start() { orb in
    orb.getColor() { color in
        print(color)
        orb.setColor((255, color.g, color.b, color.r))
    }

    // orb.setColor(randColor())
}

while RunLoop.current.run(
    mode: RunLoop.Mode.default,
    before: Date.distantFuture) { }
