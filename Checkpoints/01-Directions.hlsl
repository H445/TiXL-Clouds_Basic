// Checkpoint 1. Visualize the world ray for every equirectangular texel.

static const float PI = 3.14159265359;

// The stock full-screen vertex pass supplies panorama UV and pixel coordinates for stable jitter.
struct VertexOutput
{
    float4 position : SV_POSITION;
    float2 uv : TEXCOORD;
};

// Convert longitude and polar angle into a unit world ray. Y is up, and UV.y = 0.5 is the horizon.
float3 DirectionFromUv(float2 uv)
{
    float azimuth = uv.x * (2.0 * PI);
    float polar = uv.y * PI;
    return float3(sin(azimuth) * sin(polar), cos(polar), cos(azimuth) * sin(polar));
}

// Map slice Z to a tile in the 8 by 8 atlas and sample its XY plane.
// The 1.5-texel offset places the first interior sample at its texel centre.
float4 psMain(VertexOutput input) : SV_TARGET
{
    float3 ray = DirectionFromUv(input.uv);
    return float4(ray * 0.5 + 0.5, 1.0);
}
