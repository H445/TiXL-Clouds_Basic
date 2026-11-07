using T3.Core.Operator;
using T3.Core.Operator.Attributes;
using System.Runtime.InteropServices;
using T3.Core.DataTypes;
using T3.Core.Operator.Interfaces;
using T3.Core.Operator.Slots;
using T3.Core.Resource;

namespace H445.Clouds_Basic;

[Guid("2650e132-6de9-47d5-bf8b-61a2d85806bb")]
internal sealed class Clouds_Basic : Instance<Clouds_Basic>
{
    [Output(Guid = "a62a323f-9b56-5c77-8eb2-38cdc023531a")]
    public readonly Slot<Texture2D> Sky = new();
}

// ReSharper disable once UnusedType.Global
public sealed class ShareDefinition : IShareResources
{
    // ReSharper disable once EmptyConstructor
    public ShareDefinition(){}
    #pragma warning disable CA1822
    public bool ShouldShareResources => true;
    #pragma warning restore CA1822
}
