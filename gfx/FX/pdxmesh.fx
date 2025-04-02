#include "standardfuncs.fxh"

float4x4 WorldMatrix;
float4x4 matBones[45];

const int PDXMESH_MAX_INFLUENCE = 4;

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
	MinFilter = Anisotropic;
    
    MaxAnisotropy = 4;
};

sampler2D SpecularMap = 
sampler_state 
{
    texture = <tex1>;
    AddressU  = Wrap;        
    AddressV  = Wrap;
    MipFilter = Linear;
    MinFilter = Linear;
    MagFilter = Linear;
};

sampler2D NormalMap = 
sampler_state 
{
    texture = <tex2>;
    AddressU  = Wrap;        
    AddressV  = Wrap;
    MipFilter = Linear;
    MagFilter = Linear;
	MinFilter = Linear;
};

sampler2D FlagMap = 
sampler_state 
{
    texture = <tex3>;
    AddressU  = Clamp;        
    AddressV  = Clamp;
    MipFilter = None;
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

struct VS_INPUT_PDXMESHSTANDARD
{
    float3 vPosition	: POSITION;
	float3 vNormal      : TEXCOORD0;
	float4 vTangent		: TEXCOORD1;
	float2 vUV0			: TEXCOORD2;
	float4 vBoneIndex	: BLENDINDICES;
	float4 vBoneWeight	: BLENDWEIGHT;
};


struct VS_OUTPUT_PDXMESHSTANDARD
{
    float4 vPosition	: POSITION;
	float3 vNormal		: TEXCOORD0;
	float3 vTangent		: TEXCOORD1;
	float3 vBitangent	: TEXCOORD2;
	float2 vUV0			: TEXCOORD3;
	float4 vPos			: TEXCOORD4;
};


VS_OUTPUT_PDXMESHSTANDARD VertexPdxMeshStandardSkinned( const VS_INPUT_PDXMESHSTANDARD v )
{
  	VS_OUTPUT_PDXMESHSTANDARD Out;
			
	float4 vPosition = float4( v.vPosition.xyz, 1.0 );
	float4 vSkinnedPosition = float4( 0, 0, 0, 0 );
	float3 vSkinnedNormal = float3( 0, 0, 0 );
	float3 vSkinnedTangent = float3( 0, 0, 0 );
	float3 vSkinnedBitangent = float3( 0, 0, 0 );

	float4 vWeight = float4( v.vBoneWeight.xyz, 1.0f - v.vBoneWeight.x - v.vBoneWeight.y - v.vBoneWeight.z );

	for( int i = 0; i < PDXMESH_MAX_INFLUENCE; ++i )
    {
		int nIndex = int( v.vBoneIndex[i] );
		float4x4 mat = matBones[nIndex];
		mat = transpose( mat );
		vSkinnedPosition += mul( vPosition, mat ) * vWeight[i];

		float3 vNormal = mul( v.vNormal, (float3x3)mat );
		float3 vTangent = mul( v.vTangent.xyz, (float3x3)mat );
		float3 vBitangent = cross( vNormal, vTangent ) * v.vTangent.w;

		vSkinnedNormal += vNormal * vWeight[i];
		vSkinnedTangent += vTangent * vWeight[i];
		vSkinnedBitangent += vBitangent * vWeight[i];
	}

	Out.vPosition = mul( vSkinnedPosition, WorldMatrix );
	Out.vPos = Out.vPosition;
	Out.vPosition = mul( Out.vPosition, ViewProjectionMatrix );


	Out.vNormal = normalize( vSkinnedNormal );
	Out.vTangent = normalize( vSkinnedTangent );
	Out.vBitangent = normalize( vSkinnedBitangent );

	Out.vUV0 = v.vUV0;

	return Out;
}


VS_OUTPUT_PDXMESHSTANDARD VertexPdxMeshStandard( const VS_INPUT_PDXMESHSTANDARD v )
{
  	VS_OUTPUT_PDXMESHSTANDARD Out;
	
	float4 vPosition = float4( v.vPosition.xyz, 1.0 );
	Out.vNormal = mul( v.vNormal, WorldMatrix );
	Out.vTangent = mul( v.vTangent.xyz, WorldMatrix );
	Out.vBitangent = normalize( cross( Out.vNormal, Out.vTangent ) * v.vTangent.w );

	Out.vPosition = mul( vPosition, WorldMatrix );
	Out.vPos = Out.vPosition;
	Out.vPosition = mul( Out.vPosition, ViewProjectionMatrix );

	Out.vUV0 = v.vUV0;

	return Out;
}

	
float4 PixelPdxMeshStandard( VS_OUTPUT_PDXMESHSTANDARD In ) : COLOR
{
	float4 vColor = tex2D( DiffuseMap, In.vUV0 );
	float3 vSpecColor = tex2D( SpecularMap, In.vUV0 ).rgb;

	float3 vNormalSample = normalize( tex2D( NormalMap, In.vUV0 ).rgb - 0.5f );
	float3x3 TBN = float3x3( normalize( In.vTangent ), normalize( In.vBitangent ), normalize( In.vNormal ) );
	float3 vNormal = mul( vNormalSample, TBN );

	float3 vFinal = vColor.rgb;

	
	float3 vFoWPos = In.vPos.xyz / In.vPos.w;

	vFinal = CalculateLighting( vFinal, vNormal );
	
	float vFoW = GetFoW( vFoWPos, FoWTexture, FoWDiffuse );
	vFinal.rgb = ApplyDistanceFog( vFinal.rgb, vFoWPos ) * vFoW;

	vFinal = ComposeSpecular( vFinal, CalculateSpecular( vFoWPos, vNormal, vSpecColor.r ) );

	return float4( vFinal, vColor.a );
	
}


/////////////////////////////////////////////////////

technique PdxMeshStandardSkinned
{
	pass p0
	{	
		MipMapLodBias[0] = -1;
		CullMode = CCW;
		AlphaBlendEnable = False;
		AlphaTestEnable = False;

		VertexShader = compile vs_3_0 VertexPdxMeshStandardSkinned();
		PixelShader = compile ps_3_0 PixelPdxMeshStandard();
	}
}

technique PdxMeshStandard
{
	pass p0
	{	
		MipMapLodBias[0] = -1;
		CullMode = CCW;
		AlphaBlendEnable = False;
		AlphaTestEnable = False;

		VertexShader = compile vs_3_0 VertexPdxMeshStandard();
		PixelShader = compile ps_3_0 PixelPdxMeshStandard();
	}
}

technique PdxMeshAlphaBlendSkinned
{
	pass p0
	{	
		MipMapLodBias[0] = -1;
		CullMode = CCW;
		AlphaBlendEnable = True;
		AlphaTestEnable = False;

		VertexShader = compile vs_3_0 VertexPdxMeshStandardSkinned();
		PixelShader = compile ps_3_0 PixelPdxMeshStandard();
	}
}

