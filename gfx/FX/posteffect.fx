
#include "standardfuncs.fxh"

texture tex0;
texture tex1;

sampler2D Specular = 
sampler_state 
{
    texture = <tex0>;
    AddressU = CLAMP;
    AddressV = CLAMP;
    MIPFILTER = LINEAR;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
};

sampler2D MainScene = 
sampler_state 
{
    texture = <tex0>;
    AddressU = CLAMP;
    AddressV = CLAMP;
    MIPFILTER = NONE;
    MINFILTER = POINT;
    MAGFILTER = POINT;
};

sampler2D RestoreBloom = 
sampler_state 
{
    texture = <tex1>;
    AddressU = CLAMP;
    AddressV = CLAMP;
    MIPFILTER = LINEAR;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
};



struct VS_INPUT
{
    float2 position			: POSITION;
};

float3 vHalfPixelOffset_Axis;
float2 vHalfPixelOffsetBloom;

// Downsample //////////////////////////////////////////////////////////////////////

struct VS_OUTPUT_DOWNSAMPLE
{
    float4 position			: POSITION;
	float2 uv				: TEXCOORD0;
};


VS_OUTPUT_DOWNSAMPLE VertexShader_Downsample( const VS_INPUT VertexIn )
{
	VS_OUTPUT_DOWNSAMPLE VertexOut = (VS_OUTPUT_DOWNSAMPLE)0;
	VertexOut.position = float4( VertexIn.position, 0.0f, 1.0f );
	VertexOut.uv = ( VertexIn.position + 1.0f ) * 0.5f;
	VertexOut.uv.y = 1.0f - VertexOut.uv.y;
	VertexOut.uv += vHalfPixelOffsetBloom;
	return VertexOut;
}

float4 PixelShader_Downsample( VS_OUTPUT_DOWNSAMPLE Input ) : COLOR
{
	float vRestoreSpec = 1.0f / ( 1.0f - HDR_RANGE );
	float color = dot( saturate( tex2D( MainScene, Input.uv ).rgb - HDR_RANGE ) * vRestoreSpec, (1.0f).xxx );
	return color.xxxx;
}

technique Downsample
{
	pass p0
	{
		AlphaBlendEnable = False;
		AlphaTestEnable = False;
		ColorWriteEnable = RED;

		VertexShader = compile vs_3_0 VertexShader_Downsample();
		PixelShader = compile ps_3_0 PixelShader_Downsample();
	}
}



// Bloom //////////////////////////////////////////////////////////////////////

uniform float vSamples = 3.0f;
uniform float4 vWeights = { 55.0f, 12.0f, 1.0f, 90.0f };

struct VS_OUTPUT_BLOOM
{
    float4 position			: POSITION;
	float2 uv				: TEXCOORD0;
	float2 uvBloom			: TEXCOORD1;
	float4 uvBloom2[3]		: TEXCOORD2;
};

VS_OUTPUT_BLOOM VertexShader_Bloom( const VS_INPUT VertexIn )
{
	VS_OUTPUT_BLOOM VertexOut = (VS_OUTPUT_BLOOM)0;
	VertexOut.position = float4( VertexIn.position, 0.0f, 1.0f );
	VertexOut.uv = ( VertexIn.position + 1.0f ) * 0.5f;
	VertexOut.uv.y = 1.0f - VertexOut.uv.y;
	VertexOut.uvBloom = VertexOut.uv;
	VertexOut.uv += vHalfPixelOffset_Axis.xy;
	VertexOut.uvBloom += vHalfPixelOffsetBloom;

	float vAxis = vHalfPixelOffset_Axis.z;

	float2 vAxisOffset = float2( vHalfPixelOffset_Axis.x * vAxis, vHalfPixelOffset_Axis.y * ( 1.0f - vAxis ) );

	for ( int i = 0; i < vSamples; ++i )
	{
		float vStepFactor = 2.0f;
		VertexOut.uvBloom2[i] = float4( 
			VertexOut.uvBloom + (i+1) * vAxisOffset * vStepFactor, 
			VertexOut.uvBloom - (i+1) * vAxisOffset * vStepFactor );
	}

	return VertexOut;
}

float SampleBloom( in sampler2D InSampler, in VS_OUTPUT_BLOOM Input )
{
	float color = tex2D( InSampler, Input.uvBloom ).r * vWeights[3];

	for ( int i = 0; i < vSamples; ++i )
	{
		color += vWeights[i] 
			* ( tex2D( InSampler, Input.uvBloom2[i].xy ).r
				+ tex2D( InSampler, Input.uvBloom2[i].zw ).r );
	}

	color /= dot( vWeights, ( 1.0f ).xxxx );
	return color;
}



float4 PixelShader_Bloom( VS_OUTPUT_BLOOM Input ) : COLOR
{
	return float4( SampleBloom( Specular, Input ).rrr, 1.0f );
}

technique Bloom
{
	pass p0
	{
		AlphaBlendEnable = False;
		AlphaTestEnable = False;
		ColorWriteEnable = RED;

		VertexShader = compile vs_3_0 VertexShader_Bloom();
		PixelShader = compile ps_3_0 PixelShader_Bloom();
	}
}

// RestoreScene //////////////////////////////////////////////////////////////////////

uniform float3 HSVTweak = float3( 0.0f, 0.80f, 1.0f );
uniform float3 ColorBalance = float3( 1.1f, 1.0f, 1.0f );
uniform float2 LevelValue = float2( 0.035f, 0.85f );

float4 PixelShader_RestoreScene( VS_OUTPUT_BLOOM Input ) : COLOR
{
	float3 color = saturate( tex2D( MainScene, Input.uv ).rgb * ( 1.0f / HDR_RANGE ) );

	float3 HSV = RGBtoHSV( color.rgb );
	HSV.yz *= HSVTweak.yz;
	HSV.x += HSVTweak.x;
	HSV.x %= 6;
	color = HSVtoRGB( HSV );

	color = saturate( color * ColorBalance );

	color = Levels( color, LevelValue.x, LevelValue.y );

	return float4( color, 1.0f );
}

float4 PixelShader_RestoreSceneBloom( VS_OUTPUT_BLOOM Input ) : COLOR
{
	float4 vColor = PixelShader_RestoreScene( Input );
	float bloom = SampleBloom( RestoreBloom, Input );
	return float4( vColor + bloom.rrr * vDiffuseLight * 0.3f, 1.0f );
}


technique RestoreScene
{
	pass p0
	{
		AlphaBlendEnable = False;
		AlphaTestEnable = False;
		ColorWriteEnable = RED|GREEN|BLUE;
		ZWriteEnable = False;
		ZEnable = False;

		VertexShader = compile vs_3_0 VertexShader_Bloom();
		PixelShader = compile ps_3_0 PixelShader_RestoreScene();
	}
}

technique RestoreSceneBloom
{
	pass p0
	{
		AlphaBlendEnable = False;
		AlphaTestEnable = False;
		ColorWriteEnable = RED|GREEN|BLUE;
		ZWriteEnable = False;
		ZEnable = False;

		VertexShader = compile vs_3_0 VertexShader_Bloom();
		PixelShader = compile ps_3_0 PixelShader_RestoreSceneBloom();
	}
}

