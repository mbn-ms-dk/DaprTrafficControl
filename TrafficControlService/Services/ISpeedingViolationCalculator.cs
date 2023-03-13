namespace TrafficControlService.Services;
public interface ISpeedingViolationCalculator {
    int DetermineSpeedingViolationInKmh(DateTime entryTime, DateTime exitTime);
    string GetRoadId();
}
