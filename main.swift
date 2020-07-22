import Foundation

let manager = OrbManager() { orb in
    orb.getColor() { color in
        print(color)
    }

    orb.setColor((
        255,
        UInt8.random(in: 0...255),
        UInt8.random(in: 0...255),
        UInt8.random(in: 0...255)
    ))
}

while RunLoop.current.run(
    mode: RunLoop.Mode.default,
    before: Date.distantFuture) { }
