using Microsoft.Extensions.Options;
using Sample.Aggregator;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.Configure<HttpConfigurations>(builder.Configuration.GetSection("HttpConfigurations"));
builder.Services.AddHttpClient(HttpConfigurations.ClientNameOne, (sp, h) =>
{
    h.BaseAddress = new Uri(sp.GetService<IOptions<HttpConfigurations>>()!.Value!.ServiceOneUrl);
});

builder.Services.AddHttpClient(HttpConfigurations.ClientNameTwo, (sp, h) =>
{
    h.BaseAddress = new Uri(sp.GetService<IOptions<HttpConfigurations>>()!.Value!.ServiceTwoUrl);
});
var app = builder.Build();


if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.MapGet("/texts", async (IHttpClientFactory clientFactory) =>
{
    var serviceOne = clientFactory.CreateClient(HttpConfigurations.ClientNameOne);
    var serviceTwo = clientFactory.CreateClient(HttpConfigurations.ClientNameTwo);
    var response = new AggregatorResponse();
    var responseOne = await serviceOne.GetFromJsonAsync<TextResponse>("/serviceonetext");
    var responseTwo = await serviceOne.GetFromJsonAsync<TextResponse>("/servicetwotext");

    response.AggregatorValue = $"{responseOne!.TextFromService} - {responseTwo!.TextFromService}";
})
.WithName("GetAggregateTexts");

app.Run();
