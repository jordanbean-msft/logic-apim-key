using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Xml.Serialization;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Identity.Web;

namespace user.Pages;


[AuthorizeForScopes(Scopes = new[] { "api://34930f13-7679-40f5-9313-1b6c07dc4c09/user_impersonation" })]
public class IndexModel : PageModel
{
  private readonly ILogger<IndexModel> _logger;
  private readonly HttpClient _httpClient;

  private readonly IConfiguration _configuration;

  private readonly ITokenAcquisition _tokenAcquisition;

  public IndexModel(ILogger<IndexModel> logger, ITokenAcquisition tokenAcquisition, IConfiguration configuration)
  {
    _logger = logger;
    _tokenAcquisition = tokenAcquisition;
    _configuration = configuration;

    _httpClient = new HttpClient();
  }

  public IActionResult OnGetAsync()
  {
    return Page();
  }

  public async Task<IActionResult> OnPostAsync()
  {
    string[] scopes = new string[] { _configuration.GetSection("EchoApiScope").Value };
    string accessToken = await _tokenAcquisition.GetAccessTokenForUserAsync(scopes);

    _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
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

    return RedirectToPage("Response", resultVehicle);
  }
}
