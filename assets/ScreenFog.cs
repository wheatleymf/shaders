public sealed class ScreenFog : PostProcess, Component.ExecuteInEditor
{
	/// <summary>
	/// The distance this fog reaches.
	/// </summary>
	[Property]
	[Description( "Specifies the distance where fog gets fully visible, in world units" )]
	public float EndDistance { get; set; } = 1250.0f;

	[Property]
	[Range( 0, 1 )]
	[Description( "Defines the length between start and end of the fog gradient" )]
	public float FogDensity { get; set; } = 0.5f;
	
	[Property]
	public Color Color { get; set; }

	private IDisposable hook;
	private RenderAttributes attributes = new();

	public void Render( SceneCamera camera )
	{
		var material = Material.FromShader( "shaders/fog.shader" );
		
		attributes.Set( "FogEndDistance", EndDistance );
		attributes.Set("Color", Color );
		attributes.Set( "FogDensity", FogDensity);

		Graphics.GrabFrameTexture( "ColorBuffer", attributes );

		Graphics.Blit( material, attributes );
	}

	protected override void OnEnabled()
	{
		hook?.Dispose();
		hook = Camera.AddHookAfterTransparent( "RenderFog", -1, Render );
	}

	protected override void OnDisabled()
	{
		hook?.Dispose();
		hook = null;
	}
}
