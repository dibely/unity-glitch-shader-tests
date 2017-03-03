Shader "Custom/slice-square" {
	// Simple slicing example taken from https://docs.unity3d.com/Manual/SL-SurfaceShaderExamples.html
	Properties{
		_MainTex("Texture", 2D) = "white" {}
		_BumpMap("Bumpmap", 2D) = "bump" {}
	}
		SubShader{
		Tags{ "RenderType" = "Opaque" }
		Cull Off
		CGPROGRAM
#pragma surface surf Lambert
		struct Input {
		float2 uv_MainTex;
		float2 uv_BumpMap;
		float3 worldPos;
	};
	sampler2D _MainTex;
	sampler2D _BumpMap;
	void surf(Input IN, inout SurfaceOutput o) {
		// Clip the horizontal and vertical to create square cutouts
		clip(frac((IN.worldPos.y + IN.worldPos.z*0.1) * 10) - 0.7);
		clip(frac((IN.worldPos.x + IN.worldPos.z*0.1) * 10) - 0.7);
		o.Albedo = tex2D(_MainTex, IN.uv_MainTex).rgb;
		o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
	}
	ENDCG
	}
	Fallback "Diffuse"
}
