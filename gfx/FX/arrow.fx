
#include "standardfuncs.fxh"

texture tex0;

sampler2D DiffuseTexture = 
sampler_state 
{
    texture = <tex0>;
    AddressU = CLAMP;
    AddressV = CLAMP;
    MIPFILTER = LINEAR;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
};

struct VS_INPUT
{
    float3 vPosition  : POSITION;
	float2 vTexCoord  : TEXCOORD0;
};

struct VS_OUTPUT
{
    float4 vPosition : POSITION;
    float2 vTexCoord : TEXCOORD0;
	float3 vPos		 : TEXCOORD1;
};


float vIsArmy;

VS_OUTPUT VertexShader_Arrow( const VS_INPUT v )
{
	VS_OUTPUT Out = (VS_OUTPUT)0;

	float4 pos = float4( v.vPosition, 1.0f );
	pos.y += 2.0f * vIsArmy + 0.5 * ( 1.0f - vIsArmy );

	Out.vPos = pos.xyz;
   	Out.vPosition  = mul( pos, ViewProjectionMatrix );	
	Out.vTexCoord = v.vTexCoord;

	return Out;
}

float2 vProgress_Move;

float4 PixelShader_Arrow( VS_OUTPUT v ) : COLOR
{
	clip( vProgress_Move.x - v.vTexCoord.y );

	float vPassed = v.vTexCoord.y < vProgress_Move.y ? 1.0f : 0.0f;

	float vArrowPart = 15.0f;
	
	float vArrowDiff = v.vTexCoord.y - ( vProgress_Move.x - vArrowPart );
	float vArrow = saturate( vArrowDiff * 10000.0f );

	float BODY = 0.125f;
	float ARROW = 1.0f - BODY;

	float vBodyV = frac( v.vTexCoord.y * 0.8f ) * BODY;
	float vArrowV = BODY + ( vArrowDiff / vArrowPart ) * ARROW;

	float2 vUV = float2( 0.5f * vPassed + v.vTexCoord.x * 0.5f, vBodyV * ( 1.0f - vArrow ) + vArrow * vArrowV );

	float4 OutColor = tex2D( DiffuseTexture, vUV.yx );

	return float4( ComposeSpecular( OutColor.rgb, 0.0f ), OutColor.a );
}


technique tec0
{
	pass p0
	{
		AlphaBlendEnable = True;
		AlphaTestEnable = False;
		ZWriteEnable = False;
		ZEnable = True;
		ColorWriteEnable = RED|GREEN|BLUE;
		CullMode = CW;

		VertexShader = compile vs_2_0 VertexShader_Arrow();
		PixelShader = compile ps_2_0 PixelShader_Arrow();
	}
}
