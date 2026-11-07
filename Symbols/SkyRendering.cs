using System.Numerics;
using System.Runtime.InteropServices;
using T3.Core.DataTypes;
using T3.Core.Operator;
using T3.Core.Operator.Attributes;
using T3.Core.Operator.Slots;

namespace H445.Clouds_Basic;

[Guid("1a48f167-0b03-5cda-9910-37274ba656db")]
internal sealed class SkyRendering : Instance<SkyRendering>
{
    [Output(Guid = "f1096e1e-4929-5c3f-8452-0e8dafdcbe01")]
    public readonly Slot<Command> DrawSky = new();

    [Output(Guid = "76b3a30c-681f-5ad2-ba43-6cbd31775736")]
    public readonly Slot<Texture2D> LightingCubemap = new();

    [Input(Guid = "7ea0d690-a238-5fae-80f2-1c606efaa91a")]
    public readonly InputSlot<Texture2D> Panorama = new();
}
