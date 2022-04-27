using System;
using System.Collections.Generic;
using System.Net;
using System.Threading.Tasks;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;

namespace Company.Function
{
  public static class GenerateNewSubscriptionKey
  {
    [Function("GenerateNewSubscriptionKey")]
    public static async Task<HttpResponseData> RunAsync([HttpTrigger(AuthorizationLevel.Anonymous, "get", "post")] HttpRequestData req,
        FunctionContext executionContext)
    {
      var response = req.CreateResponse(HttpStatusCode.OK);
      await response.WriteAsJsonAsync(new
      {
        value = Guid.NewGuid().ToString()
      });

      return response;
    }
  }
}
