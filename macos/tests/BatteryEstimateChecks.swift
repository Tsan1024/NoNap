import Foundation
import IOKit.ps

@main
enum BatteryEstimateChecks {
    static func main() {
        var info: [String: Any] = [
            kIOPSTypeKey: kIOPSInternalBatteryType,
            kIOPSCurrentCapacityKey: NSNumber(value: 60),
            kIOPSMaxCapacityKey: NSNumber(value: 100),
            kIOPSPowerSourceStateKey: kIOPSBatteryPowerValue,
            kIOPSIsChargingKey: false,
            kIOPSTimeToEmptyKey: NSNumber(value: 240)
        ]
        assert(BatteryEstimate(description: info)?.minutesToFloor(15) == 180)
        assert(BatteryEstimate(description: info)?.minutesToFloor(60) == 0)
        assert(BatteryEstimate(description: info)?.minutesToFloor(70) == 0)
        assert(BatteryEstimate(description: info)?.minutesToFloor(101) == nil)
        for invalid in [-1.0, 0, Double.nan, Double.infinity] {
            info[kIOPSTimeToEmptyKey] = NSNumber(value: invalid)
            assert(BatteryEstimate(description: info)?.minutesToFloor(15) == nil)
        }
        info.removeValue(forKey: kIOPSTimeToEmptyKey)
        assert(BatteryEstimate(description: info)?.minutesToFloor(15) == nil)
        info[kIOPSTimeToEmptyKey] = NSNumber(value: 240)
        info[kIOPSPowerSourceStateKey] = kIOPSACPowerValue
        assert(BatteryEstimate(description: info)?.minutesToFloor(15) == nil)
        info[kIOPSPowerSourceStateKey] = kIOPSBatteryPowerValue
        info[kIOPSIsChargingKey] = true
        assert(BatteryEstimate(description: info)?.minutesToFloor(15) == nil)
        info[kIOPSIsChargingKey] = false
        info[kIOPSCurrentCapacityKey] = NSNumber(value: 3000)
        info[kIOPSMaxCapacityKey] = NSNumber(value: 5000)
        assert(BatteryEstimate(description: info)?.minutesToFloor(15) == 180)
        info[kIOPSMaxCapacityKey] = NSNumber(value: 0)
        assert(BatteryEstimate(description: info) == nil)
        assert(BatteryEstimate(description: [:]) == nil)
        print("battery estimate checks passed")
    }
}
