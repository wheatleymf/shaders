public sealed class DitherEffect : PostProcess, Component.ExecuteInEditor
{
	[Property] 
	[Description( "Affects quantization of color buffer pallete." )] 
	[Range( 4, 64, 4 )]
	private int ColorLevels = 16;

	[Property]
	[Description( "Resolution of the dithering effect, where 1x is full-scale, 2x is half-res, etc..." )]
	[Range( 1, 4 )]
	private int Resolution = 2;
	
	private IDisposable hook;
	private RenderAttributes attributes = new();

	public void Render( SceneCamera camera )
	{
		var material = Material.FromShader( "shaders/saunaDither.shader" );

		attributes.Set("ColorLevels", ColorLevels );
		attributes.Set( "DitherRes", Resolution );
		Graphics.GrabFrameTexture( "Color", attributes );
		Graphics.Blit( material, attributes );
	}

	protected override void OnEnabled()
	{
		hook?.Dispose();
		hook = Camera.AddHookAfterTransparent( "Dithering", -1, Render );
	}

	protected override void OnDisabled()
	{
		hook?.Dispose();
		hook = null;
	}
}
