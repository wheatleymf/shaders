// Shader tutorial by wheatleymf
// "Shader Fundamentals ~ Pt.5: RENDER ATTRIBUTES"
// You're free to use and modify this shader.

FEATURES
{   
    // This creates a new feature visible in Material Editor. 0..1 means how many options 
    // this feature has. 0 is equivalent of "false", and 1 is "true" (or "enabled").
    // Features must always start with a prefix F_, which is hidden in editor. 
    Feature( F_TINT_BY_MASK, 0..1, "Custom Features" );

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
    // Defining this keyword will get rid of any unnecessary input slots generated by s&box
    #define CUSTOM_MATERIAL_INPUTS
    #include "common/pixel.hlsl"

    // Create a static combo which will execute texture tinting by mask, instead of tinting it all. 
    // StaticCombo will be enabled depending on selected choice for a feature F_TINT_BY_MASK.
    // Static Combos must always start with a S_ prefix. 
    StaticCombo( S_TINT_BY_MASK, F_TINT_BY_MASK, Sys( ALL ) );
    DynamicCombo( D_OVERRIDE_COLOR, 0..1, Sys( ALL ) );
    
    // Create a new 2D texture input slot with a name "AlbedoMap", read in sRGB color space,
    // with file suffix "_color", inside a UI group called "My Material" on 1st place, and default color 1,1,1 (white) 
    CreateInputTexture2D( AlbedoMap, Srgb, 8, "", "_color", "My Material,10/10", Default3( 1.0, 1.0, 1.0 ) );

    // Add a float variable that will control the scale of our texture on a mesh.
    float TextureScale < UiType( Slider ); Range( 0, 5 ); Default( 1 ); UiGroup( "My Material,10/11" ); >;
    float3 TextureTint < UiType( Color ); Default3( 1, 1, 1 ); UiGroup( "My Material,10/12" ); >;

    // This variable can be updated dynamically with C#
    float3 OverrideColor < Attribute( "MyOverrideColor" ); >;

    #if ( S_TINT_BY_MASK )
        CreateInputTexture2D( TintMask, Linear, 8, "", "_tint", "My Material,10/20", Default( 1 ) );
        Texture2D g_tColor < Channel( RGB, Box( AlbedoMap ), Srgb ); Channel( A, Box( TintMask ), Linear ); OutputFormat( BC7 ); SrgbRead( true ); >;
    #else
        Texture2D g_tColor < Channel( RGB, Box( AlbedoMap ), Srgb ); OutputFormat( BC7 ); SrgbRead( true ); >;
    #endif

    // Add two float2 variables. Scroll Direction defines the scroll direction on each axis (X and Y), going either X+ or X- (or Y+ / Y-)
    // Scroll Speed will define the scrolling speed for each axis. 
    int2 TextureScrollDirection < UiType( Slider ); Range2( -1, -1, 1, 1 ); Default2( 0, 0 ); UiGroup( "Texture Scroll,20/10" ); >;
    float2 TextureScrollSpeed < UiType( Slider ); Range2( 0, 0, 4, 4 ); Default2( 1, 1 ); UiGroup( "Texture Scroll,20/20" ); >;

    float4 MainPs( PixelInput i ) : SV_Target0
    {
        // Create a new float2 variable with our texture coords, affected by TextureScale which will change the size of a texture. 
        // Then, use the shorthand operator to append animated texture offset. g_flTime is a global time variable.
        // After multiplying speed and time, we multiply it by direction. If it's zero, then total scroll offset
        // will be zero. If it's 1, then it'll keep scrolling in positive axis component. If it's -1, it'll 
        // go in opposite direction. 
        float2 uv = i.vTextureCoords * TextureScale;
        uv += g_flTime * TextureScrollSpeed * TextureScrollDirection;

        float4 MyTexture = g_tColor.Sample( g_sAniso, uv );

        // In a shader variant where S_TINT_BY_MASK is enabled, it'll tint the texture
        // according to the given grayscale mask. Only this section of code will exist
        // in that variant. And in other variant, where this feature is disabled, only
        // code section "MyTexture.rgb *= TextureTint" will exist.
        #if ( S_TINT_BY_MASK )
            MyTexture.rgb = lerp( MyTexture.rgb, MyTexture.rgb * TextureTint, MyTexture.a );
        #else 
            MyTexture.rgb *= TextureTint;
        #endif

        // If this dynamic combo is enabled, return override color attribute instead of the texture 
        return float4( D_OVERRIDE_COLOR ? OverrideColor : MyTexture.rgb, 1 );
    }
}