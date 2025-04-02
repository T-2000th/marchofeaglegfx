
#include "standardfuncs.fxh"

float4		QuadOffset_Scale_IsDetail;
float4		vSnap;
float		vBorderLookup;
float		vHeightScale;

// constants --------------------------------------------------------------------------------------------
uniform float WATER_HEIGHT = 19.0f;
uniform float WATER_HEIGHT_RECP = 1.0f / 19.0f;

texture tex0;
texture tex1;
texture tex2;
texture tex3;
texture tex4;
texture tex5;
texture tex6;
texture tex7;
texture tex8;
texture ice_diffuse;
texture ice_normal;

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


// Water --------------------------------------------------------------------------------------------

sampler2D HeightTexture = 
sampler_state 
{
    texture = <tex0>;
    AddressU = WRAP;
    AddressV = WRAP;
    MIPFILTER = LINEAR;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
};

sampler2D WaterNormal = 
sampler_state 
{
    texture = <tex1>;
    AddressU = WRAP;
    AddressV = WRAP;
    MIPFILTER = LINEAR;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
};


samplerCUBE ReflectionCubeMap = 
sampler_state 
{ 
	texture = <tex2>; 
	magfilter = LINEAR; 
	minfilter = LINEAR; 
	mipfilter = LINEAR; 
	AddressU = mirror; 
	AddressV = mirror;
};

sampler2D WaterColor = 
sampler_state 
{
    texture = <tex3>;
    AddressU = WRAP;
    AddressV = WRAP;
    MIPFILTER = LINEAR;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
};

sampler2D WaterNoise = 
sampler_state 
{
    texture = <tex4>;
    AddressU = WRAP;
    AddressV = WRAP;
    MIPFILTER = LINEAR;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
};

sampler2D WaterRefraction = 
sampler_state 
{
    texture = <tex5>;
    AddressU = CLAMP;
    AddressV = CLAMP;
    MIPFILTER = LINEAR;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
};

sampler2D IceDiffuse = 
sampler_state 
{
    texture = <ice_diffuse>;
    AddressU = WRAP;
    AddressV = WRAP;
    MIPFILTER = LINEAR;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
};

sampler2D IceNormal = 
sampler_state 
{
    texture = <ice_normal>;
    AddressU = WRAP;
    AddressV = WRAP;
    MIPFILTER = LINEAR;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
};
struct VS_INPUT_WATER
{
    float2 position			: POSITION;
};

struct VS_OUTPUT_WATER
{
    float4 position			: POSITION;
	float3 pos				: TEXCOORD0; 
	float2 uv				: TEXCOORD1;
	float4 screen_pos		: TEXCOORD2; 
	float3 cubeRotation     : TEXCOORD3;
	float2 uv_ice			: TEXCOORD4;
};

float vTime;
float2 vHalfPixelOffset;
float vWinterOpacity;

uniform float vTimeScale = 0.5f / 300.0f;

VS_OUTPUT_WATER VertexShader_Water( const VS_INPUT_WATER VertexIn )
{
	VS_OUTPUT_WATER VertexOut = (VS_OUTPUT_WATER)0;
	VertexOut.pos = float3( VertexIn.position.x, WATER_HEIGHT, VertexIn.position.y );
	VertexOut.position = mul( float4( VertexOut.pos, 1.0f ), ViewProjectionMatrix );
	VertexOut.screen_pos = VertexOut.position;
	VertexOut.uv = ( VertexIn.position.xy + 0.5f - float2( 0.0f, 2048.0f ) ) / float2( 2048.0f, -2048.0f );
	VertexOut.uv_ice = VertexOut.uv*2048.f*0.1f;

	float vAnimTime = vTime * 0.01f;
	VertexOut.cubeRotation = normalize( float3( sin( vAnimTime ) * 0.5f, sin( vAnimTime ), cos( vAnimTime ) * 0.3f ) );
	return VertexOut;
}


float3 CalcWaterNormal( float2 uv, float vTimeSpeed )
{
	float vScaledTime = vTime * vTimeSpeed;
	float vScaleUV = 10.0f;

	float2 time1 = vScaledTime * float2( 0.3f, 0.7f );
	float2 time2 = -vScaledTime * 0.75f * float2( 0.8f, 0.2f );
	//float2 time3 = vScaledTime * 1.65f * float2( 0.45f, -0.55f );

	float2 uv1 = vScaleUV * uv;
	float2 uv2 = vScaleUV * uv * 1.3;
	//float2 uv3 = vScaleUV * uv * 1.8;

	//float vTimeScale = 6.0f;

	//float2 vRotatedUV = uv1 + time1 * float2(0.8f, 0.2f) * vTimeScale;
	//vRotatedUV = float2( vRotatedUV.x + vRotatedUV.y, vRotatedUV.x - vRotatedUV.y );

	//float3 normal1 = tex2D( WaterNormal, vRotatedUV ).rgb - 0.5f;
	//float3 normal2 = tex2D( WaterNormal, uv2.yx  + time2 * vTimeScale * float2( 0.45f, 0.55f ) ).rgb - 0.5f;
	//float3 normal3 = tex2D( WaterNormal, uv3 + time3 * float2( -1.0f, 0.0f ) * vTimeScale ).rgb - 0.5f;

	float noiseScale = 12.0f;

	float3 noiseNormal1 = tex2D( WaterNoise, uv1 * noiseScale + time1 * 3.0f ).rgb - 0.5f;
	float3 noiseNormal2 = tex2D( WaterNoise, uv2 * noiseScale + time2 * 3.0f ).rgb - 0.5f;
	
	//float3 normalWaves = normal1 + normal2 + normal3;
	float3 normalNoise = noiseNormal1 + noiseNormal2 + float3( 0.0f, 0.0f, 1.5f );

	return normalize( /*normalWaves +*/ normalNoise ).xzy;
}

float4 ApplyIce( float4 vColor, float2 vPos, inout float3 vNormal, float4 vFoWColor, float2 vIceUV, out float vIceFade )
{
	float vSnow = GetSnow(vFoWColor);
	vSnow *= vWinterOpacity;
	vIceFade = vSnow * 4.0f;
	float vIceNoise = tex2D( FoWDiffuse, ( vPos + 0.5f ) / 64.0f  ).r;
	vIceFade *= vIceNoise;
	vIceFade = saturate( vIceFade );
	vNormal = lerp( vNormal, tex2D( IceNormal, vIceUV ), vIceFade );

	float4 vIceColor = tex2D( IceDiffuse, vIceUV );
	vColor = lerp( vColor, vIceColor, saturate(vIceFade*2.6f) );

	return vColor;
}

float4 PixelShader_Water( VS_OUTPUT_WATER Input ) : COLOR
{
	float3 normal = CalcWaterNormal( Input.uv, vTimeScale * 12.0f );
	
	float4 vFoWColor = GetFoWColor( Input.pos, FoWTexture);	

	//Ice effect
	float4 waterColor = tex2D( WaterColor, Input.uv );
	float vIceFade = 0.0f;
	waterColor = ApplyIce( waterColor, Input.pos.xz, normal, vFoWColor, Input.uv_ice, vIceFade );

	float3 vEyeDir = normalize( Input.pos - vCamPos );

	float3 normalReflection = normal;
	//float3 normalReflection = normalize( 
	//	  normal.yxz * Input.cubeRotation.x
	//	+ normal.xyz * Input.cubeRotation.y
	//	+ normal.xzy * Input.cubeRotation.z );

	float3 reflection = reflect( vEyeDir, normalReflection );
	float3 reflectiveColor = texCUBE( ReflectionCubeMap, reflection ).rgb;

	float2 refractiveUV = ( Input.screen_pos.xy / Input.screen_pos.w ) * 0.5f + 0.5f;
	refractiveUV.y = 1.0f - refractiveUV.y;
	refractiveUV += vHalfPixelOffset;

	float vRefractionScale = saturate( 5.0f - ( Input.screen_pos.z / Input.screen_pos.w ) * 5.0f );
	float3 refractiveColor = tex2D( WaterRefraction, refractiveUV.xy - normal.xz * vRefractionScale * 0.2f );

	float waterHeight = tex2D( HeightTexture, Input.uv ).x;

	waterHeight /= ( 93.7f / 255.0f );
	waterHeight = saturate( ( waterHeight - 0.995f ) * 50.0f );

	float fresnelBias = 0.2f;
	float fresnel = saturate( dot( -vEyeDir, normal ) ) * 0.5f;
	fresnel = saturate( fresnelBias + ( 1.0f - fresnelBias ) * pow( 1.0f - fresnel, 10.0f ) );
	fresnel *= (1.0f-vIceFade); //No fresnel when we have snow

	float3 H = normalize( -vLightDir + -vEyeDir );

	float vSpecWidth = 1850.0f;
	float vSpecMultiplier = 3.0f;
	float specular = saturate( pow( saturate( dot( H, normal ) ), vSpecWidth ) * vSpecMultiplier );

	refractiveColor = lerp( refractiveColor, waterColor, 0.3f+(0.7f*vIceFade) );
	float3 outColor = refractiveColor * ( 1.0f - fresnel ) + reflectiveColor * fresnel;

	
	float vFoW = GetFoW( Input.pos, FoWTexture, FoWDiffuse );
	outColor = ApplyDistanceFog( outColor, Input.pos ) * vFoW;

	return float4( ComposeSpecular( outColor, specular * vFoW ), 1.0f - waterHeight );
}

technique Water
{
	pass p0
	{
		AlphaBlendEnable = True;
		AlphaTestEnable = False;
		ColorWriteEnable = RED|GREEN|BLUE;

		VertexShader = compile vs_3_0 VertexShader_Water();
		PixelShader = compile ps_3_0 PixelShader_Water();
	}
}

// Terrain --------------------------------------------------------------------------------------------

sampler2D HeightNormal = 
sampler_state 
{
    texture = <tex1>;
    AddressU = WRAP;
    AddressV = WRAP;
    MIPFILTER = LINEAR;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
};

sampler2D ProvinceColorMap = 
sampler_state 
{
    texture = <tex3>;
    AddressU = CLAMP;
    AddressV = CLAMP;
    MIPFILTER = LINEAR;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
};

sampler2D ProvinceSecondaryColorMap = 
sampler_state 
{
    texture = <tex5>;
    AddressU = CLAMP;
    AddressV = CLAMP;
    MIPFILTER = LINEAR;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
};

sampler2D TerrainIDMap = 
sampler_state 
{
    texture = <tex4>;
    AddressU = CLAMP;
    AddressV = CLAMP;
    MIPFILTER = NONE;
    MINFILTER = POINT;
    MAGFILTER = POINT;
};

sampler2D TerrainDiffuse = 
sampler_state 
{
    texture = <tex0>;
    AddressU = WRAP;
    AddressV = WRAP;
    MIPFILTER = LINEAR;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
};

sampler2D TerrainColorTint = 
sampler_state 
{
    texture = <tex2>;
    AddressU = WRAP;
    AddressV = WRAP;
    MIPFILTER = LINEAR;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
};

sampler2D TerrainNormal = 
sampler_state 
{
    texture = <tex3>;
    AddressU = WRAP;
    AddressV = WRAP;
    MIPFILTER = POINT;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
};

sampler2D WaterColorTint = 
sampler_state 
{
    texture = <tex2>;
    AddressU = WRAP;
    AddressV = WRAP;
    MIPFILTER = LINEAR;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
};

sampler2D OccupationMask = 
sampler_state 
{
    texture = <tex8>;
    AddressU = WRAP;
    AddressV = WRAP;
    MIPFILTER = LINEAR;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
};


struct VS_INPUT_TERRAIN
{
    float4 position			: POSITION;
};

struct VS_INPUT_TERRAIN_NOTEXTURE
{
    float4 position			: POSITION;
	float2 height			: TEXCOORD0;
};

struct VS_OUTPUT_TERRAIN
{
    float4 position			: POSITION;
	float2 uv				: TEXCOORD0;
	float2 uv2				: TEXCOORD1;
	float3 prepos 			: TEXCOORD2;
};

VS_OUTPUT_TERRAIN VertexShader_TerrainNoVertexTexture( const VS_INPUT_TERRAIN_NOTEXTURE VertexIn )
{
	VS_OUTPUT_TERRAIN VertexOut = (VS_OUTPUT_TERRAIN)0;
	float2 pos = VertexIn.position.xy * QuadOffset_Scale_IsDetail.z + QuadOffset_Scale_IsDetail.xy;

	float vSatPosZ = saturate( VertexIn.position.z ); // VertexIn.position.z can have a value [0-4], if != 0 then we shall displace vertex
	float vUseAltHeight = vSatPosZ * vSnap[VertexIn.position.z - 1.0f]; // the snap values are set to either 0 or 1 before each draw call to enable/disable snapping due to LOD

	pos += vUseAltHeight 
		* float2( 1.0f - VertexIn.position.w, VertexIn.position.w ) // VertexIn.position.w determines offset direction
		* QuadOffset_Scale_IsDetail.z; // and of course we need to scale it to the same LOD

	VertexOut.uv = float2( pos + 0.5f ) / 2048.0f;
	VertexOut.uv2 = ( pos + 0.5f - float2( 0.0f, 2048.0f ) ) / float2( 2048.0f, -2048.0f );

	float vHeight = VertexIn.height.x * ( 1.0f - vUseAltHeight ) + VertexIn.height.y * vUseAltHeight;
	vHeight *= 0.01f;

	VertexOut.prepos = float3( pos.x, vHeight, pos.y );
	VertexOut.position = mul( float4( VertexOut.prepos, 1.0f ), ViewProjectionMatrix );
	return VertexOut;
}


uniform float3 GREYIFY = float3( 0.212671, 0.715160, 0.072169 );
uniform float TERRAINTILEFREQ = 64.0f;
uniform float NUM_TILES = 4.0f;
uniform float TEXELS_PER_TILE = 512.0f;
uniform float ATLAS_TEXEL_POW2_EXPONENT= 11.0f;
uniform float WATER_HEIGHT_RECP_SQUARED = ( 1.0f / 19.0f ) * ( 1.0f / 19.0f );
uniform float TERRAIN_WATER_CLIP_HEIGHT = 3.0f;
uniform float TERRAIN_UNDERWATER_CLIP_HEIGHT = 3.0f;
float vUseMultisample;

float mipmapLevel( float2 uv )
{
    float2 dx = ddx( uv * TEXELS_PER_TILE );
    float2 dy = ddy( uv * TEXELS_PER_TILE );
    float d = max( dot(dx, dx), dot(dy, dy) );
    return 0.5f * log2( d );
}

float4 sample_terrain( float IndexU, float IndexV, float2 vTileRepeat, float vMipTexels, float lod )
{
	vTileRepeat = frac( vTileRepeat );

	float vTexelsPerTile = vMipTexels / NUM_TILES;

	vTileRepeat *= ( vTexelsPerTile - 1.0f ) / vTexelsPerTile;
	return float4( ( float2( IndexU, IndexV ) + vTileRepeat ) / NUM_TILES + 0.5f / vMipTexels, 0.0f, lod );
}

void calculate_index( float4 IDs, out float4 IndexU, out float4 IndexV, out float vAllSame )
{
	IDs *= 255.0f;
	vAllSame = saturate( IDs.z - 98.0f ); // we've added 100 to first if all IDs are same
	IDs.z -= vAllSame * 100.0f;

	IndexV = trunc( ( IDs + 0.5f ) / NUM_TILES );
	IndexU = trunc( IDs - ( IndexV * NUM_TILES ) + 0.5f );
}

float3 calculate_secondary( float4 vSecondary, float3 vColor, float2 vPos )
{
	float4 vMask = tex2D( OccupationMask, vPos / 8.0f ).rgba;
	float vMaskDiff = tex2D( OccupationMask, (vPos - float2( 0.2, 0 ) ) / 8.0f ).a;
	vMaskDiff = saturate( vMask.g * 2 );
	vMaskDiff *= vMask.a * vSecondary.a;
	//return vSecondary.rgb;
	//vSecondary.a -= 0.5f * saturate( saturate( frac( vPos.x / 2.0f ) - 0.7f ) * 10000.0f );
	vSecondary.a = saturate( vSecondary.a * vMask.a );

	return ( vColor * ( 1.0f - vSecondary.a ) + vSecondary.rgb * vSecondary.a ) * ( 1- vMaskDiff );
}

float4 PixelShader_Terrain( VS_OUTPUT_TERRAIN Input ) : COLOR
{
	clip( Input.prepos.y + TERRAIN_WATER_CLIP_HEIGHT - WATER_HEIGHT );
	float2 vOffsets = float2( 0.5f / 2048.0f, -0.5f / 2048.0f );
	
	float vAllSame;
	float4 IndexU;
	float4 IndexV;
	calculate_index( tex2D( TerrainIDMap, Input.uv + vOffsets.yy ), IndexU, IndexV, vAllSame );

	float2 vTileRepeat = Input.uv2 * TERRAINTILEFREQ;

	float lod = clamp( trunc( mipmapLevel( vTileRepeat ) - 0.5f ), 0.0f, 6.0f );
	float vMipTexels = pow( 2.0f, ATLAS_TEXEL_POW2_EXPONENT - lod );

	float3 normal = normalize( tex2D( HeightNormal, Input.uv2 ).rbg - 0.5f );
	
	float4 sample = tex2Dlod( TerrainDiffuse, sample_terrain( IndexU.w, IndexV.w, vTileRepeat, vMipTexels, lod ) );
	float3 terrain_normal = tex2Dlod( TerrainNormal, sample_terrain( IndexU.w, IndexV.w, vTileRepeat, vMipTexels, lod ) ).rbg - 0.5f;
	
	if ( vAllSame < 1.0f && vUseMultisample < 8.0f )
	{
		float4 ColorRD = tex2Dlod( TerrainDiffuse, sample_terrain( IndexU.x, IndexV.x, vTileRepeat, vMipTexels, lod ) );
		float4 ColorLU = tex2Dlod( TerrainDiffuse, sample_terrain( IndexU.y, IndexV.y, vTileRepeat, vMipTexels, lod ) );
		float4 ColorRU = tex2Dlod( TerrainDiffuse, sample_terrain( IndexU.z, IndexV.z, vTileRepeat, vMipTexels, lod ) );

		float3 terrain_normalRD = tex2Dlod( TerrainNormal, sample_terrain( IndexU.x, IndexV.x, vTileRepeat, vMipTexels, lod ) ).rbg - 0.5f;
		float3 terrain_normalLU = tex2Dlod( TerrainNormal, sample_terrain( IndexU.y, IndexV.y, vTileRepeat, vMipTexels, lod ) ).rbg - 0.5f;
		float3 terrain_normalRU = tex2Dlod( TerrainNormal, sample_terrain( IndexU.z, IndexV.z, vTileRepeat, vMipTexels, lod ) ).rbg - 0.5f;

		float2 vFrac = frac( Input.uv * 2048.0f - 0.5f );

		float vAlphaFactor = 10.0f;

		float4 vTest = float4( 
			vFrac.x + vFrac.x * ColorLU.a * vAlphaFactor, 
			(1.0f - vFrac.x) + (1.0f - vFrac.x) * ColorRU.a * vAlphaFactor, 
			vFrac.x + vFrac.x * sample.a * vAlphaFactor, 
			(1.0f - vFrac.x) + (1.0f - vFrac.x) * ColorRD.a * vAlphaFactor );

		float2 yWeights = float2( ( vTest.x + vTest.y ) * vFrac.y, ( vTest.z + vTest.w ) * ( 1.0f - vFrac.y ) );

		float3 vBlendFactors = float3( vTest.x / ( vTest.x + vTest.y ),
			vTest.z / ( vTest.z + vTest.w ),
			yWeights.x / ( yWeights.x + yWeights.y ) );

		sample = lerp( 
			lerp( ColorRU, ColorLU, vBlendFactors.x ),
			lerp( ColorRD, sample, vBlendFactors.y ), 
			vBlendFactors.z );

		terrain_normal = 
			( terrain_normalRU * ( 1.0f - vBlendFactors.x ) + terrain_normalLU * vBlendFactors.x ) * ( 1.0f - vBlendFactors.z ) +
			( terrain_normalRD * ( 1.0f - vBlendFactors.y ) + terrain_normal   * vBlendFactors.y ) * vBlendFactors.z;
	}

	terrain_normal = normalize( terrain_normal );

	//Calculate normal
	float3 zaxis = normal; //normal
	float3 xaxis = cross( zaxis, float3( 0, 0, 1 ) ); //tangent
	xaxis = normalize( xaxis );
	float3 yaxis = cross( xaxis, zaxis ); //bitangent
	yaxis = normalize( yaxis );
	normal = xaxis * terrain_normal.x + zaxis * terrain_normal.y + yaxis * terrain_normal.z;
	
	sample.rgb = GetOverlay( sample.rgb, tex2D( TerrainColorTint, Input.uv2 ), 0.5f );

	float4 vFoWColor = GetFoWColor( Input.prepos, FoWTexture);	
	
	sample.rgb = ApplySnow( sample.rgb, Input.prepos, normal, vFoWColor, FoWDiffuse );

	sample.rgb = calculate_secondary( tex2D( ProvinceSecondaryColorMap, Input.uv ), sample.rgb, Input.prepos.xz );

	float3 vOut = CalculateLighting( sample.rgb, normal );

	vOut = ApplyDistanceFog( vOut, Input.prepos, vFoWColor.r, FoWDiffuse );

	return float4( ComposeSpecular( vOut, 0.0f ), 1.0f );
}


float4 PixelShader_TerrainUnderwater( VS_OUTPUT_TERRAIN Input ) : COLOR
{	
	clip( WATER_HEIGHT - Input.prepos.y + TERRAIN_WATER_CLIP_HEIGHT );

	float3 normal = normalize( tex2D( HeightNormal, Input.uv2 ).rbg - 0.5f );
	float3 sample = tex2D( TerrainDiffuse, Input.uv2 * 32.0f ).rgb;
	float3 waterColorTint = tex2D( WaterColorTint, Input.uv2 );

	float vMin = 17.0f;
	float vMax = 18.5f;
	float vWaterFog = saturate( 1.0f - ( Input.prepos.y - vMin ) / ( vMax - vMin ) );
	
	sample = lerp( sample, waterColorTint, vWaterFog );

	float vFog = saturate( Input.prepos.y * Input.prepos.y * Input.prepos.y * WATER_HEIGHT_RECP_SQUARED * WATER_HEIGHT_RECP );

	float3 vOut = CalculateLighting( sample, normal * vFog );
	return float4( vOut, 1.0f );
}


float4 PixelShader_TerrainColor( VS_OUTPUT_TERRAIN Input ) : COLOR
{
	clip( Input.prepos.y + TERRAIN_WATER_CLIP_HEIGHT - WATER_HEIGHT );
	float2 vOffsets = float2( 0.5f / 2048.0f, -0.5f / 2048.0f );
	
	float vAllSame;
	float4 IndexU;
	float4 IndexV;
	calculate_index( tex2D( TerrainIDMap, Input.uv + vOffsets.yy ), IndexU, IndexV, vAllSame );

	float2 vTileRepeat = Input.uv2 * TERRAINTILEFREQ;

	float lod = clamp( trunc( mipmapLevel( vTileRepeat ) - 0.5f ), 0.0f, 6.0f );
	float vMipTexels = pow( 2.0f, ATLAS_TEXEL_POW2_EXPONENT - lod );

	float3 normal = normalize( tex2D( HeightNormal, Input.uv2 ).rbg - 0.5f );
	
	float4 sample = tex2Dlod( TerrainDiffuse, sample_terrain( IndexU.w, IndexV.w, vTileRepeat, vMipTexels, lod ) );
	float3 terrain_color = tex2D( ProvinceColorMap, Input.uv ).rgb;
	
	if ( vAllSame < 1.0f && vUseMultisample < 8.0f )
	{
		float4 ColorRD = tex2Dlod( TerrainDiffuse, sample_terrain( IndexU.x, IndexV.x, vTileRepeat, vMipTexels, lod ) );
		float4 ColorLU = tex2Dlod( TerrainDiffuse, sample_terrain( IndexU.y, IndexV.y, vTileRepeat, vMipTexels, lod ) );
		float4 ColorRU = tex2Dlod( TerrainDiffuse, sample_terrain( IndexU.z, IndexV.z, vTileRepeat, vMipTexels, lod ) );

		float3 terrain_colorRD = tex2D( ProvinceColorMap, Input.uv + vOffsets.yx ).rgb;
		float3 terrain_colorLU = tex2D( ProvinceColorMap, Input.uv + vOffsets.xy ).rgb;
		float3 terrain_colorRU = tex2D( ProvinceColorMap, Input.uv + vOffsets.yy ).rgb;

		float2 vFrac = frac( Input.uv * 2048.0f - 0.5f );

		float vAlphaFactor = 10.0f;

		float4 vTest = float4( 
			vFrac.x + vFrac.x * ColorLU.a * vAlphaFactor, 
			(1.0f - vFrac.x) + (1.0f - vFrac.x) * ColorRU.a * vAlphaFactor, 
			vFrac.x + vFrac.x * sample.a * vAlphaFactor, 
			(1.0f - vFrac.x) + (1.0f - vFrac.x) * ColorRD.a * vAlphaFactor );

		float2 yWeights = float2( ( vTest.x + vTest.y ) * vFrac.y, ( vTest.z + vTest.w ) * ( 1.0f - vFrac.y ) );

		float3 vBlendFactors = float3( vTest.x / ( vTest.x + vTest.y ),
			vTest.z / ( vTest.z + vTest.w ),
			yWeights.x / ( yWeights.x + yWeights.y ) );

		sample = lerp( 
			lerp( ColorRU, ColorLU, vBlendFactors.x ),
			lerp( ColorRD, sample, vBlendFactors.y ), 
			vBlendFactors.z );
	}
	
	sample.rgb = GetOverlay( sample.rgb, tex2D( TerrainColorTint, Input.uv2 ), 0.5f );
	terrain_color.rgb = calculate_secondary( tex2D( ProvinceSecondaryColorMap, Input.uv ), terrain_color.rgb, Input.prepos.xz );

	
	float3 vOut = CalculateLighting( sample.rgb, normal );
	
	float2 vBlend = float2( 0.4f, 0.45f );
	vOut = ( dot(vOut, GREYIFY) * vBlend.x + terrain_color.rgb * vBlend.y );

	vOut = ApplyDistanceFog( vOut, Input.prepos, FoWTexture, FoWDiffuse );

	return float4( ComposeSpecular( vOut, 0.0f ), 1.0f );

}

technique TerrainNoVertexTexture
{
	pass p0
	{
		ZWriteEnable = True;
		ZEnable = True;
		ColorWriteEnable = RED|GREEN|BLUE;

		AlphaBlendEnable = False;
		AlphaTestEnable = False;
		CullMode = CW;

		VertexShader = compile vs_3_0 VertexShader_TerrainNoVertexTexture();
		PixelShader = compile ps_3_0 PixelShader_Terrain();
	}

	pass p1
	{
		ZWriteEnable = True;
		ZEnable = True;
		ColorWriteEnable = RED|GREEN|BLUE;

		AlphaBlendEnable = False;
		AlphaTestEnable = False;
		CullMode = CW;

		VertexShader = compile vs_3_0 VertexShader_TerrainNoVertexTexture();
		PixelShader = compile ps_3_0 PixelShader_TerrainColor();
	}

	pass p2
	{
		ZWriteEnable = True;
		ZEnable = True;
		ColorWriteEnable = RED|GREEN|BLUE;

		AlphaBlendEnable = False;
		AlphaTestEnable = False;
		CullMode = CW;

		VertexShader = compile vs_3_0 VertexShader_TerrainNoVertexTexture();
		PixelShader = compile ps_3_0 PixelShader_TerrainUnderwater();
	}
}



// --------------------------------------------------------------------------------------------
sampler2D BorderDiffuse = 
sampler_state 
{
    texture = <tex0>;
    AddressU = WRAP;
    AddressV = CLAMP;
    MIPFILTER = LINEAR;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
};

sampler2D BorderData = 
sampler_state 
{
    texture = <tex1>;
    AddressU = WRAP;
    AddressV = CLAMP;
    MIPFILTER = LINEAR;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
};

sampler2D BorderCornerDiffuse = 
sampler_state 
{
    texture = <tex2>;
    AddressU = WRAP;
    AddressV = CLAMP;
    MIPFILTER = LINEAR;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
};

sampler2D BorderCornerData = 
sampler_state 
{
    texture = <tex3>;
    AddressU = WRAP;
    AddressV = CLAMP;
    MIPFILTER = LINEAR;
    MINFILTER = LINEAR;
    MAGFILTER = LINEAR;
};



struct VS_INPUT_BORDER
{
    float3 position			: POSITION;
	float4 uv				: TEXCOORD0;
};

struct VS_OUTPUT_STENCILBORDER
{
    float4 position			: POSITION;
};

struct VS_OUTPUT_BORDER
{
    float4 position			: POSITION;
	float3 pos				: TEXCOORD0;
	float4 uv				: TEXCOORD1;
};

float4 vColorTint[6];
float2 vCorners;
float3 vBorderColor;

VS_OUTPUT_BORDER VertexShader_FlatBorder( const VS_INPUT_BORDER VertexIn )
{
	VS_OUTPUT_BORDER VertexOut = (VS_OUTPUT_BORDER)0;

	float4 pos = float4( VertexIn.position, 1.0f );

	float vClampHeight = saturate( ( WATER_HEIGHT - VertexIn.position.y ) * 10000 );

	pos.y = vClampHeight * WATER_HEIGHT + ( 1.0f - vClampHeight ) * pos.y;
	VertexOut.pos = pos.xyz;

	float4 vDistortedPos = pos - float4( vCamLookAtDir * 0.05f, 0.0f );
	pos = mul( pos, ViewProjectionMatrix );
	
	// move z value slightly closer to camera to avoid intersections with terrain
	float vNewZ = dot( vDistortedPos, ViewProjectionMatrix._m02_m12_m22_m32 );
	VertexOut.position = float4( pos.xy, vNewZ, pos.w );

	VertexOut.uv = VertexIn.uv;
	return VertexOut;
}

float BORDER_TILE = 1.0f / 7.0f; // 7 border types

float4 PixelShader_Border( VS_OUTPUT_BORDER Input ) : COLOR
{
	float4 color;
	float4 data;
	
	if ( Input.uv.z >= 0.999f )
	{
		color = tex2D( BorderCornerDiffuse, float2( ( frac( Input.uv.y ) + vCorners[0] ) * BORDER_TILE, Input.uv.x ) );
		data = tex2D( BorderCornerData, float2( ( frac( Input.uv.y ) + vCorners[0] ) * BORDER_TILE, Input.uv.x ) );
	}
	else if ( Input.uv.w >= 0.999f )
	{
		color = tex2D( BorderCornerDiffuse, float2( ( 1.0f - frac( Input.uv.y ) + vCorners[1] ) * BORDER_TILE, Input.uv.x ) );
		data = tex2D( BorderCornerData, float2( ( 1.0f - frac( Input.uv.y ) + vCorners[1] ) * BORDER_TILE, Input.uv.x ) );
	}
	else
	{
		color = tex2D( BorderDiffuse, float2( Input.uv.y * 0.1f, Input.uv.x ) );
		data = tex2D( BorderData, float2( Input.uv.y * 0.1f, Input.uv.x ) );
	}

	color.rgb += lerp( 
		data.r * vColorTint[0] + data.g * vColorTint[1] + data.b * vColorTint[2], 
		data.r * vColorTint[3] + data.g * vColorTint[4] + data.b * vColorTint[5], data.a );
	
	// remove by vColorTint alpha
	color.a *= lerp( vColorTint[0].a, vColorTint[3].a, data.a );

	float3 vExtraColor = vBorderColor * ( 1.0f - color.a ) * ( sin( vTime * 3.5f ) * 0.2f + 0.8f );
	color.rgb += vExtraColor;

	color.rgb = ApplyDistanceFog( color.rgb, Input.pos, FoWTexture, FoWDiffuse );
	
	return float4( ComposeSpecular( color.rgb, saturate( dot( vExtraColor, vExtraColor ) ) * 0.2f ), color.a );
}

technique Border
{
	pass p0
	{
		ZWriteEnable = False;
		ZEnable = True;
		ColorWriteEnable = RED|GREEN|BLUE;

		CullMode = CW;

		AlphaBlendEnable = True;
		AlphaTestEnable = False;

		VertexShader = compile vs_3_0 VertexShader_FlatBorder();
		PixelShader = compile ps_3_0 PixelShader_Border();
	}
}

// Sky /////////////////////////////////////////////

struct VS_INPUT_SKY
{
    float2 position			: POSITION;
};

struct VS_OUTPUT_SKY
{
    float4 position	: POSITION;
	float3 pos		: TEXCOORD0;
};


VS_OUTPUT_SKY VertexShader_Sky( const VS_INPUT_SKY VertexIn )
{
	VS_OUTPUT_SKY VertexOut = (VS_OUTPUT_SKY)0;

	VertexOut.position = float4( VertexIn.position, 1.0f, 1.0f );
	float4 position = mul( VertexOut.position, InvViewProjMatrix );
	position.xyz /= position.w;
	VertexOut.pos = position.xyz;

	return VertexOut;
}


float4 PixelShader_Sky( VS_OUTPUT_SKY Input ) : COLOR
{
	float3 color = texCUBE( ReflectionCubeMap, normalize( Input.pos - vCamPos ) ).rgb;
	float3 fog = ApplyDistanceFog( color.rgb, Input.pos );

	color = lerp( fog, color, saturate( Input.pos.y / 300.0f ) );
	return float4( ComposeSpecular( color, 0.0f ), 1.0f );
}


technique Sky
{
	pass p0
	{
		AlphaBlendEnable = False;
		AlphaTestEnable = False;
		ColorWriteEnable = RED|GREEN|BLUE;
		ZWriteEnable = False;

		VertexShader = compile vs_3_0 VertexShader_Sky();
		PixelShader = compile ps_3_0 PixelShader_Sky();
	}
}


