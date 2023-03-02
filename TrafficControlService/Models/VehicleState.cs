namespace TrafficControlService.Models {
    public record struct VehicleState {
        public string LicensePlate { get; init; }
        public DateTime EntryTimeStamp { get; init; }
        public DateTime? ExitTimeStamp { get; init; }

        public VehicleState(string licensePlate, DateTime entryTime, DateTime? exitTime = null) 
        {
            LicensePlate = licensePlate;
            EntryTimeStamp = entryTime;
            ExitTimeStamp = exitTime;
        }
    }
}
