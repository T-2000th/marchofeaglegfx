
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
};


VS_OUTPUT VertexShader_Text( const VS_INPUT v )
{
	VS_OUTPUT Out = (VS_OUTPUT)0;

	float4 vPos = float4( v.vPosition, 1.0f );
	float4 vDistortedPos = vPos - float4( vCamLookAtDir * 0.5f, 0.0f );

	vPos = mul( vPos, ViewProjectionMatrix );
	
	// move z value slightly closer to camera to avoid intersections with terrain
	float vNewZ = dot( vDistortedPos, ViewProjectionMatrix._m02_m12_m22_m32 );
	
	Out.vPosition = float4( vPos.xy, vNewZ, vPos.w );
	Out.vTexCoord = v.vTexCoord;

	return Out;
}

float vFade;
float vTargetOpacity;

float4 PixelShader_Text( VS_OUTPUT v ) : COLOR
{
	float4 vSample = tex2D( DiffuseTexture, v.vTexCoord );
	vSample.a *= vFade * vTargetOpacity * 0.7f;
	return vSample;
}


technique mapname
{
	pass p0
	{
		AlphaBlendEnable = True;
		AlphaTestEnable = False;
		ZWriteEnable = False;
		ZEnable = True;
		ColorWriteEnable = RED|GREEN|BLUE;
		CullMode = CW;

		VertexShader = compile vs_2_0 VertexShader_Text();
		PixelShader = compile ps_2_0 PixelShader_Text();
	}
}
