# OpenFIGI API C# Example

This .NET example is written to be run as a script with [`dotnet-script`](https://www.nuget.org/packages/dotnet-script/).
Example code is tested with `dotnet v8.0.404` and `dotnet-script v1.6.0`.

## Instructions

Prerequisites: `.NET 8.0` and [`dotnet-script` package](https://www.nuget.org/packages/dotnet-script/) must be installed.

```bash
# Optional: Export your API key
export OPENFIGI_API_KEY=<YOUR_KEY_HERE>
dotnet-script example.csx
```

## Docker Instructions

Prerequisites: `Docker` must be installed.

```bash
docker build --tag 'openfigi-dotnet' .

docker run --rm -it --entrypoint ./example.csx --volume ./:/OpenFIGI 'openfigi-dotnet'

# OR: If you have acquired an API Key
docker run --rm -it --entrypoint ./example.csx --volume ./:/OpenFIGI 'openfigi-dotnet' -e OPENFIGI_API_KEY=<YOUR_KEY_HERE>
```
