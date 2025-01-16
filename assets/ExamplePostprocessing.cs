namespace Sandbox;

[Title( "My Post Processing" )]
[Category( "Post Processing" )]
[Icon( "grain" )]
public sealed class MyPostProcessing : PostProcess, Component.ExecuteInEditor
{
	[Property] [Range( 0, 3 )] public float Brightness { get; set; } = 1.0f;

	private IDisposable _renderHook;

	protected override void OnEnabled()
	{
		_renderHook = Camera.AddHookBeforeOverlay( "My Post Processing", 1000, RenderEffect );
	}

	protected override void OnDisabled()
	{
		_renderHook?.Dispose();
		_renderHook = null;
	}

	RenderAttributes attributes = new RenderAttributes();

	public void RenderEffect( SceneCamera camera )
	{
		if ( !camera.EnablePostProcessing )
			return;

		attributes.Set( "ScreenBrightness", Brightness );
		Graphics.GrabFrameTexture( "ColorBuffer", attributes );
		Graphics.Blit( Material.FromShader( "shaders/postprocessing/post_example.shader" ), attributes );
	}
}
