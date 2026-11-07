using System.Numerics;
using System.Runtime.InteropServices;
using T3.Core.DataTypes;
using T3.Core.Operator;
using T3.Core.Operator.Attributes;
using T3.Core.Operator.Slots;

namespace H445.Clouds_Basic;

[Guid("c6af4e07-0d5a-5bf7-8b8b-c0ba90b1a3d0")]
internal sealed class CloudMaps : Instance<CloudMaps>
{
    [Output(Guid = "25780506-c41d-5ead-a49b-872399f78c93")]
    public readonly Slot<ShaderResourceView> CloudCoverageMap = new();

    [Output(Guid = "a5ded78b-b621-5ed0-96b7-690d8af6bd90")]
    public readonly Slot<Vector2> WindOffset = new();

    [Input(Guid = "8d9a41b4-9790-5953-b3e3-9b559c013c9f")]
    public readonly InputSlot<float> CloudScale = new();

    [Input(Guid = "f582122c-9544-58bd-a540-414e1fcfa1c4")]
    public readonly InputSlot<float> WindSpeed = new();

    [Input(Guid = "f8a6e0cf-e880-5871-bd98-08719313ffd0")]
    public readonly InputSlot<Vector2> WindDirection = new();
}
