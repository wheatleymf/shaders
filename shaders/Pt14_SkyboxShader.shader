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
	#define CUSTOM_MATERIAL_INPUTS // This is necessary evil shit
    #include "common/pixel.hlsl"
	#include "procedural.hlsl"

	// Backfaces rendering must be enabled to make shader render properly as a skybox material
	RenderState( CullMode, NONE );

	// Material properties
	float3 SkyColor < UiType( Color ); Default3( 1, 1, 1 ); UiGroup( "Sky, 10/10" ); >;
	float3 SkyHorizon < UiType( Color ); Default3( 1, 0, 1 ); UiGroup( "Sky, 10/20" ); >;

	// Cubemap texture (won't show up until you uncommented cubemap sampling code)
	CreateInputTextureCube( SkyTexture, Srgb, 8, "", "_color", "Sky, 20/30", Default3( 1, 1, 1 ) );
	TextureCube g_tSkyTexture < Channel( RGB, Box( SkyTexture ), Srgb ); OutputFormat( BC7 ); SrgbRead( true ); >;

	// Rotation with angle (in radians) and axis
	// from: https://gist.github.com/keijiro/ee439d5e7388f3aafc5296005c8c3f33
	float3x3 AngleAxis3x3( float angle, float3 axis )
	{
		float c, s;
		sincos(angle, s, c);

		float t = 1 - c;
		float x = axis.x;
		float y = axis.y;
		float z = axis.z;

		return float3x3(
			t * x * x + c,      t * x * y - s * z,  t * x * z + s * y,
			t * x * y + s * z,  t * y * y + c,      t * y * z - s * x,
			t * x * z - s * y,  t * y * z + s * x,  t * z * z + c
		);
	}

	float4 MainPs( PixelInput i ) : SV_Target0
	{
		float3 vPositionWs = i.vPositionWithOffsetWs + g_vCameraPositionWs;
		float3 vRay = normalize( vPositionWs - g_vCameraPositionWs );

		// ================================================================================

		// Draw basic sky + horizon colors using the Z component of view ray vector
		float3 sky = lerp( SkyHorizon, SkyColor, saturate( vRay.z * 2 ) );

		// ================================================================================

		// Loop through all available light sources using light API, skip all lights
		// that aren't directional. 
		for ( int j = 0; j < Light::Count( i.vPositionSs.xy ); j++ )
        {
            Light light = Light::From( i.vPositionSs.xy, vPositionWs, j ); 

            if ( distance( light.Position, light.Direction ) <= 1 ) 
                continue;

			float fSun = pow( saturate( dot( vRay, light.Direction ) ), 10000 ) * 20;

			fSun *= saturate( vRay.z * 100 );
			sky += light.Color * fSun * 5;
        }
		
		// ================================================================================

		// [OPTIONAL!]
		// This is an example of sampling and drawing a texture cube. :-)
		// Rotate view ray around Z axis 
	/* 
		float3x3 mAxisRotation = AngleAxis3x3( g_flTime * 0.05, float3( 0, 0, 1 ) ); 
		float3 vRayRotation = mul( vRay, mAxisRotation );

		float3 CubeSky = g_tSkyTexture.Sample( g_sAniso, vRayRotation );
		sky += CubeSky;
	*/

		// ================================================================================

		// Draw clouds
		float2 vCloudUv = vRay.xy / abs( vRay.z );
		float cloud = Simplex2D( vCloudUv - g_flTime * 0.1 ) * 0.5 + 0.5;
		cloud *= saturate( vRay.z * 0.5 ); 
		sky += cloud;

		// ================================================================================

		// Draw atmospherics
		sky = Fog::Apply( Depth::GetWorldPosition( i.vPositionSs.xy ), i.vPositionSs.xy, sky );

		return float4( sky, 1 );
	}
}
