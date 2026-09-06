import Foundation
import IOKit.ps

// Display-only estimate. Actual safety decisions continue to use the battery floor.
struct BatteryEstimate {
    let onBattery: Bool
    let percent: Double
    let minutesToEmpty: Double?

    init?(description: [String: Any]) {
        guard description[kIOPSTypeKey] as? String == kIOPSInternalBatteryType,
              let current = description[kIOPSCurrentCapacityKey] as? Double,
              let maximum = description[kIOPSMaxCapacityKey] as? Double,
              current.isFinite, maximum.isFinite, maximum > 0,
              current >= 0, current <= maximum,
              let state = description[kIOPSPowerSourceStateKey] as? String,
              state == kIOPSBatteryPowerValue || state == kIOPSACPowerValue else { return nil }
        onBattery = state == kIOPSBatteryPowerValue
        percent = current / maximum * 100
        let minutes = description[kIOPSTimeToEmptyKey] as? Double
        if onBattery, description[kIOPSIsChargingKey] as? Bool == false,
           let minutes, minutes.isFinite, minutes > 0 {
            minutesToEmpty = minutes
        } else {
            minutesToEmpty = nil
        }
    }

    func minutesToFloor(_ floor: Int) -> Double? {
        guard onBattery, (0...100).contains(floor) else { return nil }
        if percent <= Double(floor) { return 0 }
        guard let minutesToEmpty else { return nil }
        return minutesToEmpty * (percent - Double(floor)) / percent
    }

    static func read() -> BatteryEstimate? {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef] else { return nil }
        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any] else { continue }
            if let battery = BatteryEstimate(description: description) { return battery }
        }
        return nil
    }
}
