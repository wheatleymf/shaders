// Shader tutorial by wheatleymf
// "Shader Fundamentals ~ Pt.9: TEXTURE BLENDING"
// You're free to use and modify this shader.

FEATURES
{       
    // Putting this above the #include will make it appear at the top of available features
    Feature( F_EMISSION, 0..1, "Extra Features" );
    Feature( F_BLEND_LAYER, 0..1, "Extra Features" );
    Feature( F_TRANSPARENCY, 0..1, "Transparency" );
    Feature( F_ALPHA_TEST, 0..1, "Transparency");

    // Makes F_ALPHA_TEST unavailable if F_TRANSPARENCY isn't enabled yet. 
    FeatureRule( Requires1( F_ALPHA_TEST, F_TRANSPARENCY ), "Alpha test is available only with transparency enabled!" );

    #include "common/features.hlsl"
}

MODES
{
	VrForward();
}   

COMMON
{
	#include "common/shared.hlsl"
}

struct VertexInput
{
	#include "common/vertexinput.hlsl"

    // Extend VertexInput struct with additional property for vertex colors
    float4 vColor : COLOR0 < Semantic( Color ); >;
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
        
        // Convert sRGB vertex colors to linear, and store them in PixelInput's vVertexColor property. 
        // In fragment shader, you'll be able to use vertex colors by accessing i.vVertexColor. :-) 
        o.vVertexColor.rgb = i.vColor.rgb;

        return FinalizeVertex( o );
    }
}    

PS
{   
    // Defining this keyword will get rid of any unnecessary input slots generated by s&box
    #define CUSTOM_MATERIAL_INPUTS
    #include "common/pixel.hlsl"

    // Declare a new static combo for the emission map & transparency
    StaticCombo( S_EMISSION, F_EMISSION, Sys( ALL ) );
    StaticCombo( S_TRANSPARENCY, F_TRANSPARENCY, Sys( ALL ) );
    StaticCombo( S_BLEND_LAYER, F_BLEND_LAYER, Sys( ALL ) );

	//
	// Prepare inputs for all textures
	//
	CreateInputTexture2D( Color, 			Srgb, 	8, "", "_color", "Material A,10/Albedo Map,10/10", Default3( 1.0, 1.0, 1.0 ) );						
	CreateInputTexture2D( ColorTintMask, 	Linear, 8, "", "_tint", "Material A,10/Albedo Map,10/20", Default1( 1 ) );						
	CreateInputTexture2D( Normal, 			Linear, 8, "NormalizeNormals", "_normal", "Material A,10/Normal Map,10/30", Default3( 0.5, 0.5, 1.0 ) );		
	CreateInputTexture2D( HeightMask,       Linear, 8, "", "_height", "Material A,10/Height Blend Mask,10/35", Default( 1 ) );
    CreateInputTexture2D( Roughness, 		Linear, 8, "", "_rough", "Material A,10/Roughness,10/40", Default( 1 ) );											
	CreateInputTexture2D( Metalness, 		Linear, 8, "", "_metal",  "Material A,10/Metalness,10/50", Default( 0 ) );									
	CreateInputTexture2D( AmbientOcclusion, Linear, 8, "", "_ao",  "Material A,10/Ambient Occlusion,10/60", Default( 1 ) );

    // 
    // Second layer rendered on top, create input slots
    //
    #if ( S_BLEND_LAYER )
        CreateInputTexture2D( LayerColor, 		    Srgb, 	8, "", "_color", "Material B,20/Albedo Map,20/10", Default3( 1.0, 1.0, 1.0 ) );						
        CreateInputTexture2D( LayerColorTintMask, 	Linear, 8, "", "_tint", "Material B,20/Albedo Map,20/20", Default1( 1 ) );						
        CreateInputTexture2D( LayerNormal, 			Linear, 8, "NormalizeNormals", "_normal", "Material B,20/Normal Map,20/30", Default3( 0.5, 0.5, 1.0 ) );		
        CreateInputTexture2D( LayerRoughness, 		Linear, 8, "", "_rough", "Material B,20/Roughness,20/40", Default( 1 ) );											
        CreateInputTexture2D( LayerMetalness, 		Linear, 8, "", "_metal",  "Material B,20/Metalness,20/50", Default( 0 ) );									
        CreateInputTexture2D( LayerAmbientOcclusion,Linear, 8, "", "_ao",  "Material B,20/Ambient Occlusion,20/60", Default( 1 ) );

        // Input slot for 2nd layer emission if it's enabled
        #if ( S_EMISSION )
            CreateInputTexture2D( LayerEmission, Srgb, 8, "", "_em", "Material B,20/Emission,20/70", Default3( 0, 0, 0 ) );
            Texture2D layerEmissionMap < Channel( RGB, Box( LayerEmission ), Srgb ); OutputFormat( BC7 ); SrgbRead( true ); >;

            float g_flLayerEmissionStrength < UiType( Slider ); Range( 0, 8 ); Default( 1 ); UiGroup( "Material B,20/Emission,20/71"); >;            
        #endif  

    	Texture2D layerColorMap  < Channel( RGB, Box( LayerColor ), Srgb ); Channel( A, Box( LayerColorTintMask ), Linear ); OutputFormat( BC7 ); SrgbRead( true ); >;
	    Texture2D layerNormalMap < Channel( RGB, Box( LayerNormal ), Linear ); OutputFormat( DXT5 ); SrgbRead( false ); >; 
	    Texture2D g_tRmaLayer    < Channel( R, Box( LayerRoughness ), Linear ); Channel( G, Box( LayerMetalness ), Linear); Channel( B, Box( LayerAmbientOcclusion ), Linear ); OutputFormat( BC7 ); SrgbRead ( false ); >; 

        // Add control sliders same as in Material A, but for Material B.
        float   g_flLayerNormalIntensity < UiType( Slider ); Range( 0, 3 ); Default( 1 ); UiGroup( "Material B,20/Normal Map,20/31" ); >;
        float   LayerTextureScale < UiType( Slider ); Range( 0, 5 ); Default( 1 ); UiGroup( "Material B,20/Layer Settings,20/90" ); >;
        float3  LayerTextureTint < UiType( Color ); Default3( 1, 1, 1 ); UiGroup( "Material B,20/Layer Settings,20/91" ); >;

        // Control strength of texture blending 
        float g_flBlendSmoothness < UiType( Slider ); Range( 0, 1 ); Default( 0.5 ); UiGroup( "Settings,30/Blend Options,30/30") ; >;
        float3 g_vNormalDirections < UiType( Slider ); Range3( -1, -1, -1, 1, 1, 1 ); Default3( 0, 0, 0 ); UiGroup( "Settings,30/Blend Options,31" ); >; 
        
        // Use world-space normals instead of vertex colors
        bool g_bUseWorldSpaceNormals < UiType( CheckBox ); Default( 0 ); UiGroup( "Settings,30/Blend Options,30/32" ); >;
    #endif

    // Emission map implementation, available only inside of a dedicated static combo
    #if ( S_EMISSION )
        CreateInputTexture2D( Emission, Srgb, 8, "", "_em", "Material A,10/Emission,10/70", Default3( 0, 0, 0 ) );
        Texture2D EmissionMap < Channel( RGB, Box( Emission), Srgb ); OutputFormat( BC7 ); SrgbRead( true ); >;

        float g_flEmissionStrength < UiType( Slider ); Range( 0, 8 ); Default( 1 ); UiGroup( "Material A,10/Emission,10/71"); >;
    #endif

    // Opacity implementation
	#if ( S_TRANSPARENCY )
        BoolAttribute( translucent, true );
		RenderState( BlendEnable, true );
        RenderState( AlphaToCoverageEnable, F_ALPHA_TEST );

        // This can be optimized by packing opacity either in RMA texture, or normal map. Both have 4th channel unused at the moment.
		CreateInputTexture2D( Opacity, Linear, 8, "", "_opacity", "Material A,10/Transparency,10/70", Default( 1 ) );
		Texture2D g_tOpacity < Channel( R, Box( Opacity ), Linear ); OutputFormat( BC7 ); SrgbRead( false ); >;
	#endif

	// 
	// Create Texture2D for all basic inputs
	// 
	Texture2D ColorMap  < Channel( RGB, Box( Color ), Srgb ); Channel( A, Box( ColorTintMask ), Linear ); OutputFormat( BC7 ); SrgbRead( true ); >;
	Texture2D NormalMap < Channel( RGB, Box( Normal ), Linear ); Channel( A, Box( HeightMask ), Linear ); OutputFormat( DXT5 ); SrgbRead( false ); >; 
	Texture2D g_tRma    < Channel( R, Box( Roughness), Linear ); Channel( G, Box( Metalness ), Linear); Channel( B, Box( AmbientOcclusion ), Linear ); OutputFormat( BC7 ); SrgbRead ( false ); >; 
	
    // Control the intensity of a normal map 
    float g_flNormalIntensity < UiType( Slider ); Range( 0, 3 ); Default( 1 ); UiGroup("Material A,10/Normal Map,10/31"); >; 

    // Texture scale & offset from the previous unlit shader
    int2    TextureScrollDirection < UiType( Slider ); Range2( -1, -1, 1, 1 ); Default2( 0, 0 ); UiGroup( "Settings,30/Scroll,30/10" ); >;
    float2  TextureScrollSpeed < UiType( Slider ); Range2( 0, 0, 4, 4 ); Default2( 1, 1 ); UiGroup( "Settings,30/Scroll,30/20" ); >;
    float   TextureScale < UiType( Slider ); Range( 0, 5 ); Default( 1 ); UiGroup( "Material A,10/Layer Settings,10/80" ); >;
    float3  TextureTint < UiType( Color ); Default3( 1, 1, 1 ); UiGroup( "Material A,10/Layer Settings,10/40" ); >;

    // Initially this function was part of the s&box code but it was ripped out, so this thing
    // re-implements this function. Thank you Ziks for sharing this. <3 
    float ComputeBlendWeight( float flBlendIntensity, float flBlendSoftness, float flBlendRevealMask )
    {
        float flScaledInput = ( flBlendIntensity * ( 1.0 + ( flBlendSoftness * 2.0 ) ) ) - flBlendSoftness;
        float flMin = flScaledInput - flBlendSoftness;
        float flMax = flScaledInput + flBlendSoftness;

        return 1.0 - saturate( ( flBlendRevealMask - flMin ) / ( flBlendSoftness * 2.0 ) );
    }

    float4 MainPs( PixelInput i ) : SV_Target0
    {
        // Reinstate UV scale & scroll direction + speed feature from unlit shader
        float2 uv = i.vTextureCoords.xy * TextureScale;
        uv += g_flTime * TextureScrollSpeed * TextureScrollDirection;        

        // Sample these packed textures
        float4 albedo = ColorMap.Sample( g_sAniso, uv ).rgba;
        float4 NormalHeight = NormalMap.Sample( g_sAniso, uv ).rgba; 
		float3 normal = DecodeNormal( NormalHeight.rgb ); // Decode RGB of NormalHeight, since this is where normal map is stored
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

        // Static combo S_TRANSPARNECY
        #if ( S_TRANSPARENCY )
            mat.Opacity = g_tOpacity.Sample( g_sAniso, uv ).r; 
        #endif

        // Static combo S_EMISSION: if it's enabled in given shader variant, then sample
        // the emission map and store it into material's Emission slot. 
        #if ( S_EMISSION )
            mat.Emission = EmissionMap.Sample( g_sAniso, uv ).rgb * g_flEmissionStrength;
        #endif

        // 
        // Sample all 2nd layer textures, and create a new Material object.
        // Apply same effects as for the first material textures.
        // 
        #if ( S_BLEND_LAYER )
            // Set up separate UV property for layered texture 
            float2 layer_uv = i.vTextureCoords.xy * LayerTextureScale;

            float4 albedo_l = layerColorMap.Sample( g_sAniso, layer_uv ).rgba;
            float3 normal_l = DecodeNormal( layerNormalMap.Sample( g_sAniso, layer_uv).rgb );
            normal_l.rg *= g_flLayerNormalIntensity;

            float3 rma_l = g_tRmaLayer.Sample( g_sAniso, layer_uv ).rgb;

            Material layer = Material::Init();

            layer.Albedo = lerp( albedo_l.rgb, albedo_l.rgb * LayerTextureTint, albedo_l.a );
            layer.Normal = TransformNormal( normal_l, i.vNormalWs, i.vTangentUWs, i.vTangentVWs );
            layer.Roughness = rma_l.r;
            layer.Metalness = rma_l.g;
            layer.AmbientOcclusion = rma_l.b;
            layer.TintMask = albedo_l.a;

            // Handle emission mode
            #if ( S_EMISSION )
                layer.Emission = layerEmissionMap.Sample( g_sAniso, layer_uv ).rgb;
            #endif

            // Tip: you can add opacity here too! 

            // Final step: when both materials are set up, we can use Material class' special function "lerp"
            // to quickly lerp two textures together.
            mat = Material::lerp( mat, layer, ComputeBlendWeight( g_bUseWorldSpaceNormals ? dot( NormalTransformed, g_vNormalDirections ) : i.vVertexColor.r, g_flBlendSmoothness, NormalHeight.a ) );
        #endif

        // This method returns final, shaded pixel with a type of 'float4'.
        return ShadingModelStandard::Shade( i, mat );
    }
}