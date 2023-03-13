namespace TrafficControlService.Models;
public record struct VehicleState {
    public string LicenseNumber { get; init; }
    public DateTime EntryTimeStamp { get; init; }
    public DateTime? ExitTimeStamp { get; init; }

    public VehicleState(string licenseNumber, DateTime entryTime, DateTime? exitTime = null) {
        LicenseNumber = licenseNumber;
        EntryTimeStamp = entryTime;
        ExitTimeStamp = exitTime;
    }
}
