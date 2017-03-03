Shader "Custom/glitch" {
	Properties {
		PrimaryColour("Primary Colour", Color) = (1,0,0,1)
		SecondaryColour("Secondary Colour", Color) = (0,0,1,1)

		MinWidth("Min Width",Range(0.001,0.05)) = 0.001
		MaxWidth("Max Width",Range(0.051,0.2)) = 0.2
		MinHeight("Min Height",Range(0.001,0.05)) = 0.001
		MaxHeight("Max Height",Range(0.051,0.2)) = 0.2
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
			};

			struct vert2geo {
				float4 WorldPos : POSITION;
			};

			struct FragData {
				float4 ScreenPos : SV_POSITION;
				float4 Colour : COLOR;
			};


			float MinWidth;
			float MaxWidth;
			float MinHeight;
			float MaxHeight;
			float4 PrimaryColour;
			float4 SecondaryColour;

			float rand3(float3 co) {
				return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 45.5432))) * 43758.5453);
			}

			float rand1(float n) {
				return frac(sin(n)*43758.5453);
			}

			FragData MakeFragData(float3 offset, float3 input_WorldPos) {
				FragData x = (FragData)0;

				float3 x_WorldPos = mul(UNITY_MATRIX_V, float4(input_WorldPos,1)) + offset;
				x.ScreenPos = mul(UNITY_MATRIX_P, float4(x_WorldPos,1));
				x.Colour = lerp(PrimaryColour, SecondaryColour, rand3(input_WorldPos));
				return x;
			}

#ifdef GEOMETRY_TRIANGULATION
			vert2geo vert(app2vert v) {
				vert2geo o;

				float4 LocalPos = v.LocalPos;
				o.WorldPos = mul(unity_ObjectToWorld, LocalPos);
				return o;
			}
#endif

#ifdef VERTEX_TRIANGULATION
			FragData vert(app2vert v) {
				float4 LocalPos = v.LocalPos;
				float3 WorldPos = mul(unity_ObjectToWorld, LocalPos);

				FragData o;
				o = MakeFragData(v.Normal, WorldPos);

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
				vert2geo input = _input[v];

				float xoffset = MinWidth + (rand1(sin(input.WorldPos.x))*(MaxWidth - MinWidth));
				float yoffset = MinHeight + (rand1(cos(input.WorldPos.y))*(MaxHeight - MinHeight));
				//float xoffset = 0.0001 + rand1(sin(input.WorldPos.x))*MaxWidth;
				//float yoffset = 0.0001 + rand1(cos(input.WorldPos.y))*MaxHeight;

				// Add four vertices to the output stream that will be drawn as a triangle strip making a quad
				FragData vertex = MakeFragData(float3(-xoffset, -yoffset, 0), input.WorldPos);
				OutputStream.Append(vertex);

				vertex = MakeFragData(float3(xoffset, -yoffset, 0), input.WorldPos);
				OutputStream.Append(vertex);

				vertex = MakeFragData(float3(-xoffset, yoffset, 0), input.WorldPos);
				OutputStream.Append(vertex);

				vertex = MakeFragData(float3(xoffset, yoffset, 0), input.WorldPos);
				OutputStream.Append(vertex);
			}
#endif//GEOMETRY_TRIANGULATION

			fixed4 frag(FragData i) : SV_Target	{
				return i.Colour;
			}
			ENDCG
		}
	}
}