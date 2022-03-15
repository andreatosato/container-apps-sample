var builder = WebApplication.CreateBuilder(args);
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

//app.UseHttpsRedirection();
app.MapGet("/serviceonetext", () =>
{
    return Results.Ok(new { TextFromService = "FromServiceOne" });
})
.WithName("GetServiceOneText");
app.Run();
