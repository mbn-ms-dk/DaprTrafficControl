namespace FineCollectionService.Services;
// This is a hard coded implementation of the fine calculator
public class HardCodedFineCalculator : IFineCalculator {
    public int CalculateFine(int violationInKMh) {

        int fine = 9; // default administration fee
        if (violationInKMh < 5) {
            fine += 18;
        }
        else if (violationInKMh >= 5 && violationInKMh < 10) {
            fine += 31;
        }
        else if (violationInKMh >= 10 && violationInKMh < 15) {
            fine += 64;
        }
        else if (violationInKMh >= 15 && violationInKMh < 20) {
            fine += 121;
        }
        else if (violationInKMh >= 20 && violationInKMh < 25) {
            fine += 174;
        }
        else if (violationInKMh >= 25 && violationInKMh < 30) {
            fine += 232;
        }
        else if (violationInKMh >= 25 && violationInKMh < 35) {
            fine += 297;
        }
        else if (violationInKMh == 35) {
            fine += 372;
        }
        else {
            // violation above 35 KMh will be determined by the prosecutor
            return 0;
        }

        return fine;
    }
}
