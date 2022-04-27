using Microsoft.AspNetCore.Mvc.RazorPages;
using user.Pages;

public class ResponseModel : PageModel
{
  public Vehicle Vehicle { get; set; }

  public void OnGet(Vehicle result)
  {
    Vehicle = result;
  }
}