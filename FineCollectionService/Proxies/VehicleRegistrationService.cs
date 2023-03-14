using FineCollectionService.Models;

namespace FineCollectionService.Proxies;
public class VehicleRegistrationService {
    private HttpClient httpClient;

    public VehicleRegistrationService(HttpClient httpClient) {
        this.httpClient = httpClient;
    }

    public async Task<VehicleInfo> GetVehicleInfoAsync(string licenseNumber) {
        Console.WriteLine($"VH REG {httpClient.BaseAddress?.AbsoluteUri}");
        return await httpClient.GetFromJsonAsync<VehicleInfo>($"vehicleinfo?licensenumber={licenseNumber}");
    }
}
