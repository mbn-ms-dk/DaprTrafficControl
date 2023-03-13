using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.AccessControl;
using System.Text;
using System.Threading.Tasks;
using TrafficSimulationServiceConsole.Events;
using TrafficSimulationServiceConsole.Services;

namespace TrafficSimulationServiceConsole;
    public  class CameraSimulation {
    private readonly ITrafficControlService trafficControlService;
    private Random rnd;
    private int camNumber;
    private int minEntryDelayInMS = 50;
    private int maxEntryDelayInMS = 5000;
    private int minExitDelayInS = 4;
    private int maxExitDelayInS = 10;

    public CameraSimulation(int cameraNumber, ITrafficControlService trafficControlService) {
        this.trafficControlService = trafficControlService;
        camNumber = cameraNumber;
        rnd = new Random();
    }

    public  Task start() {
        Console.WriteLine($"Start camera {camNumber} simulation");
        while ( true ) {
            try {
                var entryDelay = TimeSpan.FromMilliseconds(rnd.Next(minEntryDelayInMS, maxEntryDelayInMS) + rnd.NextDouble());
                Task.Delay(entryDelay).Wait();

                Task.Run(async () => {
                    //simulate entry
                    var entryTimestamp = DateTime.Now;
                    var vehicleRegistered = new VehicleRegistered {
                        Lane = camNumber,
                        LicenseNumber = GenerateRandomLicenseNumber(),
                        Timestamp = entryTimestamp
                    };
                    await trafficControlService.SendVehicleEntryAsync(vehicleRegistered);
                    Console.WriteLine($"Simulated ENTRY of vehicle with license-number {vehicleRegistered.LicenseNumber} in lane {vehicleRegistered.Lane}");


                    // simulate exit
                    var exitDelay = TimeSpan.FromSeconds(rnd.Next(minExitDelayInS, maxExitDelayInS) + rnd.NextDouble());
                    Task.Delay(exitDelay).Wait();
                    vehicleRegistered.Timestamp = DateTime.Now;
                    vehicleRegistered.Lane = rnd.Next(1, 4);
                    await trafficControlService.SendVehicleExitAsync(vehicleRegistered);
                    Console.WriteLine($"Simulated EXIT of vehicle with license-number {vehicleRegistered.LicenseNumber} in lane {vehicleRegistered.Lane}");
                }).Wait();
            }
            catch (Exception ex) {
                Console.WriteLine($"Camera {camNumber} error: {ex.Message}");
            }
        }
    }

    #region Private helper methods

    private string _validLicenseNumberChars = "DFGHJKLNPRSTXYZ";

    private string GenerateRandomLicenseNumber() {
        int type = rnd.Next(1, 9);
        string licenseNumber = string.Empty;
        switch (type) {
            case 1: // 99-AA-99
                licenseNumber = string.Format("{0:00}-{1}-{2:00}", rnd.Next(1, 99), GenerateRandomCharacters(2), rnd.Next(1, 99));
                break;
            case 2: // AA-99-AA
                licenseNumber = string.Format("{0}-{1:00}-{2}", GenerateRandomCharacters(2), rnd.Next(1, 99), GenerateRandomCharacters(2));
                break;
            case 3: // AA-AA-99
                licenseNumber = string.Format("{0}-{1}-{2:00}", GenerateRandomCharacters(2), GenerateRandomCharacters(2), rnd.Next(1, 99));
                break;
            case 4: // 99-AA-AA
                licenseNumber = string.Format("{0:00}-{1}-{2}", rnd.Next(1, 99), GenerateRandomCharacters(2), GenerateRandomCharacters(2));
                break;
            case 5: // 99-AAA-9
                licenseNumber = string.Format("{0:00}-{1}-{2}", rnd.Next(1, 99), GenerateRandomCharacters(3), rnd.Next(1, 10));
                break;
            case 6: // 9-AAA-99
                licenseNumber = string.Format("{0}-{1}-{2:00}", rnd.Next(1, 9), GenerateRandomCharacters(3), rnd.Next(1, 10));
                break;
            case 7: // AA-999-A
                licenseNumber = string.Format("{0}-{1:000}-{2}", GenerateRandomCharacters(2), rnd.Next(1, 999), GenerateRandomCharacters(1));
                break;
            case 8: // A-999-AA
                licenseNumber = string.Format("{0}-{1:000}-{2}", GenerateRandomCharacters(1), rnd.Next(1, 999), GenerateRandomCharacters(2));
                break;
        }

        return licenseNumber;
    }

    private string GenerateRandomCharacters(int amount) {
        char[] chars = new char[amount];
        for (int i = 0; i < amount; i++) {
            chars[i] = _validLicenseNumberChars[rnd.Next(_validLicenseNumberChars.Length - 1)];
        }
        return new string(chars);
    }

    #endregion
}
