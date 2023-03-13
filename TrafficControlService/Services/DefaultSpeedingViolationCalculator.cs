namespace TrafficControlService.Services;
public class DefaultSpeedingViolationCalculator : ISpeedingViolationCalculator {
    private readonly string roadId;
    private readonly int sectionLengthInKm;
    private readonly int maxAllowedSpeedInKmh;
    private readonly int legalCorrectionInKmh;
    public DefaultSpeedingViolationCalculator(string roadId, int sectionLengthInKm, int maxAllowedSpeedInKmh, int legalCorrectionInKmh) {
        this.roadId = roadId;
        this.sectionLengthInKm = sectionLengthInKm;
        this.maxAllowedSpeedInKmh = maxAllowedSpeedInKmh;
        this.legalCorrectionInKmh = legalCorrectionInKmh;
    }

    public int DetermineSpeedingViolationInKmh(DateTime entryTime, DateTime exitTime) {
        double elapsedMinutes = exitTime.Subtract(entryTime).TotalSeconds; //1 sec == 1 min in simulation
        double avgSpeedInKmh = Math.Round((sectionLengthInKm / elapsedMinutes) * 60);
        int violation = Convert.ToInt32(avgSpeedInKmh - maxAllowedSpeedInKmh - legalCorrectionInKmh);
        return violation;
    }

    public string GetRoadId() {
        return roadId;
    }
}