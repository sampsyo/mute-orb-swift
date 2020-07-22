import Foundation

func randColor() -> Color {
    return (
        255,
        UInt8.random(in: 0...255),
        UInt8.random(in: 0...255),
        UInt8.random(in: 0...255)
    )
}

let manager = OrbManager()
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
