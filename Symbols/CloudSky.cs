using System.Numerics;
using System.Runtime.InteropServices;
using T3.Core.DataTypes;
using T3.Core.Operator;
using T3.Core.Operator.Attributes;
using T3.Core.Operator.Slots;

namespace H445.Clouds_Basic;

[Guid("3508d042-e321-5fce-8dbc-1d33ef6d4bb7")]
internal sealed class CloudSky : Instance<CloudSky>
{
    [Output(Guid = "9c4eff21-3ccb-5bed-b7b7-9186101ec4dd")]
    public readonly Slot<Command> Environment = new();

    [Input(Guid = "5265e1ee-25de-5ed0-ad93-66f08941ff3f")]
    public readonly InputSlot<float> CloudCover = new();

    [Input(Guid = "aadf7682-803b-5e67-9320-2df9e94b7f9d")]
    public readonly InputSlot<float> CumulusBlend = new();

    [Input(Guid = "73363ae7-3c71-5975-8298-a94d164fb1eb")]
    public readonly InputSlot<float> StratusBlend = new();

    [Input(Guid = "26374c83-3dff-5428-9755-ca46b9ac0d55")]
    public readonly InputSlot<float> CirrusBlend = new();

    [Input(Guid = "d65c8d21-624e-5fe1-adbf-6c1d7c44c691")]
    public readonly InputSlot<float> CloudScale = new();

    [Input(Guid = "16a25821-2f08-5c3f-8b13-f02d0fe119bb")]
    public readonly InputSlot<Vector4> CloudTint = new();

    [Input(Guid = "d27737c2-6dcf-5e81-a75d-2b3ac012ff2b")]
    public readonly InputSlot<float> WindSpeed = new();

    [Input(Guid = "860882c3-8ada-58e0-aab6-77fbc3fe2784")]
    public readonly InputSlot<Vector2> WindDirection = new();

    [Input(Guid = "13c5f537-fa82-5e56-8905-2352468f0a2c")]
    public readonly InputSlot<Vector2> SunPosition = new();

    [Input(Guid = "5f2e0fd7-9218-5c47-948f-9302993acee9")]
    public readonly InputSlot<float> EnvironmentExposure = new();

    [Input(Guid = "28178983-fd8d-5596-8602-f39c9b3902c0")]
    public readonly InputSlot<bool> UpdateLive = new();

    [Input(Guid = "26419c8d-72f0-54e6-8efe-bbad9897defc")]
    public readonly InputSlot<Command> Scene = new();

    [Input(Guid = "7d16d7c8-7b7f-54a5-9b2b-92eed6474d64")]
    public readonly InputSlot<float> StratusBaseKm = new();

    [Input(Guid = "b123d18f-5a26-5792-8ca2-9d1f46e1739b")]
    public readonly InputSlot<float> CumulusBaseKm = new();

    [Input(Guid = "8bf4de51-446d-5a07-ae2b-351c53f8033b")]
    public readonly InputSlot<float> CirrusBaseKm = new();

    [Input(Guid = "c12d2cc0-3412-5231-8e69-7358a8819c83")]
    public readonly InputSlot<float> SunRadiance = new();

    [Input(Guid = "3eff78b4-6d34-5731-9946-08c9fe32d79b")]
    public readonly InputSlot<float> TimeOfDay = new();
}
