// =============================================================
//  Station ALMA-7, Part II: The Teleporter Incident
//  iOS Mobile Development · Module 4 · Lab Assignment
//
//  How to use:
//   • Xcode: File → New → Playground → Blank, replace everything
//     with this file's contents.
//   • Terminal: swift ALMA7_Part2_Starter.swift
//
//  Rules:
//   • Do NOT modify the STARTER DATA section.
//   • `!` (force unwrap) is forbidden: −0.5 points each.
//   • No map / filter / reduce / compactMap.
//   • Default to struct. Use class only where the task says so.
// =============================================================


// MARK: - =================== STARTER DATA ===================
// MARK: - Do not modify anything in this section

/// Splits a line into fields.
/// fields("crate:101:120")            -> ["crate", "101", "120"]
/// fields("livestock:lab mice:12:2")  -> ["livestock", "lab mice", "12", "2"]
/// fields("junk")                     -> ["junk"]
func fields(_ line: String, separatedBy separator: Character = ":") -> [String] {
    var result: [String] = []
    var current = ""
    for character in line {
        if character == separator {
            result.append(current)
            current = ""
        } else {
            current.append(character)
        }
    }
    result.append(current)
    return result
}

/// Cargo manifest as recovered from the damaged recorder.
let rawManifest = [
    "crate:101:120",
    "container:KZ-ALM-7:340",
    "livestock:lab mice:12:2",
    "???-corrupted-line",
    "crate:102:75",
    "container:KZ-ALM-9:410",
    "livestock:ficus:3:5",
    "crate:103:260",
    "crate:104:abc",
    ""
]

/// Oxygen readings. One of these deck names is not a real deck.
let deckReadings: [(deck: String, oxygen: Int)] = [
    (deck: "bridge",     oxygen: 78),
    (deck: "lab",        oxygen: 64),
    (deck: "greenhouse", oxygen: 55),
    (deck: "cargo",      oxygen: 12),
    (deck: "medbay",     oxygen: 90),
    (deck: "engine",     oxygen: 41)
]

/// Crew records, straight from the personnel file.
let crewData: [(name: String, deck: String, oxygen: Int)] = [
    (name: "Timur",   deck: "engine", oxygen: 62),
    (name: "Dana",    deck: "lab",    oxygen: 48),
    (name: "Aigerim", deck: "bridge", oxygen: 91),
    (name: "Nurlan",  deck: "cargo",  oxygen: 17)
]

print("ALMA-7 recorder online: \(rawManifest.count) manifest lines, \(deckReadings.count) readings, \(crewData.count) crew records.")

// MARK: - ================= END OF STARTER DATA =================


// MARK: - =================== YOUR SOLUTION ===================
// Uncomment each declaration when you start working on it.



// MARK: Level 1 · The Deck Register

// 1.1
// We don't write raw values. For a String enum, Swift uses the case name
// as the raw value: "bridge", "lab" and so on.
enum Deck: String, CaseIterable {
    case bridge, lab, cargo, medbay, engine

    // Read-only computed property.
    // There is no `default` case. If someone adds a new deck later,
    // the code will not compile until they give it a priority.
    var evacuationPriority: Int {
        switch self {
        case .bridge: return 1
        case .medbay: return 2
        case .lab:    return 3
        case .engine: return 4
        case .cargo:  return 5
        }
    }
}

print("\n=== Level 1 · Deck Register ===")
for deck in Deck.allCases {
    print("Deck \(deck.rawValue) -> evacuation priority \(deck.evacuationPriority)")
}
print("Deck(rawValue: \"greenhouse\") = \(String(describing: Deck(rawValue: "greenhouse")))")

// 1.2
// We only write green = 0. Swift gives the rest numbers automatically:
// yellow = 1, orange = 2, red = 3.
enum AlarmLevel: Int {
    case green = 0
    case yellow
    case orange
    case red

    // Every full 500 kg is one step up.
    // The number of steps is the same as the raw value we need.
    // We cap it at 3 (red), so we don't need a chain of ifs.
    static func level(forTotalMass mass: Int) -> AlarmLevel {
        let steps = max(0, mass) / 500
        let capped = min(steps, AlarmLevel.red.rawValue)
        return AlarmLevel(rawValue: capped) ?? .red
    }
}

print("AlarmLevel for 0 kg    -> \(AlarmLevel.level(forTotalMass: 0)) (raw \(AlarmLevel.level(forTotalMass: 0).rawValue))")
print("AlarmLevel for 940 kg  -> \(AlarmLevel.level(forTotalMass: 940))")
print("AlarmLevel for 1500 kg -> \(AlarmLevel.level(forTotalMass: 1500))")
print("AlarmLevel for 4000 kg -> \(AlarmLevel.level(forTotalMass: 4000))")


// MARK: Level 2 · The Manifest

// 2.1
enum ManifestEntry {
    case crate(id: Int, massKg: Int)
    case container(code: String, massKg: Int)
    case livestock(species: String, count: Int, massPerUnitKg: Int)
    case unknown(raw: String)
}

// 2.2
// `.unknown` is our error case. It does the job `nil` did in Module 3,
// but it also keeps the bad line, so we can show it later.
func parseEntry(_ line: String) -> ManifestEntry {
    let parts = fields(line)
    guard let tag = parts.first else {
        return .unknown(raw: line)
    }

    switch tag {
    case "crate":
        guard parts.count == 3,
              let id = Int(parts[1]),
              let massKg = Int(parts[2]) else {
            return .unknown(raw: line)
        }
        return .crate(id: id, massKg: massKg)

    case "container":
        guard parts.count == 3,
              let massKg = Int(parts[2]) else {
            return .unknown(raw: line)
        }
        return .container(code: parts[1], massKg: massKg)

    case "livestock":
        guard parts.count == 4,
              let count = Int(parts[2]),
              let perUnit = Int(parts[3]) else {
            return .unknown(raw: line)
        }
        return .livestock(species: parts[1], count: count, massPerUnitKg: perUnit)

    default:
        return .unknown(raw: line)
    }
}

// 2.3
func mass(of entry: ManifestEntry) -> Int {
    switch entry {
    case .crate(_, let massKg):
        return massKg
    case .container(_, let massKg):
        return massKg
    case .livestock(_, let count, let massPerUnitKg):
        return count * massPerUnitKg
    case .unknown:
        return 0
    }
}

print("\n=== Level 2 · Manifest ===")
var manifestTotal = 0
var unknownCount = 0
for line in rawManifest {
    let entry = parseEntry(line)
    let entryMass = mass(of: entry)
    print("\"\(line)\" -> \(entry) -> \(entryMass) kg")
    manifestTotal += entryMass
    if case .unknown = entry {
        unknownCount += 1
    }
}
print("Unknown (corrupted) lines: \(unknownCount)")
print("Total manifest mass: \(manifestTotal) kg")

let A = manifestTotal
print("Integrity fragment A = \(A)")


// MARK: Level 3 · Crew Snapshots

// 3.1
// This is a struct because a snapshot is just data about one person at one moment.
// When we copy it, the copy must be separate. Changing my copy
// must not change anyone else's copy.
// Equatable lets us compare two snapshots with ==. We use it in the Bonus.
struct CrewSnapshot: Equatable {
    let name: String
    var deck: Deck
    var oxygen: Int
    // We don't write an init. Swift makes init(name:deck:oxygen:) for us.

    mutating func breathe(_ amount: Int) {
        oxygen = max(0, oxygen - amount)
    }

    mutating func move(to deck: Deck) {
        self.deck = deck
    }

    // Replaces all of self with a new value in one line.
    // This works only because the method is `mutating`.
    mutating func reviveInMedbay() {
        self = CrewSnapshot(name: name, deck: .medbay, oxygen: 100)
    }

    static func rookie(named name: String) -> CrewSnapshot {
        return CrewSnapshot(name: name, deck: .bridge, oxygen: 100)
    }
}

// 3.2
print("\n=== Level 3 · Crew Snapshots ===")
var builtRoster: [CrewSnapshot] = []
for record in crewData {
    if let deck = Deck(rawValue: record.deck) {
        builtRoster.append(CrewSnapshot(name: record.name, deck: deck, oxygen: record.oxygen))
    } else {
        print("WARNING: \(record.name) is assigned to unknown deck \"\(record.deck)\", skipped")
    }
}
let crewRoster: [CrewSnapshot] = builtRoster
for member in crewRoster {
    print("Roster: \(member.name) on \(member.deck.rawValue), O2 \(member.oxygen)")
}

var rookie = CrewSnapshot.rookie(named: "Aliya")
print("Rookie: \(rookie)")
rookie.breathe(130)
print("Rookie after breathe(130) (clamped at 0): \(rookie.oxygen)")
rookie.move(to: .engine)
print("Rookie after move(to: .engine): \(rookie.deck)")
rookie.reviveInMedbay()
print("Rookie after reviveInMedbay(): \(rookie)")

// 3.3 · Value-semantics demonstration (copy / plain parameter / inout)
print("\n--- 3.3 Value semantics ---")

// Test 1: when we assign a struct to a new variable, we get a separate copy.
var original = CrewSnapshot(name: "Timur", deck: .engine, oxygen: 62)
print("[copy] BEFORE: original.oxygen = \(original.oxygen)")
var copy = original
copy.breathe(20)
print("[copy] AFTER:  copy.oxygen = \(copy.oxygen), original.oxygen = \(original.oxygen)  (original unchanged)")

// Test 2: a normal parameter is also a copy.
// Inside the function the parameter is a constant, so we copy it into a var first.
func drainCopy(_ snapshot: CrewSnapshot) {
    var local = snapshot
    local.breathe(30)
    print("[param] inside function: local.oxygen = \(local.oxygen)")
}
print("[param] BEFORE: original.oxygen = \(original.oxygen)")
drainCopy(original)
print("[param] AFTER:  original.oxygen = \(original.oxygen)  (original unchanged)")

// Test 3: with inout, the changed value goes back into the caller's variable.
func drainInPlace(_ snapshot: inout CrewSnapshot) {
    snapshot.breathe(30)
    print("[inout] inside function: snapshot.oxygen = \(snapshot.oxygen)")
}
print("[inout] BEFORE: original.oxygen = \(original.oxygen)")
drainInPlace(&original)
print("[inout] AFTER:  original.oxygen = \(original.oxygen)  (original CHANGED)")


// MARK: Level 4 · The Teleport Pod

// 4.1
// This is a class because there is only one real pod P-1.
// Every part of the station must see the same charge and the same person inside.
// If it were a struct, every variable would have its own copy of the pod,
// and the copies could disagree. That is exactly what went wrong in the incident.
final class TeleportPod {
    let id: String
    var chargeLevel: Int
    var occupant: CrewSnapshot?

    // Why we write this init ourselves:
    // Swift makes a memberwise init for structs, but never for classes.
    // A class can have subclasses, so Swift does not guess how to set it up.
    // That is why CrewSnapshot got init(name:deck:oxygen:) for free and this class did not.
    init(id: String, chargeLevel: Int) {
        self.id = id
        self.chargeLevel = chargeLevel
        self.occupant = nil
    }

    // Bonus 1: runs when the pod is removed from memory.
    deinit {
        print("deinit: pod \(id) destroyed")
    }

    func load(_ crew: CrewSnapshot) -> Bool {
        guard occupant == nil, chargeLevel >= 20 else {
            return false
        }
        occupant = crew
        return true
    }

    func fire() -> CrewSnapshot? {
        guard let passenger = occupant else {
            return nil                 // empty pod, so no charge is used
        }
        chargeLevel -= 20
        occupant = nil
        return passenger
    }
}

// Helper: finds a crew member by name with a normal loop (no filter).
func crewMember(named name: String, in roster: [CrewSnapshot]) -> CrewSnapshot? {
    for member in roster {
        if member.name == name {
            return member
        }
    }
    return nil
}

// 4.2 · Charge ledger: load+fire three times, then fire an empty pod
print("\n=== Level 4 · Teleport Pod ===")
let pod1 = TeleportPod(id: "P-1", chargeLevel: 100)
print("Pod \(pod1.id) start charge: \(pod1.chargeLevel)")

var step = 1
for name in ["Timur", "Dana", "Nurlan"] {
    if let member = crewMember(named: name, in: crewRoster) {
        let loaded = pod1.load(member)
        let arrived = pod1.fire()
        print("Step \(step): load \(name) -> \(loaded), fire -> \(arrived?.name ?? "nobody"), charge = \(pod1.chargeLevel)")
    } else {
        print("Step \(step): \(name) not in roster, charge = \(pod1.chargeLevel)")
    }
    step += 1
}
let emptyShot = pod1.fire()
print("Step \(step): fire empty pod -> \(emptyShot?.name ?? "nil"), charge = \(pod1.chargeLevel)")

let C = pod1.chargeLevel
print("Integrity fragment C = \(C)")

// 4.3 · Reference-semantics demonstration
print("\n--- 4.3 Reference semantics ---")
let podAlias = pod1
print("BEFORE: pod1.chargeLevel = \(pod1.chargeLevel), podAlias.chargeLevel = \(podAlias.chargeLevel)")
podAlias.chargeLevel = 5
print("AFTER podAlias.chargeLevel = 5: pod1 = \(pod1.chargeLevel), podAlias = \(podAlias.chargeLevel)  (BOTH changed)")
pod1.chargeLevel = C   // put the charge back to the value from the ledger

let snapA = CrewSnapshot(name: "Dana", deck: .lab, oxygen: 48)
var snapB = snapA
print("BEFORE: snapA.oxygen = \(snapA.oxygen), snapB.oxygen = \(snapB.oxygen)")
snapB.oxygen = 5
print("AFTER snapB.oxygen = 5: snapA = \(snapA.oxygen), snapB = \(snapB.oxygen)  (only snapB changed)")
// Rule: assigning a class copies the link, so both names point to one object.
// Assigning a struct copies the data, so we get two separate values.


// MARK: Level 5 · Station Systems

// 5.1
// This is a class because there is only one station.
// All systems must read and change the same live data.
final class Station {
    // 1. Stored `let`
    let callSign: String

    // Stored dictionary, built from the readings
    var oxygenByDeck: [Deck: Int]

    // 2. Stored `var` with observers
    var hullIntegrity: Int {
        willSet {
            print("Hull integrity: \(hullIntegrity) -> \(newValue)")
        }
        didSet {
            // Changing the property inside its own didSet does not call
            // willSet/didSet again, so there is no endless loop.
            if hullIntegrity > 100 {
                hullIntegrity = 100
            } else if hullIntegrity < 0 {
                hullIntegrity = 0
            }
        }
    }

    // 3. Lazy stored property.
    // The code inside runs only the first time someone reads it.
    // After that, the saved result is returned.
    lazy var fullDiagnostics: String = {
        print("Running full scan...")
        var report = "Diagnostics for \(self.callSign): hull \(self.hullIntegrity)%"
        for deck in Deck.allCases {
            if let level = self.oxygenByDeck[deck] {
                report += ", \(deck.rawValue) \(level)"
            }
        }
        return report
    }()

    // 4. Computed, read-only (written without the `get` keyword)
    var totalOxygen: Int {
        var sum = 0
        for (_, level) in oxygenByDeck {
            sum += level
        }
        return sum
    }

    // 5. Computed with get and set. The setter uses the default name `newValue`.
    var averageOxygen: Int {
        get {
            guard oxygenByDeck.count > 0 else { return 0 }
            return totalOxygen / oxygenByDeck.count
        }
        set {
            // The loop goes over a copy of the dictionary,
            // so it is safe to change the dictionary inside the loop.
            for (deck, _) in oxygenByDeck {
                oxygenByDeck[deck] = newValue
            }
        }
    }

    init(callSign: String, readings: [(deck: String, oxygen: Int)], hullIntegrity: Int) {
        self.callSign = callSign
        self.hullIntegrity = hullIntegrity     // observers don't run inside init
        var byDeck: [Deck: Int] = [:]
        for reading in readings {
            if let deck = Deck(rawValue: reading.deck) {
                byDeck[deck] = reading.oxygen
            } else {
                print("Station \(callSign): skipped reading for unknown deck \"\(reading.deck)\"")
            }
        }
        self.oxygenByDeck = byDeck
    }
}

print("\n=== Level 5 · Station Systems ===")
let station = Station(callSign: "ALMA-7", readings: deckReadings, hullIntegrity: 100)
print("Call sign: \(station.callSign)")
print("Decks with readings: \(station.oxygenByDeck.count)")
print("Total oxygen: \(station.totalOxygen)")

let B = station.averageOxygen
print("Average oxygen at start-up: \(B)")
print("Integrity fragment B = \(B)")

// Lazy test: the 1st read prints "Running full scan...", the 2nd read does not.
print("Accessing fullDiagnostics for the 1st time:")
print(station.fullDiagnostics)
print("Accessing fullDiagnostics for the 2nd time:")
print(station.fullDiagnostics)

// This station never reads fullDiagnostics, so the scan never runs.
let backupStation = Station(callSign: "ALMA-7-BACKUP", readings: deckReadings, hullIntegrity: 90)
print("Backup station created, diagnostics never accessed, so no scan line above. Avg O2: \(backupStation.averageOxygen)")

// The averageOxygen setter changes every deck to the new value.
station.averageOxygen = 70
print("After averageOxygen = 70: bridge \(station.oxygenByDeck[.bridge] ?? -1), cargo \(station.oxygenByDeck[.cargo] ?? -1), total \(station.totalOxygen)")
// The lazy value was saved before, so it is not calculated again and still shows old numbers.
print("fullDiagnostics still shows the old scan: \(station.fullDiagnostics)")

// 5.2 · The clamp trap: 130, then -40, then 55
print("\n--- 5.2 Clamp trap ---")
station.hullIntegrity = 130
print("hullIntegrity after 130: \(station.hullIntegrity)")
station.hullIntegrity = -40
print("hullIntegrity after -40: \(station.hullIntegrity)")
station.hullIntegrity = 55
print("hullIntegrity after 55: \(station.hullIntegrity)")
// Why there is no endless loop:
// When didSet sets hullIntegrity = 100, Swift just saves the value.
// It does not call willSet or didSet again for a change made inside the property's own observer.
// That is why "Hull integrity: ..." is printed only once per assignment.


// MARK: Level 6 · Incident Reports
// Three of these compile and are wrong. One does not compile.
// For each: expectation, actual behaviour, the language rule, the fix.
//
// NOTE: after testing, Report 3 does not compile. In Report 4 the line
// `snapshot.oxygen = 40` does not compile either (the pod line is fine).
// Reports 1 and 2 compile but give the wrong result.

/*
// Report 1
var roster = crewRoster
for var member in roster {
    member.oxygen -= 10
}
print(roster[0].oxygen)   // author expected the crew to have lost oxygen

// Report 2
let podA = TeleportPod(id: "A", chargeLevel: 100)
let podB = podA
podB.chargeLevel = 0
print(podA.chargeLevel)   // author expected 100

// Report 3
struct Logbook {
    var entries: [String] = []
    func add(_ entry: String) {
        entries.append(entry)
    }
}

// Report 4
let snapshot = CrewSnapshot.rookie(named: "Dana")
snapshot.oxygen = 40

let pod = TeleportPod(id: "B", chargeLevel: 50)
pod.chargeLevel = 10
*/

print("\n=== Level 6 · Incident Reports (fixed) ===")

// Report 1: compiles, but the result is wrong.
// Expected: every crew member in `roster` loses 10 oxygen.
// Actual: roster[0].oxygen is still 62. `member` is a copy of the element.
//   We change the copy, and the copy is thrown away after each loop step.
// Rule: structs are value types. `for var x in array` gives you a copy.
// Fix: change the element in the array itself, using its index.
do {
    var roster = crewRoster
    print("Report 1 BEFORE: roster[0].oxygen = \(roster[0].oxygen)")
    for index in roster.indices {
        roster[index].breathe(10)
    }
    print("Report 1 AFTER (fixed): roster[0].oxygen = \(roster[0].oxygen)")
}

// Report 2: compiles, but the result is wrong.
// Expected: podA stays at 100, and podB is a separate pod with 0.
// Actual: it prints 0. `let podB = podA` copies the link, not the pod.
//   Both names point to the same object, so changing podB also changes podA.
// Rule: classes are reference types.
// Fix: if you need a second pod, create a new one.
do {
    let podA = TeleportPod(id: "A", chargeLevel: 100)
    let podB = TeleportPod(id: "A-copy", chargeLevel: podA.chargeLevel)
    podB.chargeLevel = 0
    print("Report 2 (fixed): podA.chargeLevel = \(podA.chargeLevel), podB.chargeLevel = \(podB.chargeLevel)")
}

// Report 3: does NOT compile.
// Expected: add() adds a new entry to the list.
// Actual: error: cannot use mutating member on immutable value: 'self' is immutable
// Rule: in a struct method, self can't be changed unless the method is `mutating`.
// Fix: add the word `mutating`.
struct Logbook {
    var entries: [String] = []
    mutating func add(_ entry: String) {
        entries.append(entry)
    }
}
var logbook = Logbook()
logbook.add("Day 10: teleporter reports full success")
logbook.add("Day 10: Nurlan seen on two decks")
print("Report 3 (fixed): logbook has \(logbook.entries.count) entries")
print("Report 3 (fixed): last entry = \(logbook.entries.last ?? "none")")

// Report 4: the first part does NOT compile, the second part is fine.
// `snapshot.oxygen = 40` gives:
//   error: cannot assign to property: 'snapshot' is a 'let' constant
//   For a struct, `let` locks the whole value, including all its properties.
// `pod.chargeLevel = 10` works.
//   For a class, `let` locks only the link. `pod` can't point to another pod,
//   but the object itself can still change its `var` properties.
// Fix: use `var` for the snapshot.
do {
    var snapshot = CrewSnapshot.rookie(named: "Dana")
    snapshot.oxygen = 40
    let pod = TeleportPod(id: "B", chargeLevel: 50)
    pod.chargeLevel = 10
    print("Report 4 (fixed): snapshot.oxygen = \(snapshot.oxygen), pod.chargeLevel = \(pod.chargeLevel)")
    // pod = TeleportPod(id: "C", chargeLevel: 0)   // this would NOT compile: a let link can't point to a new pod
}


// MARK: Level 7 · Sealing the Black Box

// The leaky original:
//
// class FlightRecorder {
//     var entries: [String] = []
//     var isSealed = false
// }
//
// Your sealed version below. One comment per access keyword.

// This is a class because there is only one black box.
// Every system must write into the same recorder, not into its own copy.
// internal: blocks access from other modules (other apps or frameworks).
internal final class FlightRecorder {
    // private: blocks all code outside this class from reading, replacing or clearing the list.
    private var entries: [String] = []

    // private(set): blocks outside code from changing isSealed, so it can't go back to false. Reading is allowed.
    private(set) var isSealed = false

    // internal: blocks other modules; inside the app anyone can read the count.
    internal var entryCount: Int {
        return entries.count
    }

    // internal: blocks other modules; it returns a new text, not the real list.
    internal var transcript: String {
        var text = ""
        var number = 1
        for entry in entries {
            text += "#\(number) \(entry)\n"
            number += 1
        }
        return text
    }

    // internal: blocks other modules; the guard inside blocks adding after sealing.
    internal func add(_ entry: String) -> Bool {
        guard isSealed == false else {
            return false
        }
        entries.append(entry)
        return true
    }

    // internal: blocks other modules; sealing works one way only, there is no unseal.
    internal func seal() {
        isSealed = true
    }

    // fileprivate: blocks code in other files; the audit function below is in this file, so it can use it.
    // It returns a copy of the array, so the caller can't change the real log.
    fileprivate func rawEntriesForAudit() -> [String] {
        return entries
    }
}

// A free function (not inside the class) that uses the fileprivate helper.
// If the helper were `private`, this function could not call it,
// because it is outside the class.
func auditTranscript(of recorder: FlightRecorder) -> String {
    let lines = recorder.rawEntriesForAudit()
    var longest = 0
    for line in lines {
        if line.count > longest {
            longest = line.count
        }
    }
    return "AUDIT: \(lines.count) entries, sealed = \(recorder.isSealed), longest entry = \(longest) chars"
}

print("\n=== Level 7 · Black Box ===")
let recorder = FlightRecorder()
print("Add 1: \(recorder.add("Teleporter fired: Timur -> engine"))")
print("Add 2: \(recorder.add("Teleporter fired: Dana -> lab"))")
recorder.seal()
print("Sealed: \(recorder.isSealed)")
print("Add after seal (must be false): \(recorder.add("Nothing happened, honest"))")
print("Entry count: \(recorder.entryCount)")
print("Transcript:\n\(recorder.transcript)", terminator: "")
print(auditTranscript(of: recorder))

// My attempts to break the recorder from outside. They do not compile:
//
// recorder.entries = []
//   error: 'entries' is inaccessible due to 'private' protection level
//
// recorder.entries.append("fake entry")
//   error: 'entries' is inaccessible due to 'private' protection level
//
// recorder.isSealed = false
//   error: cannot assign to property: 'isSealed' setter is inaccessible


// MARK: Finale · Integrity Code

print("\n=== Finale ===")
let D = AlarmLevel.level(forTotalMass: A).rawValue
print("Alarm level for manifest mass \(A) kg: \(AlarmLevel.level(forTotalMass: A))")
let integrityCode = "\(A)-\(B)-\(C)-\(D)"
print("INTEGRITY CODE: \(integrityCode)")


// MARK: Bonus

// deinit in TeleportPod, a do-block lifetime experiment, and === identity
print("\n=== Bonus ===")

// Test 1: both links are inside the block.
print("Bonus: entering block 1")
do {
    let temp = TeleportPod(id: "TEMP-1", chargeLevel: 30)
    let secondRef = temp
    print("Inside block 1: \(temp.id) and \(secondRef.id), 2 references")
}   // deinit for TEMP-1 runs HERE: both links end at this brace, so nobody holds the pod
print("Bonus: left block 1")

// Test 2: the second link is outside the block.
var survivor: TeleportPod? = nil
print("Bonus: entering block 2")
do {
    let temp = TeleportPod(id: "TEMP-2", chargeLevel: 30)
    survivor = temp
    print("Inside block 2: \(temp.id), 2 references (temp + survivor)")
}   // temp is gone, but survivor still holds the pod, so NO deinit here
print("Bonus: left block 2, pod still alive: \(survivor?.id ?? "none")")
survivor = nil   // deinit for TEMP-2 runs on THIS line: the last link is removed
print("Bonus: survivor set to nil")

// === checks "same object", == style check compares the data inside
func comparePods(_ first: TeleportPod, _ second: TeleportPod) -> String {
    if first === second {
        return "SAME pod (one object, two references)"
    }
    if first.id == second.id && first.chargeLevel == second.chargeLevel && first.occupant == second.occupant {
        return "TWO different pods with EQUAL contents"
    }
    return "TWO different pods with different contents"
}

let recordOne = TeleportPod(id: "P-7", chargeLevel: 60)
let recordTwo = recordOne
let recordThree = TeleportPod(id: "P-7", chargeLevel: 60)
print("recordOne vs recordTwo:   \(comparePods(recordOne, recordTwo))")
print("recordOne vs recordThree: \(comparePods(recordOne, recordThree))")
// Using === on CrewSnapshot does not compile:
//   let s1 = CrewSnapshot.rookie(named: "Dana"); let s2 = s1
//   s1 === s2   // error: argument type 'CrewSnapshot' expected to be an instance of a class or class-constrained type
// A struct has no identity. Each variable keeps its own data, not a link
// to a shared object. So "is it the same object?" makes no sense for it.
// For structs we use == to compare the data.
print("CrewSnapshot uses == instead: \(CrewSnapshot.rookie(named: "Dana") == CrewSnapshot.rookie(named: "Dana"))")


// MARK: - ================= DEFENSE QUESTIONS =================
/*
 1. Why did CrewSnapshot get an initializer for free and TeleportPod did not?

    Swift always makes a memberwise init for a struct:
    CrewSnapshot(name:deck:oxygen:).
    For a class it does not do this. A class can have subclasses,
    and Swift does not want to guess how to set up the whole chain.
    A class gets a free init() only if every stored property already
    has a default value. TeleportPod's id and chargeLevel don't have one,
    so we must write the init ourselves.

 2. What does `mutating` do to self, and why do classes never need it?

    In a normal struct method, self can't be changed.
    `mutating` allows the method to change self: change its properties
    or even replace the whole value (self = CrewSnapshot(...)).
    The new value is saved back into the variable that called the method.
    That is also why you can't call a mutating method on a `let` struct.
    A class works through a link to an object. The method changes the
    object, not the link, so there is nothing that needs to be marked.

 3. In Report 4 both values are `let`. What exactly does `let` freeze for a
    struct, and what does it freeze for a class?

    Struct: `let snapshot` locks the whole value, all of its properties,
    even the ones declared with var. So snapshot.oxygen = 40 is an error.
    Class: `let pod` locks only the link. pod = TeleportPod(...) is an
    error, but pod.chargeLevel = 10 is OK, because we change the object,
    not the link stored in `pod`.

 4. Why must a lazy property be var? When does lazy change behaviour, not
    just performance?

    A lazy property has no value when init finishes. It gets its value
    later, the first time someone reads it. A `let` must get its value
    exactly once inside init, so lazy can't be let.
    How it changes behaviour: fullDiagnostics saves the data at the moment
    of the first read and never updates. In my output, after
    averageOxygen = 70 it still shows the old oxygen numbers.
    Also, the code inside (the "Running full scan..." print) runs only if
    someone reads the property. For backupStation it never runs at all.

 5. private vs fileprivate: where in your FlightRecorder would private be
    too strict?

    auditTranscript(of:) is a free function, it is not part of
    FlightRecorder. It needs the list of entries, so it calls
    rawEntriesForAudit(). If that helper were `private`, only the class
    itself could call it, and the audit function would not compile.
    With `fileprivate`, code in this file can use it, but code in other
    files can't. The helper returns a copy of the list, so even the
    audit function can't change the real log.

 Bonus. On which line does deinit fire, and why can't === be used on
 CrewSnapshot?

    Block 1: deinit runs on the closing brace of the do block.
    Both links (temp and secondRef) end there, so nobody holds the pod.
    Block 2: leaving the block does NOT remove the pod, because
    `survivor` still holds it. deinit runs on the line survivor = nil,
    when the last link is removed. Swift (ARC) counts the links to an
    object and deletes it when the count becomes 0.
    === checks "are these two the same object?". Only class objects have
    this kind of identity. A struct is just a value, so === does not even
    compile for CrewSnapshot. For structs we compare data with ==.
*/

