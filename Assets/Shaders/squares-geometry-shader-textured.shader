Shader "Custom/squares-geometry-shader-textured" {
	Properties {
		_MainTex("Texture", 2D) = "white" {}
		ParticleSize("ParticleSize",Range(0.001,1)) = 0.1
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
				float3 Normal : NORMAL;
				float2 uv : TEXCOORD0;
		};

			struct vert2geo {
				float4 WorldPos : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct FragData {
				float4 ScreenPos : SV_POSITION;
				float2 uv : TEXCOORD0;
			};


			sampler2D _MainTex;
			float4 _MainTex_ST;
			float ParticleSize;

			float3 GetParticleSize3() {
				return float3(ParticleSize, ParticleSize, ParticleSize);
			}


			FragData MakeFragData(float3 offset, float3 input_WorldPos, float2 uv, float3 ParticleSize3) {
				FragData x = (FragData)0;

				float3 x_WorldPos = mul(UNITY_MATRIX_V, float4(input_WorldPos,1)) + (offset * ParticleSize3);
				x.ScreenPos = mul(UNITY_MATRIX_P, float4(x_WorldPos,1));
				x.uv = uv;
				return x;
			}

#ifdef GEOMETRY_TRIANGULATION
			vert2geo vert(app2vert v) {
				vert2geo o;

				float4 LocalPos = v.LocalPos;
				o.WorldPos = mul(unity_ObjectToWorld, LocalPos);
				o.uv = v.uv;

				return o;
			}
#endif

#ifdef VERTEX_TRIANGULATION
			FragData vert(app2vert v) {
				float4 LocalPos = v.LocalPos;
				float3 WorldPos = mul(unity_ObjectToWorld, LocalPos);

				float3 ParticleSize3 = GetParticleSize3();

				FragData o;
				o = MakeFragData(v.Normal, WorldPos, v.uv, ParticleSize3);

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

				// Add four vertices to the output stream that will be drawn as a triangle strip making a quad
				FragData vertex = MakeFragData(float3(-size,-size,0), input.WorldPos, input.uv, ParticleSize3);
				OutputStream.Append(vertex);

				vertex = MakeFragData(float3(size,-size,0), input.WorldPos, input.uv, ParticleSize3);
				OutputStream.Append(vertex);

				vertex = MakeFragData(float3(-size,size,0), input.WorldPos, input.uv, ParticleSize3);
				OutputStream.Append(vertex);

				vertex = MakeFragData(float3(size, size, 0), input.WorldPos, input.uv, ParticleSize3);
				OutputStream.Append(vertex);

			}
#endif//GEOMETRY_TRIANGULATION

			fixed4 frag(FragData i) : SV_Target	{
				// sample the texture
				return tex2D(_MainTex, i.uv);
			}
			ENDCG
		}
	}
}