MODES
{
    Forward();
}

struct VertexInput
{
    float3 vPositionOs : POSITION;
    float2 vTexCoord : TEXCOORD0;
};

struct PixelInput
{
    float2 vTexCoord : TEXCOORD0;

	#if ( PROGRAM == VFX_PROGRAM_VS )
		float4 vPositionPs : SV_Position;
	#endif

	#if ( ( PROGRAM == VFX_PROGRAM_PS ) )
		float4 vPositionSs : SV_Position;
	#endif
};

VS
{
    PixelInput MainVs( VertexInput i )
    {
        PixelInput o;
        
        o.vPositionPs = float4( i.vPositionOs.xy, 0.0f, 1.0f );
        o.vTexCoord = i.vTexCoord;
        return o;
    }
}

PS
{
    //RenderState( DepthWriteEnable, false );
    //RenderState( DepthEnable, false );

    SamplerState s < Filter( Linear ); >;
    Texture2D g_tColorBuffer < Attribute( "ColorBuffer" ); SrgbRead( true ); >;

    float g_flScreenBrightness < Attribute( "ScreenBrightness" ); Default( 1 ); >;

    float4 MainPs( PixelInput i ) : SV_Target0
    {
        float3 buffer = g_tColorBuffer.Sample( s, i.vTexCoord ).rgb;

        return float4( buffer * g_flScreenBrightness, 1 );
    }
}