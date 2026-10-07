// =============================================================
//  Station ALMA-7, Part III: The Repair Fleet
//  iOS Mobile Development · Module 5 · Lab Assignment
//
//  How to use:
//   • Xcode: File → New → Playground → Blank, replace everything
//     with this file's contents.
//   • Terminal: swift ALMA7_Part3_Starter.swift
//
//  Rules:
//   • Do NOT modify the STARTER DATA section. LegacyBeacon in
//     particular must be reached with an extension, not edited.
//   • `!` (force unwrap) is forbidden: −0.5 points each.
//   • No map / filter / reduce / compactMap.
//   • The Health Rule must exist in exactly ONE place in this file.
// =============================================================


// MARK: - =================== STARTER DATA ===================
// MARK: - Do not modify anything in this section

/// Drone records recovered from the fleet registry.
/// One `kind` does not correspond to any drone type you will build.
let fleetData: [(kind: String, id: String, charge: Int)] = [
    (kind: "welder",  id: "W-1", charge: 80),
    (kind: "scanner", id: "S-1", charge: 45),
    (kind: "cargo",   id: "C-1", charge: 100),
    (kind: "welder",  id: "W-2", charge: 15),
    (kind: "scanner", id: "S-2", charge: 60),
    (kind: "tug",     id: "T-1", charge: 50)
]

/// Hull sensors. These are NOT drones — they never move and never work a shift.
let sensorData: [(id: String, charge: Int)] = [
    (id: "hull-cam", charge: 12),
    (id: "thermal",  charge: 77)
]

/// Hardware from the original station. You may not add anything to this
/// declaration — no methods, no protocols, no properties.
struct LegacyBeacon {
    let name: String
    let signalStrength: Int
}

let beacon = LegacyBeacon(name: "ALMA-BEACON", signalStrength: 8)

print("Fleet registry online: \(fleetData.count) drone records, \(sensorData.count) sensors, beacon \(beacon.name).")

// MARK: - ================= END OF STARTER DATA =================


// MARK: - =================== YOUR SOLUTION ===================
// Uncomment each declaration when you start working on it.



// MARK: Level 1 · The Power Cell

// The recharge rule, written once: skip amounts of 0 or less, never go above 100.
// PowerCell and SensorModule both use it.
func chargeAfterRecharge(_ current: Int, by amount: Int) -> Int {
    if amount <= 0 {
        return current
    }
    return min(current + amount, 100)
}

// Why a class and not a struct here?  -> There is only one real battery, so when a drone
// spends charge, the real battery must change, not a copy of it.
final class PowerCell {
    private var charge: Int

    init(charge: Int) {
        self.charge = min(max(charge, 0), 100)
    }

    func level() -> Int {
        return charge
    }

    // The "is there enough charge?" rule, written once.
    // spend() and Drone.canRunAgain both use it.
    func hasEnough(for amount: Int) -> Bool {
        return amount > 0 && amount <= charge
    }

    func spend(_ amount: Int) -> Bool {
        if hasEnough(for: amount) == false {
            return false
        }
        charge -= amount
        return true
    }

    func recharge(by amount: Int) {
        charge = chargeAfterRecharge(charge, by: amount)
    }
}

print("\n=== Level 1 · Power Cell ===")
let cell = PowerCell(charge: 140)
print("PowerCell(charge: 140) starts at \(cell.level())")
print("spend(30) -> \(cell.spend(30)), level \(cell.level())")
print("spend(0) -> \(cell.spend(0)), level \(cell.level())")
print("spend(-5) -> \(cell.spend(-5)), level \(cell.level())")
print("spend(500) -> \(cell.spend(500)), level \(cell.level())")
cell.recharge(by: 50)
print("recharge(by: 50) -> level \(cell.level()) (never above 100)")
cell.recharge(by: -20)
print("recharge(by: -20) -> level \(cell.level()) (ignored)")
print("PowerCell(charge: -10) starts at \(PowerCell(charge: -10).level())")

// Encapsulation proof (leave this commented, with the compiler error):
// cell.charge = 100
// error: 'charge' is inaccessible due to 'private' protection level


// MARK: Level 2 · The Fleet

// 2.1  What does `final` on runOnce() buy you?  -> No child class can change it,
// so every drone always pays for its work first.
class Drone {
    let id: String
    let cell: PowerCell

    init(id: String, cell: PowerCell) {
        self.id = id
        self.cell = cell
    }

    var powerCost: Int { 10 }

    func performTask() -> Int { 0 }

    var statusLine: String {
        return "\(id): \(cell.level())% \(cell.level().powerBar)"
    }

    final func runOnce() -> Int {
        if cell.spend(powerCost) == false {
            return 0
        }
        return performTask()
    }

    var canRunAgain: Bool {
        return cell.hasEnough(for: powerCost)
    }
}

// 2.2
final class WelderDrone: Drone {
    override var powerCost: Int { 25 }

    override func performTask() -> Int { 40 }

    func weldSeam() -> String {
        return "\(id) welds a hull seam"
    }
}

class ScannerDrone: Drone {
    override var powerCost: Int { 10 }

    override func performTask() -> Int { 15 }

    override var statusLine: String {
        return super.statusLine + " [scanner]"
    }
}

final class CargoDrone: Drone {
    override var powerCost: Int { 20 }

    override func performTask() -> Int { 25 }
}

// 2.3
func makeDrone(kind: String, id: String, charge: Int) -> Drone? {
    let cell = PowerCell(charge: charge)
    switch kind {
    case "welder":
        return WelderDrone(id: id, cell: cell)
    case "scanner":
        return ScannerDrone(id: id, cell: cell)
    case "cargo":
        return CargoDrone(id: id, cell: cell)
    default:
        return nil
    }
}

print("\n=== Level 2 · Fleet ===")
var builtFleet: [Drone] = []
for record in fleetData {
    if let drone = makeDrone(kind: record.kind, id: record.id, charge: record.charge) {
        builtFleet.append(drone)
        print("Built \(record.kind) \(drone.id), cost \(drone.powerCost), status \(drone.statusLine)")
    } else {
        print("WARNING: unknown drone kind \"\(record.kind)\" for \(record.id), skipped")
    }
}
let fleet: [Drone] = builtFleet
print("Fleet size: \(fleet.count)")


// MARK: Level 3 · The Shift

func runShift(_ fleet: [Drone], rounds: Int) -> Int {
    var total = 0
    for _ in 0..<rounds {
        for drone in fleet {
            total += drone.runOnce()
        }
    }
    return total
}

print("\n=== Level 3 · Shift ===")
let A = runShift(fleet, rounds: 3)
print("Total work units after 3 rounds: \(A)")

var chargeSum = 0
var readyCount = 0
for drone in fleet {
    print(drone.statusLine)
    chargeSum += drone.cell.level()
    if drone.canRunAgain {
        readyCount += 1
    }
}
print("Drones that can still run one more task: \(readyCount)")

let B = chargeSum
let C = readyCount
print("Mission fragment A = \(A)")
print("Mission fragment B = \(B)")
print("Mission fragment C = \(C)")


// MARK: Level 4 · Diagnostics

// 4.1
protocol Diagnosable {
    var componentID: String { get }
    var statusCode: Int { get }
    func diagnose() -> String
}

// 4.2
protocol Rechargeable {
    mutating func recharge(by amount: Int)
}

// Why does Drone implement recharge(by:) without `mutating`?  -> Drone is a class.
// The method changes the object (its battery), not the variable that points to it,
// so `mutating` is not needed.
extension Drone: Diagnosable, Rechargeable {
    var componentID: String {
        return id
    }

    var statusCode: Int {
        return healthCode(forLevel: cell.level())
    }

    func recharge(by amount: Int) {
        cell.recharge(by: amount)
    }
}

struct SensorModule: Diagnosable, Rechargeable {
    let id: String
    var chargeLevel: Int

    var componentID: String {
        return id
    }

    var statusCode: Int {
        return healthCode(forLevel: chargeLevel)
    }

    mutating func recharge(by amount: Int) {
        chargeLevel = chargeAfterRecharge(chargeLevel, by: amount)
    }
}

print("\n=== Level 4 · Diagnostics ===")
var sensors: [SensorModule] = []
for record in sensorData {
    sensors.append(SensorModule(id: record.id, chargeLevel: record.charge))
}
for sensor in sensors {
    print("Sensor \(sensor.componentID): charge \(sensor.chargeLevel), code \(sensor.statusCode)")
}

var testSensor = SensorModule(id: "test-sensor", chargeLevel: 90)
testSensor.recharge(by: 30)
print("Test sensor after recharge(by: 30): \(testSensor.chargeLevel)")
let testDrone = ScannerDrone(id: "S-TEST", cell: PowerCell(charge: 10))
testDrone.recharge(by: 25)
print("Test drone after recharge(by: 25): \(testDrone.cell.level())")

// 4.3
// Why could [Drone] never have held the sensors?  -> SensorModule is a struct, and a struct
// can't be a child of the Drone class. The only thing they share is the protocol.
func diagnosticsReport(_ components: [Diagnosable]) -> String {
    var report = "DIAGNOSTICS (\(components.count) components)"
    for component in components {
        report += "\n  " + component.diagnose()
    }
    return report
}

var components: [Diagnosable] = []
for drone in fleet {
    components.append(drone)
}
for sensor in sensors {
    components.append(sensor)
}
print(diagnosticsReport(components))


// MARK: Level 5 · Shared Behaviour

// 5.1 · default diagnose() + the single home of the Health Rule
extension Diagnosable {
    func diagnose() -> String {
        return "\(componentID): code \(statusCode)"
    }

    // The Health Rule. This is the only place with these numbers.
    func healthCode(forLevel level: Int) -> Int {
        if level < 20 {
            return 2
        } else if level < 50 {
            return 1
        } else {
            return 0
        }
    }
}

// 5.2 · the beacon you cannot edit
extension LegacyBeacon: Diagnosable {
    var componentID: String {
        return name
    }

    var statusCode: Int {
        return healthCode(forLevel: signalStrength)
    }

    func diagnose() -> String {
        return "*** LEGACY HARDWARE *** \(name): signal \(signalStrength), code \(statusCode), check by hand"
    }
}

print("\n=== Level 5 · Shared Behaviour ===")
components.append(beacon)
print(diagnosticsReport(components))

var codeSum = 0
for component in components {
    codeSum += component.statusCode
}
let D = codeSum
print("Mission fragment D = \(D)")

// 5.3
extension Int {
    var powerBar: String {
        var filled = self / 10
        if filled < 0 {
            filled = 0
        }
        if filled > 10 {
            filled = 10
        }
        var bar = ""
        for position in 0..<10 {
            if position < filled {
                bar += "#"
            } else {
                bar += "."
            }
        }
        return bar
    }
}

print("42.powerBar  = \(42.powerBar)")
print("-5.powerBar  = \((-5).powerBar)")
print("250.powerBar = \(250.powerBar)")


// MARK: Level 6 · Incident Reports
// Two of these do not compile. Two compile and lie.
// For each: expectation, actual behaviour, the language rule, the fix.
//
// Note: I checked with the compiler. Reports 1, 2 and 3 do not compile.
// Only Report 4 compiles and gives the wrong result.

/*
// Report 1
class PatchDrone: Drone {
    func performTask() -> Int {
        return 30
    }
}

// Report 2
final class HeavyWelder: WelderDrone {
    override func runOnce() -> Int {
        return 999
    }
}

// Report 3
let reportFleet: [Drone] = [WelderDrone(id: "W-9", cell: PowerCell(charge: 100))]
let first = reportFleet[0]
print(first.weldSeam())

// Report 4
protocol Labelled {
    var componentID: String { get }
}

extension Labelled {
    func label() -> String { "generic component" }
}

struct Thruster: Labelled {
    let componentID: String
    func label() -> String { "thruster \(componentID)" }
}

let parts: [Labelled] = [Thruster(componentID: "T-1")]
print(parts[0].label())
*/

print("\n=== Level 6 · Incident Reports (fixed) ===")

// Report 1: does NOT compile.
// Expected: PatchDrone makes 30 work units.
// Actual: error: overriding declaration requires an 'override' keyword
// Rule: to replace a parent's method you must write `override`.
// Fix: add `override`.
class PatchDrone: Drone {
    override func performTask() -> Int {
        return 30
    }
}
let patch = PatchDrone(id: "P-1", cell: PowerCell(charge: 50))
print("Report 1 (fixed): PatchDrone runOnce() -> \(patch.runOnce()), charge left \(patch.cell.level())")

// Report 2: does NOT compile.
// Expected: a heavy welder that makes 999 units.
// Actual:
//   error: inheritance from a final class 'WelderDrone'
//   error: instance method overrides a 'final' instance method
// Rule: a final class can't have children, and a final method can't be replaced.
// Fix: don't touch runOnce(). Make the new drone from Drone and change only cost and work.
final class HeavyWelder: Drone {
    override var powerCost: Int { 40 }
    override func performTask() -> Int { 60 }
}
let heavy = HeavyWelder(id: "HW-1", cell: PowerCell(charge: 50))
print("Report 2 (fixed): HeavyWelder runOnce() -> \(heavy.runOnce()), charge left \(heavy.cell.level())")
print("Report 2 (fixed): second runOnce() -> \(heavy.runOnce()) (not enough charge, no work)")

// Report 3: does NOT compile.
// Expected: print the welder's weldSeam() text.
// Actual: error: value of type 'Drone' has no member 'weldSeam'
// Rule: the array is [Drone], so the compiler only allows what Drone has.
// Fix: check the real type with `as?`.
// `as?` returns an optional because the check can fail: the drone might not be a welder.
let reportFleet: [Drone] = [WelderDrone(id: "W-9", cell: PowerCell(charge: 100))]
let first = reportFleet[0]
if let welder = first as? WelderDrone {
    print("Report 3 (fixed): \(welder.weldSeam())")
} else {
    print("Report 3 (fixed): \(first.id) is not a welder")
}

// Report 4: compiles, but prints "generic component" instead of "thruster T-1".
// Rule: label() is not in the protocol, only in the extension. So Swift picks the
//   method by the array type ([Labelled]), not by the real object.
//   If label() is in the protocol, Swift picks it by the real object.
// Fix: one line, add `func label() -> String` to the protocol.
protocol Labelled {
    var componentID: String { get }
    func label() -> String          // <- the fix
}

extension Labelled {
    func label() -> String { "generic component" }
}

struct Thruster: Labelled {
    let componentID: String
    func label() -> String { "thruster \(componentID)" }
}

let parts: [Labelled] = [Thruster(componentID: "T-1")]
print("Report 4 (fixed): \(parts[0].label())")


// MARK: Finale · Mission Code

print("\n=== Finale ===")
let missionCode = "\(A)-\(B)-\(C)-\(D)"
print("MISSION CODE: \(missionCode)")


// MARK: Bonus

// Two ways to forbid using Drone directly; a protocol-based redesign;
// two or three sentences comparing them.
print("\n=== Bonus ===")

// Way 1, fails when the program RUNS: the base method stops the program with fatalError.
class RuntimeAbstractDrone {
    func performTask() -> Int {
        fatalError("RuntimeAbstractDrone is abstract: a subclass must override performTask()")
    }
}
final class RuntimeWelder: RuntimeAbstractDrone {
    override func performTask() -> Int { 40 }
}
print("RuntimeWelder works: \(RuntimeWelder().performTask())")
// RuntimeAbstractDrone().performTask()
// Compiles, then crashes: Fatal error: RuntimeAbstractDrone is abstract: a subclass must override performTask()

// Way 2, fails when the code COMPILES: make the base a protocol.
// A protocol can't be created, and every drone must write its own performTask().
protocol RepairDrone: Diagnosable {
    var id: String { get }
    var cell: PowerCell { get }
    var powerCost: Int { get }
    func performTask() -> Int
}
// let bare = RepairDrone()
// error: 'any RepairDrone' cannot be constructed because it has no accessible initializers

extension RepairDrone {
    var componentID: String {
        return id
    }

    var statusCode: Int {
        return healthCode(forLevel: cell.level())
    }

    var statusLine: String {
        return "\(id): \(cell.level())% \(cell.level().powerBar)"
    }

    func runOnce() -> Int {
        if cell.spend(powerCost) == false {
            return 0
        }
        return performTask()
    }
}

// WelderDrone as a struct. It is inside `Redesign` so the name doesn't clash with the class.
enum Redesign {
    struct WelderDrone: RepairDrone {
        let id: String
        let cell: PowerCell
        var powerCost: Int { 25 }
        func performTask() -> Int { 40 }
    }

    struct ScannerDrone: RepairDrone {
        let id: String
        let cell: PowerCell
        var powerCost: Int { 10 }
        func performTask() -> Int { 15 }
    }
}

let redesignFleet: [RepairDrone] = [
    Redesign.WelderDrone(id: "RW-1", cell: PowerCell(charge: 80)),
    Redesign.ScannerDrone(id: "RS-1", cell: PowerCell(charge: 45))
]
var redesignWork = 0
for _ in 0..<3 {
    for drone in redesignFleet {
        redesignWork += drone.runOnce()
    }
}
print("Redesign fleet work after 3 rounds: \(redesignWork)")
for drone in redesignFleet {
    print("Redesign: \(drone.statusLine), \(drone.diagnose())")
}

// Comparison:
// The class version gives shared stored properties, one init and a runOnce() that nobody
// can change, so I would keep it for this station.
// The protocol version works with structs and can't be created by itself, but a drone
// could write its own runOnce(), so the rule is less strict.
// If drones had to share changing data (like one battery), we need classes: here it still
// works only because PowerCell is a class. With plain struct fields, each copy would have its own charge.


// MARK: - ================= DEFENSE QUESTIONS =================
/*
 1. Why does a class satisfy a `mutating` protocol requirement without the
    keyword, while a struct must write it?

    `mutating` means "this method may change self".
    A struct is a value. Changing chargeLevel changes the struct itself,
    so Swift needs the word `mutating`. Without it SensorModule doesn't compile.
    A class works through a link to an object. The method changes the object,
    not the link, so a normal method in Drone is enough.

 2. One thing inheritance does that protocols cannot, and one thing
    protocols do that inheritance cannot:

    Inheritance: the child class gets ready properties (id, cell), the init
    and working code from the parent. It can call `super`, and the parent
    can lock a method with `final` (runOnce()).
    Protocols: they work with structs, enums and classes, even with a type
    we can't edit (LegacyBeacon, through an extension). A type can follow
    many protocols, but a class has only one parent.
    That is why the sensors and the beacon fit in the diagnostics list,
    but could never be Drones.

 3. What does `final` prevent, and what did it protect in runOnce()?

    A `final` method can't be replaced in a child class.
    A `final` class can't have children at all.
    The compiler checks both.
    In runOnce() it keeps the rule: every drone must pay powerCost from its
    battery before it works, and gets 0 if it can't pay. Report 2 shows the
    danger: HeavyWelder tried to return 999 without spending any charge.

 4. In Report 4, why did the protocol extension's method win?

    label() was not in the protocol, it was only in the extension.
    For such methods Swift chooses the code by the type of the variable,
    not by the real object. parts is [Labelled], so Swift called the
    extension version, even though the object is a Thruster.
    When label() is listed in the protocol, Swift looks at the real object
    and prints "thruster T-1".

*/
