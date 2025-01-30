// https://shaders.wheatleymf.net/
// Post-processing: screen-space fog

MODES
{
    Forward();
}

COMMON
{
	#include "postprocess/shared.hlsl"
}

struct VertexInput
{
	float3 vPositionOs : POSITION;
};

struct PixelInput
{
	float4 vPositionSs : SV_Position;
};

VS
{
    PixelInput MainVs( VertexInput i )
    {
        PixelInput o;
        o.vPositionSs = float4(i.vPositionOs.xyz, 1.0f);

        return o;
    }
}

PS
{
    #include "postprocess/common.hlsl"
    #include "common/classes/Depth.hlsl"

	float3 fogColor < Attribute( "Color" ); >;
	float fogEnd < Attribute( "FogEndDistance" ); Default( 1250 ); >;
    float fogDensity < Attribute( "FogDensity" ); Default( 0.5 ); >;
    
    CreateTexture2D( g_tColorBuffer ) < Attribute( "ColorBuffer" ); SrgbRead( true ); >;
    SamplerState sLinear < Filter( Linear ); >;

    float4 MainPs( PixelInput i ) : SV_Target0
    { 		
        // Sample frame buffer
        float3 ColorBuffer = g_tColorBuffer.Sample( sLinear, i.vPositionSs.xy / g_vViewportSize.xy ).rgb;

        // Grab the linear depth buffer value, perfect for this case
        float flLinear = Depth::GetLinear( i.vPositionSs.xy );

        float3 _fogColor = SrgbGammaToLinear( fogColor.rgb );
        float3 fogBlend = lerp( _fogColor, ColorBuffer, smoothstep( 0, fogDensity, 1 - flLinear / fogEnd ) );
        return float4( fogBlend, 1 );
    }
}