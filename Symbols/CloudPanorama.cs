using System.Numerics;
using System.Runtime.InteropServices;
using T3.Core.DataTypes;
using T3.Core.Operator;
using T3.Core.Operator.Attributes;
using T3.Core.Operator.Slots;

namespace H445.Clouds_Basic;

[Guid("7cb776ae-9f57-5215-bf72-c39786102278")]
internal sealed class CloudPanorama : Instance<CloudPanorama>
{
    [Output(Guid = "84c66ea5-1f22-5f5c-b148-beb02cc23c0d")]
    public readonly Slot<Texture2D> Panorama = new();

    [Input(Guid = "90161fef-c94a-53e1-81c9-0692a01d1623")]
    public readonly InputSlot<float> CloudCover = new();

    [Input(Guid = "14de6c76-0d59-5669-9449-e96da4de834b")]
    public readonly InputSlot<float> CumulusBlend = new();

    [Input(Guid = "5e850083-ab76-55b2-b062-896bd39ffb77")]
    public readonly InputSlot<float> StratusBlend = new();

    [Input(Guid = "a6607b2d-618c-5b7d-aeb2-58373efcd777")]
    public readonly InputSlot<float> CirrusBlend = new();

    [Input(Guid = "510a1268-2137-5ef2-8b42-c5d995757c96")]
    public readonly InputSlot<ShaderResourceView> CloudCoverageMap = new();

    [Input(Guid = "7944bef1-4f13-55b8-8474-34759b4ae891")]
    public readonly InputSlot<Vector2> WindOffset = new();

    [Input(Guid = "6ce6bd3c-6ca3-51e6-8f58-a9d3281bb175")]
    public readonly InputSlot<float> CloudScale = new();

    [Input(Guid = "9f49071d-8eab-5ec9-89cd-2a58d7a1981c")]
    public readonly InputSlot<Vector4> CloudTint = new();

    [Input(Guid = "3b6a9fbb-9e90-5d56-9fbf-9c24e2d229fb")]
    public readonly InputSlot<float> StratusBaseKm = new();

    [Input(Guid = "bccf60a5-83a6-5acd-9e57-13dcc1ffe3c8")]
    public readonly InputSlot<float> CumulusBaseKm = new();

    [Input(Guid = "0a8096da-8161-51b1-9528-a6247718a17b")]
    public readonly InputSlot<float> CirrusBaseKm = new();

    [Input(Guid = "7237dfcf-84b1-5eac-86d8-633173eeef46")]
    public readonly InputSlot<Vector2> SunPosition = new();

    [Input(Guid = "0c3bb63d-36f2-58f6-a3cc-7b1fd18da5e0")]
    public readonly InputSlot<float> SunRadiance = new();

    [Input(Guid = "b6d6d8e4-6d9f-500a-b774-ad8ab2aba047")]
    public readonly InputSlot<float> TimeOfDay = new();
}
