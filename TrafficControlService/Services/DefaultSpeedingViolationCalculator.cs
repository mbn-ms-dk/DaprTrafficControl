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

    //method to calculate the speeding violation in km/h
    public int DetermineSpeedingViolationInKmh(DateTime entryTime, DateTime exitTime) {
        var timeDifference = exitTime - entryTime;
        var timeDifferenceInHours = timeDifference.TotalHours;
        var averageSpeedInKmh = sectionLengthInKm / timeDifferenceInHours;
        var speedingViolationInKmh = averageSpeedInKmh - maxAllowedSpeedInKmh - legalCorrectionInKmh;
        return (int) Math.Round(speedingViolationInKmh);
    }

    public string GetRoadId() {
        return roadId;
    }
}