
#include "standardfuncs.fxh"

float4x4 WorldMatrix;
float4x4 matBones[45] : Bones;
float Time;
float4 TextureOffset;
float vScale;

float4 PrimaryColor;
float4 SecondaryColor;
float4 TertiaryColor;

const int SKINNING_INFLUENCES = 2;

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


struct VS_INPUT
{
    float4 vPosition   : POSITION;
    float3 vNormal     : NORMAL;
	float4 vTangent    : TANGENT;
	float2 vTexCoord0  : TEXCOORD0;
	float4 boneIndices : BLENDINDICES;
    float4 boneWeights : BLENDWEIGHT;
};

struct VS_INPUT_STATIC
{
    float4 vPosition   : POSITION;
    float3 vNormal     : NORMAL;
	float4 vTangent    : TANGENT;
	float2 vTexCoord0  : TEXCOORD0;
};

struct VS_OUTPUT
{
    float4 vPosition  : POSITION;
	float2 vTexCoord0 : TEXCOORD0;
	float3 Normal     : TEXCOORD1;
	float3 vPos       : TEXCOORD2;
	float3 vTangent   : TEXCOORD3;
};

struct VS_INPUT_TAB
{
    float4 vPosition   : POSITION;
    float3 vNormal     : NORMAL;
	float4 vTangent    : TANGENT;
	float2 vTexCoord0  : TEXCOORD0;
	float2 vTexCoord1  : TEXCOORD1;
	float4 boneIndices : BLENDINDICES;
    float4 boneWeights : BLENDWEIGHT;
};

struct VS_INPUT_TAB_STATIC
{
    float4 vPosition   : POSITION;
    float3 vNormal     : NORMAL;
	float4 vTangent    : TANGENT;
	float2 vTexCoord0  : TEXCOORD0;
	float2 vTexCoord1  : TEXCOORD1;
};


struct VS_OUTPUT_TAB
{
    float4 vPosition  : POSITION;
	float2 vTexCoord0 : TEXCOORD0;
	float2 vTexCoord1 : TEXCOORD1;
	float3 vNormal    : TEXCOORD2;
	float3 vPos       : TEXCOORD3;
};

struct VS_OUTPUT_TAB_STATIC
{
    float4 vPosition  : POSITION;
	float2 vTexCoord0 : TEXCOORD0;
	float2 vTexCoord1 : TEXCOORD1;
	float3 vNormal    : TEXCOORD2;
	float3 vPos       : TEXCOORD3;
	float3 vTangent	  : TEXCOORD4;
};


VS_OUTPUT SkinnedAvatarVS(const VS_INPUT v )
{
	VS_OUTPUT Out = (VS_OUTPUT)0;
		
	float4 skinnedPosition = (float4)0;
	float3 skinnedNormal = (float3)0;
	float3 skinnedTangent = (float3)0;

	float4 vPosition = float4( v.vPosition.xyz, 1.0 );
		
	// skinning
	for( int i = 0; i < SKINNING_INFLUENCES; ++i )
    {
    	float4x4 mat = matBones[ v.boneIndices[i] ];

		skinnedPosition += mul( vPosition, mat ) * v.boneWeights[i];		
		skinnedNormal += mul( v.vNormal, mat ) * v.boneWeights[i];
		skinnedTangent += mul( v.vTangent.xyz, mat ) * v.boneWeights[i];
	}
	
	Out.vPos = skinnedPosition.xyz;
	Out.vPosition = mul(skinnedPosition, ViewProjectionMatrix );
	Out.vTexCoord0 = v.vTexCoord0;
	Out.Normal  = normalize(skinnedNormal);
	Out.vTangent = normalize( skinnedTangent ) * v.vTangent.w;

	return Out;
}

VS_OUTPUT StaticAvatarVS(const VS_INPUT_STATIC v )
{
	VS_OUTPUT Out = (VS_OUTPUT)0;
			
	Out.vPosition = float4(v.vPosition.xyz * vScale, 1.0);
	Out.vPosition = mul(Out.vPosition, WorldMatrix );
	
	Out.vPos = Out.vPosition.xyz;
	Out.vPosition = mul(Out.vPosition, ViewProjectionMatrix );
	
	Out.vTexCoord0 = v.vTexCoord0;
	Out.Normal  = normalize( mul( v.vNormal, WorldMatrix ) );

	return Out;
}

float4 SkinnedAvatarPS( VS_OUTPUT In ) : COLOR
{
	float4 vColor = tex2D( DiffuseMap, In.vTexCoord0 );
	float4 vColor_Spec = tex2D( SpecularMap, In.vTexCoord0 );
	float3 vNormal = normalize( In.Normal );

	vColor.rgb = CalculateLighting( vColor, vNormal );
	float vFoW = GetFoW( In.vPos, FoWTexture, FoWDiffuse );
	vColor.rgb = ApplyDistanceFog( vColor.rgb, In.vPos ) * vFoW;
	vColor.rgb = ComposeSpecular( vColor.rgb, CalculateSpecular( In.vPos, vNormal, vColor_Spec.r ) * vFoW );

	return vColor;
}

float4 SkinnedAvatarNormalPS( VS_OUTPUT In ) : COLOR
{
	float4 vColor = tex2D( DiffuseMap, In.vTexCoord0 );
	clip( vColor.a - 0.0001f );

	float4 vColor_Spec = tex2D( SpecularMap, In.vTexCoord0 );
	float3 vNormal = normalize( In.Normal );
	float3 vTangent = normalize( In.vTangent );
	float3 vBitangent = cross( vTangent, vNormal );

	float3 vNormalSample = normalize( tex2D( NormalMap, In.vTexCoord0 ).rbg - 0.5f );
	float3x3 TNB = float3x3( vTangent, vNormal, vBitangent );
	vNormal = mul( vNormalSample, TNB );

	vColor.rgb = CalculateLighting( vColor, vNormal );
	float vFoW = GetFoW( In.vPos, FoWTexture, FoWDiffuse );
	vColor.rgb = ApplyDistanceFog( vColor.rgb, In.vPos ) * vFoW;
	vColor.rgb = ComposeSpecular( vColor.rgb, CalculateSpecular( In.vPos, vNormal, vColor_Spec.a ) * vFoW );

	return vColor;
}


float2 GetTexCoordsInAtlas(float2 TexCoord)
{
	return float2( (TexCoord.x / TextureOffset.x) + TextureOffset.z,
	               (TexCoord.y / TextureOffset.y) + TextureOffset.w );
}

VS_OUTPUT_TAB_STATIC StaticAvatarVSTabard(const VS_INPUT_TAB_STATIC v )
{
	VS_OUTPUT_TAB_STATIC Out = (VS_OUTPUT_TAB_STATIC)0;

	Out.vPosition = float4(v.vPosition.xyz * vScale, 1.0);
	float4x4 Rot = { ViewMatrix._m00_m10_m20, 0.0f,
                     ViewMatrix._m01_m11_m21, 0.0f,
					 ViewMatrix._m02_m12_m22, 0.0f,
					 0.0f, 0.0f, 0.0f, 1.0f }; 

	Out.vPosition = mul( Out.vPosition, Rot );
	Out.vPosition = mul( Out.vPosition, WorldMatrix );
	
	Out.vPos = Out.vPosition.xyz;
	Out.vPosition = mul( Out.vPosition, ViewProjectionMatrix );

	Out.vTexCoord0 = v.vTexCoord0;
	Out.vTexCoord1 = v.vTexCoord1;
	Out.vNormal = normalize( mul( v.vNormal, Rot ) );
	Out.vTangent = normalize( mul( v.vTangent.xyz, (float3x3)Rot ) ) * v.vTangent.w;

	return Out;
}

float4 StaticAvatarPSTabard( VS_OUTPUT_TAB_STATIC In ) : COLOR
{
	float4 vColor = tex2D( DiffuseMap, In.vTexCoord0 );
	float3 vSpecColor = tex2D( SpecularMap, In.vTexCoord0 ).rgb;
	float3 vTabardColor = tex2D( FlagMap, GetTexCoordsInAtlas( In.vTexCoord1 ) ).rgb;
	float3 vNormal = normalize( In.vNormal );
	float3 vTangent = normalize( In.vTangent );
	float3 vBitangent = cross( vTangent, vNormal );

	float3 vNormalSample = normalize( tex2D( NormalMap, In.vTexCoord0 ).rbg - 0.5f );
	float3x3 TNB = float3x3( vTangent, vNormal, vBitangent );
	vNormal = mul( vNormalSample, TNB );
	
	float3 vFinal = vColor.rgb * ( 1 - vColor.a ) + vColor.rgb * vColor.a * vTabardColor;

	vFinal = CalculateLighting( vFinal, vNormal );
	float vFoW = GetFoW( In.vPos, FoWTexture, FoWDiffuse );
	vFinal = ApplyDistanceFog( vFinal, In.vPos ) * vFoW;
	vFinal = ComposeSpecular( vFinal, CalculateSpecular( In.vPos, vNormal, vSpecColor.r ) * vFoW );

	return float4( vFinal, 1 );
}


VS_OUTPUT_TAB SkinnedAvatarVSTabard(const VS_INPUT_TAB v )
{
	VS_OUTPUT_TAB Out = (VS_OUTPUT_TAB)0;
		
	float4 skinnedPosition = (float4)0;
	float3 skinnedNormal = (float3)0;
	//float3 skinnedTangent = (float3)0;
	
	float4 vPosition = float4( v.vPosition.xyz, 1.0 );
		
	// skinning
	for( int i = 0; i < SKINNING_INFLUENCES; ++i )
    {
    	float4x4 mat = matBones[ v.boneIndices[i] ];

		skinnedPosition += mul( vPosition, mat ) * v.boneWeights[i];		
		skinnedNormal += mul( v.vNormal, mat ) * v.boneWeights[i];
		//skinnedTangent += mul( v.vTangent.xyz, mat ) * v.boneWeights[i];
	}
		
	Out.vPos = skinnedPosition.xyz;
	Out.vPosition = mul( skinnedPosition, ViewProjectionMatrix );
	Out.vTexCoord0 = v.vTexCoord0;
	Out.vTexCoord1 = v.vTexCoord1;
	Out.vNormal = normalize( skinnedNormal );
	//Out.vTangent = normalize( skinnedTangent ) * v.vTangent.w;

	return Out;
}

float4 SkinnedAvatarPSTabard( VS_OUTPUT_TAB In ) : COLOR
{
	float4 vColor = tex2D( DiffuseMap, In.vTexCoord0 );
	float3 vSpecColor = tex2D( SpecularMap, In.vTexCoord0 ).rgb;
	float3 vTabardColor = tex2D( FlagMap, GetTexCoordsInAtlas( In.vTexCoord1 ) ).rgb;
	float3 vNormal = normalize( In.vNormal );
	
	float3 vFinal = vColor.rgb * ( 1 - vColor.a ) + vColor.rgb * vColor.a * vTabardColor;

	vFinal = CalculateLighting( vFinal, vNormal );
	float vFoW = GetFoW( In.vPos, FoWTexture, FoWDiffuse );
	vFinal = ApplyDistanceFog( vFinal, In.vPos ) * vFoW;
	vFinal = ComposeSpecular( vFinal, CalculateSpecular( In.vPos, vNormal, vSpecColor.r ) * vFoW );

	return float4( vFinal, 1 );
}

float4 SkinnedAvatarPSShadow( VS_OUTPUT In ) : COLOR
{
	clip( -1 );
	float4 vColor = tex2D( DiffuseMap, In.vTexCoord0 );
	return vColor;
}

/////////////////////////////////////////////////////

technique StaticStandard
{
	pass p0
	{	
		MipMapLodBias[0] = -1;
		CullMode = CCW;
		AlphaBlendEnable = False;
		AlphaTestEnable = False;

		VertexShader = compile vs_3_0 StaticAvatarVS();
		PixelShader = compile ps_3_0 SkinnedAvatarPS();
	}
}

technique StaticStandardNormal
{
	pass p0
	{	
		MipMapLodBias[0] = -1;
		CullMode = CCW;
		AlphaBlendEnable = True;
		AlphaTestEnable = False;

		VertexShader = compile vs_3_0 SkinnedAvatarVS();
		PixelShader = compile ps_3_0 SkinnedAvatarNormalPS();
	}
}

technique Standard
{
	pass p0
	{
		MipMapLodBias[0] = -1;
		//CullMode = CCW;
		AlphaBlendEnable = False;
		AlphaTestEnable = False;
		
		VertexShader = compile vs_3_0 SkinnedAvatarVS();
		PixelShader = compile ps_3_0 SkinnedAvatarPS();
	}
}

technique Shadow
{
	pass p0
	{
		ZENABLE = True;
		ALPHABLENDENABLE = True;
		ALPHATESTENABLE = False;
		ZWRITEENABLE = False;
		VertexShader = compile vs_3_0 SkinnedAvatarVS();
		PixelShader = compile ps_3_0 SkinnedAvatarPSShadow();
	}
}

technique StaticShadow
{
	pass p0
	{
		ZENABLE = True;
		ALPHABLENDENABLE = True;
		ALPHATESTENABLE = False;
		ZWRITEENABLE = False;
		VertexShader = compile vs_3_0 StaticAvatarVS();
		PixelShader = compile ps_3_0 SkinnedAvatarPSShadow();
	}
}



technique StaticTabard
{
	pass p0
	{		
		MipMapLodBias[0] = -1;
		CullMode = CCW;
		AlphaBlendEnable = False;
		AlphaTestEnable = False;

		VertexShader = compile vs_3_0 StaticAvatarVSTabard();
		PixelShader = compile ps_3_0 StaticAvatarPSTabard();
	}
}

technique Tabard
{
	pass p0
	{
		MipMapLodBias[0] = -1;
		CullMode = CCW;
		AlphaBlendEnable = False;
		AlphaTestEnable = False;
		
		VertexShader = compile vs_3_0 SkinnedAvatarVSTabard();
		PixelShader = compile ps_3_0 SkinnedAvatarPSTabard();
	}
}
