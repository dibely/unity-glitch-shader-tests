Shader "Custom/squares-geometry-shader" {
	Properties {
		_MainTex("Texture", 2D) = "white" {}
		ParticleSize("ParticleSize",Range(0.001,1)) = 0.1
		UseVertexColour("UseVertexColour", Range(0,1)) = 0.0
	}
	
	SubShader {
		Tags{ "RenderType" = "Opaque" }
		LOD 100
		Cull off
		Blend off

		Pass {
			CGPROGRAM

			//	geometry shader needs GL ES 3+
			//	https://docs.unity3d.com/Manual/SL-ShaderCompileTargets.html
#pragma target 3.5

#pragma shader_feature POINT_TOPOLOGY
#define GEOMETRY_TRIANGULATION

#ifndef GEOMETRY_TRIANGULATION
#define VERTEX_TRIANGULATION
#endif

#pragma vertex vert
#pragma fragment frag

#ifdef GEOMETRY_TRIANGULATION
#pragma geometry geom
#endif

#include "UnityCG.cginc"

#define lengthsq(x)	dot( (x), (x) )
#define squared(x)	( (x)*(x) )

			struct app2vert {
				float4 LocalPos : POSITION;
				float2 uv : TEXCOORD0;
				float4 Rgba : COLOR;
				float3 Normal : NORMAL;
			};

			struct vert2geo {
				float4 WorldPos : TEXCOORD1;
				float2 uv : TEXCOORD0;
				float4 Rgba : COLOR;
			};

			struct FragData {
				float3 LocalOffset : TEXCOORD1;
				float4 ScreenPos : SV_POSITION;
				float3 Colour : TEXCOORD4;
			};


			sampler2D _MainTex;
			float4 _MainTex_ST;
			float ParticleSize;
			float UseVertexColour;

			float3 GetParticleSize3() {
				return float3(ParticleSize, ParticleSize, ParticleSize);
			}


			FragData MakeFragData(float3 offset, float3 colour, float3 input_WorldPos, float3 input_Rgba, float3 ParticleSize3) {
				FragData x = (FragData)0;
				x.LocalOffset = offset;

				float3 x_WorldPos = mul(UNITY_MATRIX_V, float4(input_WorldPos,1)) + (x.LocalOffset * ParticleSize3);
				x.ScreenPos = mul(UNITY_MATRIX_P, float4(x_WorldPos,1));
				x.Colour = colour;
				x.Colour = lerp(x.Colour, input_Rgba, UseVertexColour);
				return x;
			}

#ifdef GEOMETRY_TRIANGULATION
			vert2geo vert(app2vert v) {
				vert2geo o;

				float4 LocalPos = v.LocalPos;
				o.WorldPos = mul(unity_ObjectToWorld, LocalPos);
				o.uv = v.uv;
				o.Rgba = v.Rgba;

				return o;
			}
#endif

#ifdef VERTEX_TRIANGULATION
			FragData vert(app2vert v) {
				float4 LocalPos = v.LocalPos;
				float3 WorldPos = mul(unity_ObjectToWorld, LocalPos);

				float3 ParticleSize3 = GetParticleSize3();

				FragData o;
				o = MakeFragData(v.Normal, float3(1,0,0), WorldPos, v.Rgba.xyz, ParticleSize3);

				return o;
			}
#endif

#ifdef GEOMETRY_TRIANGULATION
#if POINT_TOPOLOGY
			[maxvertexcount(9)]
			void geom(point vert2geo _input[1], inout TriangleStream<FragData> OutputStream) {
				int v = 0;
#else
			[maxvertexcount(9)]
			void geom(triangle vert2geo _input[3], inout TriangleStream<FragData> OutputStream) {
				//	non-shared vertex in triangles is 2nd
				int v = 1;
#endif
				//	get particle size in worldspace
				float3 ParticleSize3 = GetParticleSize3();

				vert2geo input = _input[v];

				float size = 0.2;

				FragData a = MakeFragData(float3(size,size,0), float3(1,0,0), input.WorldPos, input.Rgba, ParticleSize3);
				FragData b = MakeFragData(float3(-size,-size,0), float3(1, 0, 0), input.WorldPos, input.Rgba, ParticleSize3);
				FragData c = MakeFragData(float3(size,-size,0), float3(1, 0, 0), input.WorldPos, input.Rgba, ParticleSize3);

				FragData d = MakeFragData(float3(-size, size, 0), float3(0, 1, 0), input.WorldPos, input.Rgba, ParticleSize3);
				FragData e = MakeFragData(float3(size, size, 0), float3(0, 1, 0), input.WorldPos, input.Rgba, ParticleSize3);
				FragData f = MakeFragData(float3(size, -size, 0), float3(0, 1, 0), input.WorldPos, input.Rgba, ParticleSize3);

				OutputStream.Append(a);
				OutputStream.Append(b);
				OutputStream.Append(c);
				OutputStream.Append(d);
				OutputStream.Append(e);
				OutputStream.Append(f);
			}
#endif//GEOMETRY_TRIANGULATION

			fixed4 frag(FragData i) : SV_Target	{
				return float4(i.Colour, 1);
			}
			ENDCG
		}
	}
}