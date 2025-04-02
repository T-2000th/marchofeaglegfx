
#include "standardfuncs.fxh"

texture tex0;
texture tex1;
texture tex2;
texture tex3;
texture tex4;
texture tex5;

sampler2D DiffuseMap = 
sampler_state 
{
    texture = <tex0>;
    AddressU  = Wrap;        
    AddressV  = Wrap;
    MipFilter = Linear;
    MagFilter = Linear;
	MinFilter = Linear;
};

sampler2D NormalMap = 
sampler_state 
{
    texture = <tex1>;
    AddressU  = Wrap;        
    AddressV  = Wrap;
    MipFilter = Linear;
    MinFilter = Linear;
    MagFilter = Linear;
};

sampler2D TintMap = 
sampler_state 
{
    texture = <tex2>;
    AddressU  = Wrap;        
    AddressV  = Wrap;
    MipFilter = Linear;
    MagFilter = Linear;
	MinFilter = Linear;
};

sampler2D ColorMap = 
sampler_state 
{
    texture = <tex3>;
    AddressU  = Wrap;        
    AddressV  = Wrap;
    MipFilter = Linear;
    MagFilter = Linear;
	MinFilter = Linear;
};

sampler2D FoWTexture = 
sampler_state 
{
    texture = <tex4>;
    AddressU = WRAP;
    AddressV = WRAP;
    MIPFILTER = LINEAR;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
};

sampler2D FoWDiffuse = 
sampler_state 
{
    texture = <tex5>;
    AddressU = WRAP;
    AddressV = WRAP;
    MIPFILTER = LINEAR;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
};

struct VS_INPUT_INSTANCE
{
    float4 vPosition   : POSITION;
    float3 vNormal     : NORMAL;
	float4 vTangent    : TANGENT;
	float2 vTexCoord0  : TEXCOORD0;
	float2 vTexCoord1  : TEXCOORD1;
	float4 vPos_YRot   : TEXCOORD2;
	float2 vSlopes     : TEXCOORD3;
};

struct VS_OUTPUT
{
    float4 vPosition		  : POSITION;
	float4 vTexCoord0_TintUV  : TEXCOORD0;
	float3 vNormal          	: TEXCOORD1;
	float3 vPos				  : TEXCOORD2;
	float3 vTangent          	: TEXCOORD3;
	float3 vBitangent          	: TEXCOORD4;
};

VS_OUTPUT StaticTreeVS( const VS_INPUT_INSTANCE v )
{
	VS_OUTPUT Out = (VS_OUTPUT)0;

	float vRandom = v.vPos_YRot.w / 6.28318531f;
	float vSummedRandom = v.vTexCoord1.x + vRandom;
	vSummedRandom = vSummedRandom >= 1.0f ? vSummedRandom - 1.0f : vSummedRandom;
	
	float vHeightScaleFactor = 0.75f + vSummedRandom * 0.5f;
	Out.vPosition = float4( v.vPosition.xyz, 1.0 );
	Out.vPosition.y *= vHeightScaleFactor;

	float randSin = sin( v.vPos_YRot.w );
	float randCos = cos( v.vPos_YRot.w );

	Out.vPosition.xz = float2( 
		Out.vPosition.x * randCos - Out.vPosition.z * randSin, 
		Out.vPosition.x * randSin + Out.vPosition.z * randCos );

	Out.vPosition.y += Out.vPosition.x * v.vSlopes.x + Out.vPosition.z * v.vSlopes.y;
	Out.vPosition.xyz += v.vPos_YRot.xyz;
	
	Out.vPos = Out.vPosition.xyz;

	Out.vPosition = mul( Out.vPosition, ViewProjectionMatrix );
	
	Out.vTexCoord0_TintUV.xy = v.vTexCoord0;

	float3 vNormal = v.vNormal;
	vNormal.xz = float2( 
		vNormal.x * randCos - vNormal.z * randSin, 
		vNormal.x * randSin + vNormal.z * randCos );
	
	float3 vTangent = v.vTangent.xyz;
	vTangent.xz = float2( 
		vTangent.x * randCos - vTangent.z * randSin, 
		vTangent.x * randSin + vTangent.z * randCos );

	float3 vBitangent = cross( vTangent, vNormal ) * v.vTangent.w;
	
	Out.vNormal = vNormal;
	Out.vTangent = vTangent;
	Out.vBitangent = vBitangent;
	
//	float3x3 matTBN = float3x3( vTangent, vBitangent, vNormal );
//	Out.vLightDir = mul( matTBN, vLightDir );

	Out.vTexCoord0_TintUV.zw = float2( vRandom, 0.0f ) + v.vTexCoord1;
	return Out;
}

float3 ApplySnowTree( float3 vColor, float3 vPos, inout float3 vNormal, float4 vFoWColor, in sampler2D FoWDiffuse )
{
	float vNoise = tex2D( FoWDiffuse, ( vPos.xz + 0.5f ) / 100.0f  ).r;

	float vIsSnow = GetSnow( vFoWColor );
	
	float vNormalFade = saturate( saturate( vNormal.y-((1.0f-vIsSnow)*(1.0f-vNoise)*3.f) ) * 10.0f );
	
	vColor = lerp( vColor, SNOW_COLOR, vNormalFade * ( saturate( vIsSnow*2.5f ) ) );	
	
	vNormal.y += 1.0f * vNormalFade;
	vNormal = normalize( vNormal );
	
	return vColor;
}

float4 StaticTreePS( VS_OUTPUT In ) : COLOR
{
	float3 vColor = GetOverlay( tex2D( DiffuseMap, In.vTexCoord0_TintUV.xy ).rgb, tex2D( TintMap, In.vTexCoord0_TintUV.zw ).rgb, 0.5f );
	
	float3 vNormalSample = normalize( tex2D( NormalMap, In.vTexCoord0_TintUV.xy  ).rgb - 0.5f );
	float3x3 TBN = float3x3( normalize( In.vTangent ), normalize( In.vBitangent ), normalize( In.vNormal ) );
	float3 vNormal = mul( vNormalSample, TBN );	

	float2 uv = ( In.vPos.xz + 0.5f - float2( 0.0f, 2048.0f ) ) / float2( 2048.0f, -2048.0f );
	vColor = GetOverlay( vColor, tex2D( ColorMap, uv ).rgb, 0.25f );

	float4 vFoWColor = GetFoWColor( In.vPos, FoWTexture);	
	vColor = ApplySnowTree( vColor, In.vPos, vNormal, vFoWColor, FoWDiffuse );	
	
	vColor = CalculateLighting( vColor, normalize( vNormal ) );
	
	vColor = ApplyDistanceFog( vColor, In.vPos, vFoWColor.r, FoWDiffuse );
	return float4( ComposeSpecular( vColor, 0.0f ), 1.0f );
}

technique Tree
{
	pass p0
	{
		MipMapLodBias[0] = -1;
		MipMapLodBias[1] = -1;

		ColorWriteEnable = RED|GREEN|BLUE;

		AlphaBlendEnable = False;
		AlphaTestEnable = False;
		CullMode = CCW;

		VertexShader = compile vs_3_0 StaticTreeVS();
		PixelShader = compile ps_3_0 StaticTreePS();
	}
}
