// Shader tutorial by wheatleymf
// "Shader Fundamentals ~ Pt.2: YOUR FIRST UNLIT SHADERS"
// You're free to use and modify this shader.

FEATURES
{
    #include "common/features.hlsl"
}

MODES
{
	VrForward();
	ToolsVis( S_MODE_TOOLS_VIS );
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

    // "MainVs" is the name of a main vertex shader function. It always must be MainVs.
    // VertexInput is the "unprocessed" vertex data that we're feeding into vertex shader. It is our input. 
    // PixelInput is a type that vertex shader will return. Object of this type will be sent to fragment shader.
    PixelInput MainVs( VertexInput i )
    {
        // Create PixelInput object, initialize it with our processed vertex.
        // Between ProcessVertex() and FinalizeVertex() you can do any sorts of tricks
        // with your vertices.
        PixelInput o = ProcessVertex( i );

        // Return finalized vertex
        return FinalizeVertex( o );
    }
}    

PS
{
    #define CUSTOM_MATERIAL_INPUTS
    #include "common/pixel.hlsl"
    
	CreateInputTexture2D( AlbedoMap, Srgb, 8, "", "_color", "Material,10/10", Default3( 1.0, 1.0, 1.0 ) );
	Texture2D g_tColor < Channel( RGB, Box( AlbedoMap ), Srgb ); OutputFormat( BC7 ); SrgbRead( true ); >;

    float4 MainPs( PixelInput i ) : SV_Target0
    {
        return float4( float3( 1, 0, 0 ), 1 );
    }
}