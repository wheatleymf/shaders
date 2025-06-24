FEATURES
{
    #include "common/features.hlsl"
}

MODES
{
    Forward();
    Depth();
}

COMMON
{
	#include "common/shared.hlsl"
}

struct VertexInput
{
	#include "common/vertexinput.hlsl"
};

struct PixelInput
{
	#include "common/pixelinput.hlsl"
};

VS
{
	#include "common/vertex.hlsl"

	PixelInput MainVs( VertexInput i )
	{
		PixelInput o = ProcessVertex( i );

		// Adjust the vertices so they appear correctly as a skybox material
		float3 vPositionWs = g_vCameraPositionWs.xyz + i.vPositionOs.xyz * 100;
		o.vPositionPs = Position3WsToPs( vPositionWs.xyz );
		o.vPositionWs = vPositionWs;

		return FinalizeVertex( o );
	}
}

PS
{
	#define CUSTOM_MATERIAL_INPUTS // guh  
    #include "common/pixel.hlsl"

	RenderState( CullMode, NONE );

	float4 MainPs( PixelInput i ) : SV_Target0
	{
		float3 vPositionWs = i.vPositionWithOffsetWs + g_vCameraPositionWs;
		float3 vRay = normalize( vPositionWs - g_vCameraPositionWs );
		float3 vCamDir = g_vCameraDirWs;

		// Return view ray vector as a quick placeholder 
		return float4( vRay * 0.5 + 0.5, 1 );
	}
}
