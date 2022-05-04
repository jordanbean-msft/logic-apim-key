using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Identity.Client;
using Microsoft.Identity.Web;
using Microsoft.Identity.Web.Resource;

namespace api.Controllers;

[ApiController]
[Route("[controller]")]
public class VehicleController : ControllerBase
{
  private readonly ILogger<VehicleController> _logger;
  private readonly HttpClient _httpClient;

  private IConfiguration _configuration;

  public VehicleController(ILogger<VehicleController> logger, IConfiguration configuration)
  {
    _logger = logger;
    _configuration = configuration;

    _httpClient = new HttpClient();
  }

  [HttpGet(Name = "GetVehicle")]
  public async Task<Vehicle> GetAsync()
  {
    string[] scopes = new string[] { _configuration.GetSection("EchoApiScope").Value };
    var app = ConfidentialClientApplicationBuilder.Create(_configuration.GetSection("AzureAd:ClientId").Value)
      .WithClientSecret(_configuration.GetSection("AzureAd:ClientSecret").Value)
      .WithAuthority(_configuration.GetSection("AzureAd:Instance").Value + _configuration.GetSection("AzureAd:TenantId").Value)
      .Build();

    var authResult = await app.AcquireTokenForClient(scopes).ExecuteAsync();

    _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", authResult.AccessToken);
    _httpClient.DefaultRequestHeaders.Add("Ocp-Apim-Subscription-Key", _configuration.GetSection("EchoApiSubscriptionKey").Value);
    _httpClient.DefaultRequestHeaders.Add("Ocp-Apim-Trace", "true");
    _httpClient.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));

    var vehicle = new Vehicle
    {
      VehicleType = "Car",
      MaxSpeed = 100,
      AvgSpeed = 50,
      SpeedUnit = "mph"
    };

    var content = new StringContent(JsonSerializer.Serialize(vehicle), Encoding.UTF8, "application/json");

    var response = await _httpClient.PutAsync(_configuration.GetSection("EchoAPIEndpoint").Value, content);
    response.EnsureSuccessStatusCode();

    var resultVehicle = await response.Content.ReadFromJsonAsync<Vehicle>();

    return resultVehicle;
  }
}
