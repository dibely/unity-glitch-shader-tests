Shader "Custom/tris-geometry-shader" {
	// Geometry shader sample from Graham
	// https://github.com/NewChromantics/PopParticleCloud/blob/master/Assets/PopParticleCloud/PopParticleCloudMesh.shader

	Properties {
		_MainTex("Texture", 2D) = "white" {}
		ParticleSize("ParticleSize",Range(0.001,1)) = 0.1
		Radius("Radius", Range(0,1)) = 0.5
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
			float Radius;
			float UseVertexColour;

			float3 GetParticleSize3() {
				//	gr: thought it length of each row was scale but... doesn't seem to be. row vs col major issue?
				//float WorldScale = length(unity_ObjectToWorld[0]) + length(unity_ObjectToWorld[1]) + length(unity_ObjectToWorld[2]);
				//WorldScale /= 3.0;

				float3 OneTrans = mul(unity_ObjectToWorld, float4(1,0,0,0));
				float3 ZeroTrans = mul(unity_ObjectToWorld, float4(0,0,0,0));
				float WorldScale = length(OneTrans - ZeroTrans);
				float3 ParticleSize3 = float3(ParticleSize * WorldScale, ParticleSize * WorldScale, ParticleSize * WorldScale);
				return ParticleSize3;
			}


			FragData MakeFragData(float3 TriangleIndexer,float3 input_WorldPos,float3 input_Rgba,float3 ParticleSize3) {
				float isa = TriangleIndexer.x;
				float isb = TriangleIndexer.y;
				float isc = TriangleIndexer.z;

				FragData x = (FragData)0;

				//	gr: use maths to work out biggest circle 
				float Top = -0.6;
				float Bottom = 0.3;
				float Width = 0.5;
				x.LocalOffset = isa * float3(0,Top,0);
				x.LocalOffset += isb * float3(-Width,Bottom,0);
				x.LocalOffset += isc * float3(Width,Bottom,0);

				float3 x_WorldPos = mul(UNITY_MATRIX_V, float4(input_WorldPos,1)) + (x.LocalOffset * ParticleSize3);
				x.ScreenPos = mul(UNITY_MATRIX_P, float4(x_WorldPos,1));
				x.Colour = TriangleIndexer;
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
				o = MakeFragData(v.Normal, WorldPos, v.Rgba.xyz, ParticleSize3);

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

				{
					vert2geo input = _input[v];

					FragData a = MakeFragData(float3(1,0,0), input.WorldPos, input.Rgba, ParticleSize3);
					FragData b = MakeFragData(float3(0,1,0), input.WorldPos, input.Rgba, ParticleSize3);
					FragData c = MakeFragData(float3(0,0,1), input.WorldPos, input.Rgba, ParticleSize3);

					OutputStream.Append(a);
					OutputStream.Append(b);
					OutputStream.Append(c);
				}
			}
#endif//GEOMETRY_TRIANGULATION

			fixed4 frag(FragData i) : SV_Target	{
				float DistanceFromCenterSq = lengthsq(i.LocalOffset);

				if (DistanceFromCenterSq > squared(Radius))
					discard;

				return float4(i.Colour, 1);
			}
			ENDCG
		}
	}
}