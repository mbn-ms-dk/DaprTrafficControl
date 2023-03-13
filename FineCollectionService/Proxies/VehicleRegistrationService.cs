using FineCollectionService.Models;

namespace FineCollectionService.Proxies;
public class VehicleRegistrationService {
    private HttpClient httpClient;

    public VehicleRegistrationService(HttpClient httpClient) {
        this.httpClient = httpClient;
    }

    public async Task<VehicleInfo> GetVehicleInfoAsync(string licenseNumber) {
        return await httpClient.GetFromJsonAsync<VehicleInfo>($"vehicleinfo/{licenseNumber}");
    }
}
