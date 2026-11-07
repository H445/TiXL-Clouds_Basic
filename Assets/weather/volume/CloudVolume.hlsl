// CloudVolume is the Clouds_Basic tutorial shader.
// The rendering path is UV to ray, sky and sun, cloud density, then front-to-back ray marching.
// CloudPanorama renders a linear HDR equirectangular texture. SkyRendering converts it to
// cubemaps for the visible sky dome and SetEnvironment lighting.

// The stock CustomPixelShader packs Offset and A through D into b0.
// CloudPanorama maps those slots to wind, global cover, and the three independent layer blends.
cbuffer CloudMix : register(b0)
{
    // Horizontal travel in the graph's wind units. The marcher scales it to cloud-space distance.
    float2 WindOffset;
    // Coverage lowers each layer's density threshold. Blend controls scale density separately.
    float CloudCover;
    float CumulusBlend;
    float StratusBlend;
    float CirrusBlend;
    // The remaining values in this register are unused by this shader.
    float2 Padding0;
};

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
// The atlas stores the slices of a repeating 3D noise volume in a 2D texture.
Texture2D<float4> NoiseAtlas : register(t1);
// The packed coverage map uses red for cumulus, green for stratus, and blue for cirrus.
Texture2D<float4> WeatherMap : register(t3);
SamplerState LinearClamp : register(s1);

static const float PI = 3.14159265359;
// All shell intersections and ray distances use kilometres.
static const float EarthRadius = 6371.0;

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
float3 AtlasSlice(float2 xy, float z)
{
    float2 tile = float2(fmod(z, 8.0), floor(z / 8.0));
    // Tiles are 64 by 64, with a one-pixel periodic gutter on every edge.
    return NoiseAtlas.SampleLevel(LinearClamp, (tile * 66.0 + 1.5 + xy) / 528.0, 0).rgb;
}

// Wrap all axes to tile the volume. Bilinear filtering handles XY within a slice,
// then the explicit Z interpolation blends the two nearest slices, including the wrap from 63 to 0.
float3 VolumeNoise(float3 p)
{
    float3 cell = frac(p) * 64.0;
    float z = floor(cell.z);
    return lerp(AtlasSlice(cell.xy, z), AtlasSlice(cell.xy, fmod(z + 1.0, 64.0)), frac(cell.z));
}

// Return the forward distance to a spherical shell at the given altitude.
// radialDot is the ray projected onto the local radial direction, scaled by the observer radius.
float ShellExit(float radialDot, float altitude)
{
    // Rationalized positive root keeps the near-vertical intersection precise.
    float difference = altitude * (2.0 * EarthRadius + altitude);
    return difference / max(0.0001, sqrt(max(0.0, radialDot * radialDot + difference)) + radialDot);
}

// Return a unitless density for one point in the cloud shell.
// height runs from 0 at the shell base to 1 at its top. Layer indices 0, 1, and 2 are stratus, cumulus, and cirrus.
// sampleWidth is the ray step length used to suppress details that long steps cannot resolve.
float CloudDensity(float3 p, float height, int layer, float2 flow, float scale, float sampleWidth)
{
    // Stretch each layer horizontally and give the upper layers different wind speeds.
    float2 stretch = layer == 0 ? float2(0.78, 1.12) :
                     layer == 1 ? float2(1.0, 1.0) : float2(0.83, 1.16);
    float2 wind = flow * (layer == 0 ? 0.72 : layer == 1 ? 1.0 : 1.68);
    float2 position = (p.xz - wind) * stretch;
    float3 noise = VolumeNoise(float3(position.x, p.y * 1.34, position.y) * (0.20 * scale)
                              + float3(0.17, 0.31, 0.53) * layer);
    // Mirror the large-scale coverage map at tile boundaries. Small noise offsets fray the cirrus shape.
    float2 mapUv = position / 24.0 + float2(0.41, 0.57);
    if (layer == 2)
        mapUv += (noise.rg - 0.5) * 0.030;
    mapUv = 1.0 - abs(frac(mapUv * 0.5) * 2.0 - 1.0);
    float3 weather = WeatherMap.SampleLevel(LinearClamp, mapUv, 0).rgb;
    float shape = layer == 0 ? weather.g : layer == 1 ? weather.r : weather.b;
    // Ease density in and out at the shell boundaries to avoid flat, hard cuts.
    float envelope = smoothstep(0.0, 0.16, height) * (1.0 - smoothstep(layer == 1 ? 0.48 : 0.72, 1.0, height));
    // Filter fine density structure when a grazing ray spans more than a detail cell.
    float footprint = sampleWidth * scale;
    float coarse = lerp(noise.r, 0.50, smoothstep(0.14, 0.60, footprint));
    float detail = lerp(noise.g, 0.50, smoothstep(0.055, 0.26, footprint));
    float wisps = lerp(noise.b, 0.50, smoothstep(0.028, 0.14, footprint));
    // Higher cover lowers the density cutoff. The coverage map gives the cloud its broad shape,
    // while the higher-frequency noise removes material from the edges.
    float cutoff = layer == 0 ? lerp(0.73, 0.30, saturate(CloudCover)) :
                   layer == 1 ? lerp(0.76, 0.36, saturate(CloudCover)) :
                                lerp(0.69, 0.26, saturate(CloudCover));
    float weatherWeight = layer == 0 ? 0.71 : layer == 1 ? 0.56 : 0.64;
    float body = lerp(coarse, shape, weatherWeight);
    float erosion = (1.0 - detail) * (layer == 1 ? 0.115 : 0.052) + (1.0 - wisps) * 0.035;
    return saturate((body - cutoff - erosion + (envelope - 1.0) * 0.18) * 5.2) * envelope;
}

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

// Ray march a single cloud shell, updating the accumulated scattered light and remaining transmittance.
// The caller carries both values from the nearest layer through the farthest layer.
void IntegrateLayer(float3 ray, float radialDot, float3 sun,
                    float3 haze, float baseAltitude, float depth, float strength, int layer, float phase,
                    inout float3 light, inout float transmittance)
{
    if (strength <= 0.0001 || transmittance < 0.008)
        return;

    // Bound grazing rays by the layer's draw distance and intersect the inner and outer shell surfaces.
    float maxDistance = layer == 0 ? 41.0 : layer == 1 ? 63.0 : 124.0;
    float t0 = ShellExit(radialDot, baseAltitude);
    float t1 = min(maxDistance, ShellExit(radialDot, baseAltitude + depth));
    if (t1 <= t0)
        return;

    // Use small steps for short rays and increase step length as needed to stay within the layer's sample budget.
    int maxSteps = layer == 0 ? 36 : layer == 1 ? 64 : 32;
    float nominalStep = layer == 2 ? 0.047 : 0.035;
    float stepSize = max(nominalStep, (t1 - t0) / maxSteps);
    int stepCount = min(maxSteps, (int)ceil((t1 - t0) / stepSize));
    float extinction = layer == 0 ? 6.5 : layer == 1 ? 4.1 : 3.0;
    float2 flow = WindOffset * 20.0;
    float scale = max(0.15, CloudScale / 9.0);
    // Precompute the sun-facing glow and solar elevation weights once per ray.
    float forwardGlow = pow(saturate(dot(ray, sun)), 9.0);
    float daylight = smoothstep(-0.08, 0.16, sun.y);
    float ambientDay = smoothstep(-0.20, 0.30, sun.y);
    float sunrise = 1.0 - smoothstep(10.0, 14.0, TimeOfDay);
    float3 horizonSun = lerp(float3(1.0, 0.33, 0.14), float3(1.0, 0.62, 0.48), sunrise);
    // Use the default HDR radiance of 12 as the reference brightness for direct and twilight scattering.
    float directIntensity = max(SunRadiance, 0.0) / 12.0;
    float3 sunTint = lerp(horizonSun, float3(1.0, 0.97, 0.90), smoothstep(0.0, 0.47, sun.y));

    [loop] for (int sampleIndex = 0; sampleIndex < stepCount; ++sampleIndex)
    {
        // Jitter the sample within its segment. Clamp the final segment to the shell exit.
        float start = t0 + sampleIndex * stepSize;
        float segment = clamp(t1 - start, 0.0, stepSize);
        float distance = start + segment * phase;
        float3 p = ray * distance;
        // Convert the local sample position to an approximate altitude above the curved Earth.
        float curvature = dot(p.xz, p.xz) / (2.0 * EarthRadius);
        float height = saturate((p.y + curvature - baseAltitude) / depth);
        float density = CloudDensity(p, height, layer, flow, scale, stepSize);
        density *= strength * saturate(CloudTint.a) * smoothstep(0.0, 0.15, CloudCover);
        // Fade the layer before its distance limit and skip lighting for effectively empty samples.
        density *= 1.0 - smoothstep(maxDistance * 0.49, maxDistance, distance);
        if (density < 0.0003)
            continue;

        // Take one density sample toward the sun as a cheap approximation of cloud self-shadowing.
        float lightDistance = layer == 1 ? 0.36 : 0.16;
        float3 sunSample = p + sun * lightDistance;
        float sunHeight = height + sun.y * lightDistance / depth;
        float sunDensity = sunHeight < 1.0 && sunHeight > 0.0
                         ? CloudDensity(sunSample, sunHeight, layer, flow, scale, stepSize) : 0.0;
        float direct = exp(-sunDensity * (layer == 1 ? 2.3 : 1.25));
        // Mix ambient light, twilight color and direct sunlight. Higher parts of the cloud get more ambient fill.
        float ambient = lerp(layer == 2 ? 0.49 : 0.28, 0.58, height);
        float3 cloudLight = lerp(float3(0.022, 0.035, 0.073), float3(0.77, 0.86, 1.0) * ambient, ambientDay);
        float twilight = smoothstep(-0.23, -0.06, sun.y) * (1.0 - smoothstep(0.04, 0.31, sun.y));
        float3 twilightCloud = lerp(float3(0.39, 0.115, 0.075), float3(0.19, 0.24, 0.37), sunrise);
        float3 cloudEdge = lerp(float3(0.17, 0.035, 0.012), float3(0.24, 0.115, 0.075), sunrise);
        cloudLight += directIntensity * twilight * (twilightCloud * (0.34 + 0.66 * direct) + cloudEdge * direct * (0.45 + 0.55 * height));
        cloudLight += directIntensity * sunTint * daylight * (0.54 * direct + 0.20 * forwardGlow * (0.25 + 0.75 * direct));
        // Blend toward horizon haze with distance to soften the far layers.
        cloudLight = lerp(cloudLight * CloudTint.rgb, haze, 1.0 - exp(-distance * 0.026));

        // Beer-Lambert attenuation turns optical depth into a segment opacity.
        // Add this segment's light after attenuation by earlier samples, then reduce the light that can pass behind it.
        float stepAlpha = 1.0 - exp(-density * extinction * segment);
        light += transmittance * stepAlpha * cloudLight;
        transmittance *= 1.0 - stepAlpha;
        if (transmittance < 0.008)
            break;
    }
}

// Evaluate the sky for one panorama texel and composite it with the cloud volume in linear HDR.
float4 psMain(VertexOutput input) : SV_TARGET
{
    float3 ray = DirectionFromUv(input.uv);
    float3 sun = SolarDirection(TimeOfDay);
    float2 horizontal = ray.xz / max(length(ray.xz), 0.0001);
    float3 haze = Atmosphere(float3(horizontal.x, 0.0, horizontal.y), sun);

    // Start with the HDR sky and sun behind the cloud volume.
    float3 sky = Atmosphere(ray, sun);
    sky += SunLight(dot(ray, sun), sun.y) * smoothstep(-0.012, 0.028, sun.y);

    // Start with no cloud light and full visibility of the background.
    float3 light = 0.0;
    float transmittance = 1.0;
    if (ray.y > 0.0 && CloudCover > 0.0)
    {
        // The tutorial camera rotates from sea level. Intersect each curved cloud shell.
        float radialDot = ray.y * EarthRadius;
        // Keep layers in altitude order even if the exposed base heights cross.
        float stratus = max(StratusBaseKm, 0.1);
        float cumulus = max(CumulusBaseKm, stratus + 0.48);
        float cirrus = max(CirrusBaseKm, cumulus + 1.20);

        // Jitter the samples with a stable panorama-space phase to soften stepping.
        float noise = frac(52.9829189 * frac(dot(floor(input.position.xy), float2(0.06711056, 0.00583715))));
        float phase = 0.24 + 0.52 * noise;
        // March low stratus first, then cumulus, then high cirrus.
        IntegrateLayer(ray, radialDot, sun, haze, stratus, 0.38, StratusBlend, 0, phase, light, transmittance);
        IntegrateLayer(ray, radialDot, sun, haze, cumulus, 1.08, CumulusBlend, 1, phase, light, transmittance);
        IntegrateLayer(ray, radialDot, sun, haze, cirrus, 0.54, CirrusBlend, 2, phase, light, transmittance);
    }

    // Each layer contributes light and absorbs part of the sky behind it.
    return float4(light + transmittance * sky, 1.0);
}
