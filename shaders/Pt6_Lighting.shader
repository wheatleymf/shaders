// Shader tutorial by wheatleymf
// "Shader Fundamentals ~ Pt.6: LIGHTING AND SHADING MODEL"
// You're free to use and modify this shader.

FEATURES
{       
    // Putting this above the #include will make it appear at the top of available features
    Feature( F_EMISSION, 0..1, "Extra Features" );

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

        return FinalizeVertex( o );
    }
}    

PS
{   
    // Defining this keyword will get rid of any unnecessary input slots generated by s&box
    #define CUSTOM_MATERIAL_INPUTS
    #include "common/pixel.hlsl"

    // Declare a new static combo for the emission map 
    StaticCombo( S_EMISSION, F_EMISSION, Sys( ALL ) );

	//
	// Prepare inputs for all textures
	//
	CreateInputTexture2D( Color, 			Srgb, 	8, "", "_color", "Material,10/Albedo Map,10/10", Default3( 1.0, 1.0, 1.0 ) );						
	CreateInputTexture2D( ColorTintMask, 	Linear, 8, "", "_tint", "Material,10/Albedo Map,10/20", Default1( 1 ) );						
	CreateInputTexture2D( Normal, 			Linear, 8, "NormalizeNormals", "_normal", "Material,10/Normal Map,10/30", Default3( 0.5, 0.5, 1.0 ) );		
	CreateInputTexture2D( Roughness, 		Linear, 8, "", "_rough", "Material,10/Roughness,10/40", Default( 1 ) );											
	CreateInputTexture2D( Metalness, 		Linear, 8, "", "_metal",  "Material,10/Metalness,10/50", Default( 0 ) );									
	CreateInputTexture2D( AmbientOcclusion, Linear, 8, "", "_ao",  "Material,10/Ambient Occlusion,10/60", Default( 1 ) );

    // Emission map implementation, available only inside of a dedicated static combo
    #if ( S_EMISSION )
        CreateInputTexture2D( Emission, Srgb, 8, "", "_em", "Material,10/Emission,10/70", Default3( 0, 0, 0 ) );
        Texture2D EmissionMap < Channel( RGB, Box( Emission), Srgb ); OutputFormat( BC7 ); SrgbRead( true ); >;

        float g_flEmissionStrength < UiType( Slider ); Range( 0, 8 ); Default( 1 ); UiGroup( "Material,10/Emission,10/71"); >;
    #endif

	// 
	// Create Texture2D for all basic inputs
	// 
	Texture2D ColorMap  < Channel( RGB, Box( Color ), Srgb ); Channel( A, Box( ColorTintMask ), Linear ); OutputFormat( BC7 ); SrgbRead( true ); >;
	Texture2D NormalMap < Channel( RGB, Box( Normal ), Linear ); OutputFormat( DXT5 ); SrgbRead( false ); >; 
	Texture2D g_tRma    < Channel( R, Box( Roughness), Linear ); Channel( G, Box( Metalness ), Linear); Channel( B, Box( AmbientOcclusion ), Linear ); OutputFormat( BC7 ); SrgbRead ( false ); >; 
	
    // Control the intensity of a normal map 
    float g_flNormalIntensity < UiType( Slider ); Range( 0, 3 ); Default( 1 ); UiGroup("Material,10/Normal Map,10/31"); >; 

    // Texture scale & offset from the previous unlit shader
    int2    TextureScrollDirection < UiType( Slider ); Range2( -1, -1, 1, 1 ); Default2( 0, 0 ); UiGroup( "Settings,20/Scroll,20/10" ); >;
    float2  TextureScrollSpeed < UiType( Slider ); Range2( 0, 0, 4, 4 ); Default2( 1, 1 ); UiGroup( "Settings,20/Scroll,20/20" ); >;
    float   TextureScale < UiType( Slider ); Range( 0, 5 ); Default( 1 ); UiGroup( "Settings,20/Scale,20/30" ); >;
    float3  TextureTint < UiType( Color ); Default3( 1, 1, 1 ); UiGroup( "Settings,20/Texture Tint,20/40" ); >;

    float4 MainPs( PixelInput i ) : SV_Target0
    {
        // Reinstate UV scale & scroll direction + speed feature from unlit shader
        float2 uv = i.vTextureCoords.xy * TextureScale;
        uv += g_flTime * TextureScrollSpeed * TextureScrollDirection;        

        // Sample these packed textures
        float4 albedo = ColorMap.Sample( g_sAniso, uv ).rgba;
		float3 normal = DecodeNormal( NormalMap.Sample( g_sAniso, uv ).rgb ); // Decoding is necessary!
		float3 rma = g_tRma.Sample( g_sAniso, uv ).rgb;

        // Adjust normal map's intensity according to the user-defined variable. 
        // We shouldn't mess with blue channel, so update only RG components. 
        // This must be done transforming them into world-space normals. 
        normal.rg *= g_flNormalIntensity;

        // Before passing normal into Material class, it must be transformed from tangent-space
        // to world-space. This is necessary for the standard shading model. 
        float3 NormalTransformed = TransformNormal( normal, i.vNormalWs, i.vTangentUWs, i.vTangentVWs );

        // Initialize a new material object
        Material mat = Material::Init();

        // Fill out the material with all textures we've sampled above
        mat.Albedo = lerp( albedo.rgb, albedo.rgb * TextureTint, albedo.a );
        mat.Normal = NormalTransformed;
        mat.Roughness = rma.r;
        mat.Metalness = rma.g;
        mat.AmbientOcclusion = rma.b;
        mat.TintMask = albedo.a;

        // Static combo S_EMISSION: if it's enabled in given shader variant, then sample
        // the emission map and store it into material's Emission slot. 
        #if ( S_EMISSION )
            mat.Emission = EmissionMap.Sample( g_sAniso, uv ).rgb * g_flEmissionStrength;
        #endif
        
        // This method returns final, shaded pixel with a type of 'float4'.
        return ShadingModelStandard::Shade( i, mat );
    }
}