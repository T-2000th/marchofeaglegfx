
#include "standardfuncs.fxh"

texture tex0;
texture tex1;
texture tex2;
texture tex3;
texture tex4;
texture tex5;
texture tex6;
texture tex7;

sampler2D DiffuseMap = 
sampler_state 
{
    texture = <tex0>;
    AddressU  = Wrap;        
    AddressV  = Clamp;
    MipFilter = Linear;
    MagFilter = Linear;
	MinFilter = Linear;
};

sampler2D NormalMap = 
sampler_state 
{
    texture = <tex1>;
    AddressU  = Wrap;        
    AddressV  = Clamp;
    MipFilter = Linear;
    MinFilter = Linear;
    MagFilter = Linear;
};

sampler2D DiffuseBottomMap = 
sampler_state 
{
    texture = <tex2>;
    AddressU  = Wrap;        
    AddressV  = Clamp;
    MipFilter = Linear;
    MinFilter = Linear;
    MagFilter = Linear;
};

sampler2D SurfaceNormalMap = 
sampler_state 
{
    texture = <tex3>;
    AddressU  = Wrap;        
    AddressV  = Wrap;
    MipFilter = Linear;
    MinFilter = Linear;
    MagFilter = Linear;
};

sampler2D ColorOverlay = 
sampler_state 
{
    texture = <tex4>;
    AddressU  = Wrap;        
    AddressV  = Wrap;
    MipFilter = Linear;
    MinFilter = Linear;
    MagFilter = Linear;
};

sampler2D HeightNormal = 
sampler_state 
{
    texture = <tex5>;
    AddressU  = Wrap;        
    AddressV  = Wrap;
    MipFilter = Linear;
    MinFilter = Linear;
    MagFilter = Linear;
};

sampler2D FoWTexture = 
sampler_state 
{
    texture = <tex6>;
    AddressU = WRAP;
    AddressV = WRAP;
    MIPFILTER = LINEAR;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
};

sampler2D FoWDiffuse = 
sampler_state 
{
    texture = <tex7>;
    AddressU = WRAP;
    AddressV = WRAP;
    MIPFILTER = LINEAR;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
};

struct VS_INPUT
{
    float4 vPosition   : POSITION;
	float4 vUV_Tangent : TEXCOORD0;
};

struct VS_OUTPUT
{
    float4 vPosition	    : POSITION;
	float4 vUV			    : TEXCOORD0;
	float4 vWorldUV_Tangent	: TEXCOORD1;
	float4 vPrePos_Fade		: TEXCOORD2;
	float4 vSecondaryUV		: TEXCOORD3;
};

uniform float vTime;
uniform float vDirection;

VS_OUTPUT RiverFlatVS( const VS_INPUT v )
{
	VS_OUTPUT Out = (VS_OUTPUT)0;

	Out.vPosition = float4( v.vPosition.xyz, 1.0f );

	float4 vTmpPos = float4( v.vPosition.xyz, 1.0f );
	Out.vPrePos_Fade.xyz = vTmpPos.xyz;

	float4 vDistortedPos = vTmpPos - float4( vCamLookAtDir * 0.05f, 0.0f );

	vTmpPos = mul( vTmpPos, ViewProjectionMatrix );
	
	// move z value slightly closer to camera to avoid intersections with terrain
	float vNewZ = dot( vDistortedPos, ViewProjectionMatrix._m02_m12_m22_m32 );
	Out.vPosition = float4( vTmpPos.xy, vNewZ, vTmpPos.w );
	
	Out.vUV.yx = v.vUV_Tangent.xy;
	Out.vUV.x += vTime * 1.0f * vDirection;
	Out.vUV.y += vTime * 0.2f;
	Out.vUV.x *= 0.05f;

	Out.vSecondaryUV.yx = v.vUV_Tangent.xy;
	Out.vSecondaryUV.x += vTime * 0.9f * vDirection;
	Out.vSecondaryUV.y -= vTime * 0.1f;
	Out.vSecondaryUV.x *= 0.05f;

	Out.vUV.wz = v.vUV_Tangent.xy;
	Out.vUV.z *= 0.05f;

	Out.vWorldUV_Tangent.xy = ( v.vPosition.xz + 0.5f - float2( 0.0f, 2048.0f ) ) / float2( 2048.0f, -2048.0f );
	Out.vWorldUV_Tangent.zw = v.vUV_Tangent.zw;
	Out.vPrePos_Fade.w = saturate( 1.0f - v.vUV_Tangent.y );

	return Out;
}


float4 RiverPS( VS_OUTPUT In ) : COLOR
{
	float4 vWaterSurface = tex2D( DiffuseMap, float2( In.vUV.x, In.vUV.w ) );

	float3 vHeightNormal = normalize( tex2D( HeightNormal, In.vWorldUV_Tangent.xy ).rbg - 0.5f );

	float3 vSurfaceNormal1 = normalize( tex2D( SurfaceNormalMap, In.vUV.xy ).rgb - 0.5f );
	float3 vSurfaceNormal2 = normalize( tex2D( SurfaceNormalMap, In.vSecondaryUV ).rgb - 0.5f );

	float3 vSurfaceNormal = normalize( vSurfaceNormal1 + vSurfaceNormal2 );

	vSurfaceNormal.xzy = float3( vSurfaceNormal.x * In.vWorldUV_Tangent.zw + vSurfaceNormal.y * float2( -In.vWorldUV_Tangent.w, In.vWorldUV_Tangent.z ), vSurfaceNormal.z );
	vSurfaceNormal =
		  vHeightNormal.yxz * vSurfaceNormal.x
		+ vHeightNormal.xyz * vSurfaceNormal.y
		+ vHeightNormal.xzy * vSurfaceNormal.z;

	float3 vEyeDir = normalize( In.vPrePos_Fade.xyz - vCamPos );
	float3 H = normalize( -vLightDir + -vEyeDir );

	float vSpecRemove = 1.0f - abs( 0.5f - In.vUV.w ) * 2.0f;

	float vSpecWidth = 70.0f;
	float vSpecMultiplier = 0.25f;
	float specular = saturate( pow( saturate( dot( H, vSurfaceNormal ) ), vSpecWidth ) * vSpecMultiplier ) * vSpecRemove/*  dot( vWaterSurface, vWaterSurface )*/;

	float2 vDistort = refract( vCamLookAtDir, vSurfaceNormal, 0.66f ).xz;

	vDistort = vDistort.x * In.vWorldUV_Tangent.zw + vDistort.y * float2( -In.vWorldUV_Tangent.w, In.vWorldUV_Tangent.z );

	float3 vBottom = tex2D( DiffuseBottomMap, In.vUV.zw + vDistort * 0.05f ).rgb;
	float  vBottomAlpha = tex2D( DiffuseBottomMap, In.vUV.zw ).a;

	vBottom = GetOverlay( vBottom, tex2D( ColorOverlay, In.vWorldUV_Tangent.xy ), 0.5f );

	float3 vBottomNormal = normalize( tex2D( NormalMap, In.vUV.zw ).rgb - 0.5f );
	vBottomNormal.xzy = float3( vBottomNormal.x * In.vWorldUV_Tangent.zw + vBottomNormal.y * float2( -In.vWorldUV_Tangent.w, In.vWorldUV_Tangent.z ), vBottomNormal.z );
	vBottomNormal = 
		  vHeightNormal.yxz * vBottomNormal.x
		+ vHeightNormal.xyz * vBottomNormal.y
		+ vHeightNormal.xzy * vBottomNormal.z;

	float3 vColor = lerp( vBottom, vWaterSurface.xyz, vWaterSurface.a * 0.8f );
	vColor = CalculateLighting( vColor, vBottomNormal );
	float vFoW = GetFoW( In.vPrePos_Fade.xyz, FoWTexture, FoWDiffuse );
	vColor = ApplyDistanceFog( vColor, In.vPrePos_Fade.xyz ) * vFoW;
	return float4( ComposeSpecular( vColor, specular * ( 1.0f - In.vPrePos_Fade.w ) * vWaterSurface.a * vFoW ), vBottomAlpha * ( 1.0f - In.vPrePos_Fade.w ) );
}


technique River
{
	pass p0
	{
		ZWriteEnable = False;
		ZEnable = True;
		ColorWriteEnable = RED|GREEN|BLUE;

		CullMode = CW;

		AlphaBlendEnable = True;
		AlphaTestEnable = False;

		VertexShader = compile vs_3_0 RiverFlatVS();
		PixelShader = compile ps_3_0 RiverPS();
	}
}
