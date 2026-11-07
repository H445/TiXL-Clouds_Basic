// Checkpoint 2. Add the daylight gradient and HDR sunlight.

// The Pack shader settings group supplies b2 with FloatsToBuffer.
// Keep field order and register packing in sync with the graph when adding or changing inputs.
cbuffer CloudView : register(b2)
{
    // X rotates the sun path around world Y. Y adjusts its maximum vertical component.
    float2 SunPosition;
    // CloudScale sets the procedural sampling frequency. SunRadiance also scales direct cloud lighting.
    float CloudScale;
    float SunRadiance;
    // RGB tints the scattered cloud light. Alpha multiplies density.
    float4 CloudTint;
    // Base altitudes are in kilometres and ordered from low stratus to high cirrus.
    float StratusBaseKm;
    float CumulusBaseKm;
    float CirrusBaseKm;
    // Manual scene hour on a 24-hour clock.
    float TimeOfDay;
};

// The gradient supplies the daylight palette as a function of polar angle.
Texture2D<float4> SkyGradient : register(t0);
SamplerState LinearClamp : register(s1);

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

// Map time to a unit vector along a tilted solar path. Hour 6 and hour 18 cross the horizon.
float3 SolarDirection(float hour)
{
    float phase = (hour - 6.0) * (PI / 12.0);
    float elevation = clamp(0.68 + SunPosition.y * 0.8, 0.33, 0.95);
    float3 direction = float3(cos(phase), sin(phase) * elevation,
                             -sin(phase) * sqrt(1.0 - elevation * elevation));
    float yaw = SunPosition.x * PI;
    return float3(direction.x * cos(yaw) + direction.z * sin(yaw), direction.y,
                 direction.z * cos(yaw) - direction.x * sin(yaw));
}

// Approximate the atmosphere with an elevation gradient, solar elevation, and a directional twilight rim.
float3 Atmosphere(float3 ray, float3 sun)
{
    float elevation = max(0.0, ray.y);
    float sunrise = 1.0 - smoothstep(10.0, 14.0, TimeOfDay);
    float horizon = exp(-elevation * lerp(4.5, 7.0, sunrise));
    float daylight = smoothstep(-0.14, 0.35, sun.y);
    float twilight = smoothstep(-0.28, -0.065, sun.y) * (1.0 - smoothstep(0.04, 0.34, sun.y));
    // Compare the ray and sun in the horizontal plane so the twilight glow is strongest toward the sun.
    float2 horizontalSun = sun.xz / max(length(sun.xz), 0.0001);
    float2 horizontalRay = ray.xz / max(length(ray.xz), 0.0001);
    float facing = pow(saturate(0.5 + 0.5 * dot(horizontalRay, horizontalSun)), 2.1);
    float3 night = lerp(float3(0.013, 0.021, 0.051), float3(0.026, 0.046, 0.104), horizon);
    float3 day = SkyGradient.SampleLevel(LinearClamp, float2(0.5, acos(clamp(ray.y, -1.0, 1.0)) / PI), 0).rgb;
    float3 color = lerp(night, day, daylight);
    // Separate the upper twilight color from the horizon rim, with different palettes at sunrise and sunset.
    float3 upper = lerp(float3(0.15, 0.042, 0.23), float3(0.115, 0.23, 0.48), sunrise);
    color = lerp(color, upper, twilight * (1.0 - horizon) * 0.52);
    float3 rim = lerp(float3(1.24, 0.20, 0.075), float3(0.88, 0.40, 0.40), sunrise);
    float3 glow = lerp(float3(1.58, 0.37, 0.08), float3(1.14, 0.71, 0.43), sunrise);
    color += twilight * horizon * (rim * 0.52 + glow * facing * 0.45);
    return color;
}

// Return the HDR solar disc and two halo falloffs. cosine is dot(ray, sun), and mu is the sun's Y component.
float3 SunLight(float cosine, float mu)
{
    // The disc and both halo terms are angular, including when the sun is near the zenith.
    // Use the distance between the unit vectors as the radial coordinate for the softened disc.
    float chord = sqrt(max(0.0, 2.0 - 2.0 * cosine));
    float disc = 1.0 - smoothstep(0.0093, 0.0148, chord);
    float corona = 1.12 * exp2(-chord * 34.0) + 0.26 * exp2(-chord * 9.0);
    float3 warmth = lerp(float3(1.0, 0.67, 0.38), float3(1.0, 0.90, 0.72), smoothstep(0.01, 0.46, mu));
    return warmth * (disc * SunRadiance + corona * (SunRadiance / 21.0));
}

float4 psMain(VertexOutput input) : SV_TARGET
{
    float3 ray = DirectionFromUv(input.uv);
    float3 sun = SolarDirection(TimeOfDay);
    float3 sky = Atmosphere(ray, sun);
    sky += SunLight(dot(ray, sun), sun.y) * smoothstep(-0.012, 0.028, sun.y);
    return float4(sky, 1.0);
}
