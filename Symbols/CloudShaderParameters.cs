using System.Runtime.InteropServices;
using T3.Core.Operator;
using T3.Core.Operator.Attributes;
using T3.Core.Operator.Slots;

namespace H445.Clouds_Basic;

[Guid("3d890761-b88f-57e2-9f1d-7ffba0349e5a")]
internal sealed class CloudShaderParameters : Instance<CloudShaderParameters>
{
    [Output(Guid = "501752b6-0bbb-5ed1-a71a-964016e01427")]
    public readonly Slot<Buffer> SettingsBuffer = new();

    [Input(Guid = "f92c56de-b2b2-58f1-b271-97f5b8de73c1")]
    public readonly InputSlot<Vector2> SunPosition = new();

    [Input(Guid = "7d777362-8500-5225-9f9a-16586fddb294")]
    public readonly InputSlot<float> CloudScale = new();

    [Input(Guid = "43bf3d6f-18d7-5c36-a027-b5e125daa8cd")]
    public readonly InputSlot<float> SunRadiance = new();

    [Input(Guid = "49e71232-6094-5d1d-abd6-5631fb81fe06")]
    public readonly InputSlot<Vector4> CloudTint = new();

    [Input(Guid = "65a4a41f-2e56-5b91-b3be-702b7256fdf2")]
    public readonly InputSlot<float> StratusBaseKm = new();

    [Input(Guid = "b93ef9b4-8bd4-5abd-81d8-5bfa5c581fcb")]
    public readonly InputSlot<float> CumulusBaseKm = new();

    [Input(Guid = "150fd70b-72f9-526b-9511-88c470a41590")]
    public readonly InputSlot<float> CirrusBaseKm = new();

    [Input(Guid = "2116c791-d420-5e0f-b7f3-a258e76b321d")]
    public readonly InputSlot<float> TimeOfDay = new();
}
