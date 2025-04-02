texture tex0 < string name = "sdf"; >;	// Base texture
texture tex1 < string name = "sdf"; >;	// Base texture

float4x4 WorldViewProjectionMatrix; 
float4	 FlagCoords;

sampler BaseTexture  =
sampler_state
{
    Texture = <tex0>;
    MinFilter = Point;
    MagFilter = Point;
    MipFilter = None;
    AddressU = Wrap;
    AddressV = Wrap;
};

sampler MaskTexture  =
sampler_state
{
    Texture = <tex1>;
    MinFilter = Point;
    MagFilter = Point;
    MipFilter = None;
    AddressU = Wrap;
    AddressV = Wrap;
};

struct VS_INPUT
{
    float4 vPosition  : POSITION;
    float2 vTexCoord  : TEXCOORD0;
    float2 vMaskCoord  : TEXCOORD1;
};

struct VS_OUTPUT
{
    float4  vPosition : POSITION;
    float2  vTexCoord0 : TEXCOORD0;
    float2  vTexCoord1 : TEXCOORD1;
};


VS_OUTPUT GeneralVertexShader(const VS_INPUT v )
{
	VS_OUTPUT Out = (VS_OUTPUT)0;

	Out.vPosition  = mul(v.vPosition, WorldViewProjectionMatrix );

	Out.vTexCoord1 = v.vMaskCoord;

	Out.vTexCoord0.x = v.vTexCoord.x/FlagCoords.x;
	Out.vTexCoord0.x = Out.vTexCoord0.x + FlagCoords.z;
	Out.vTexCoord0.y = v.vTexCoord.y/FlagCoords.y;
	Out.vTexCoord0.y = Out.vTexCoord0.y + FlagCoords.w;

	

	return Out;
}

float4 GeneralPixelShader( VS_OUTPUT v ) : COLOR
{
	float4 OutColor = tex2D( BaseTexture, v.vTexCoord0.xy );
	OutColor -= tex2D( BaseTexture, v.vTexCoord0.xy-0.0009)*2.7f;
	OutColor += tex2D( BaseTexture, v.vTexCoord0.xy+0.0009)*2.7f;
	OutColor.rgb = ( OutColor.r*0.212671+OutColor.g*0.715160+OutColor.b*0.072169)/3.0f;
	OutColor.rgb *= float3( 3.0f, 1.0f, 1.0f );
	float4 MaskColor = tex2D( MaskTexture, v.vTexCoord1.xy );
	OutColor.a = MaskColor.a;
	
	return OutColor;
}

float4 PixelShaderOver( VS_OUTPUT v ) : COLOR
{
    float4 OutColor = tex2D( BaseTexture, v.vTexCoord0.xy );
	OutColor -= tex2D( BaseTexture, v.vTexCoord0.xy-0.0009)*2.7f;
	OutColor += tex2D( BaseTexture, v.vTexCoord0.xy+0.0009)*2.7f;
	OutColor.rgb = ( OutColor.r*0.212671+OutColor.g*0.715160+OutColor.b*0.072169)/3.0f;
	OutColor = dot( OutColor.rgb, float3( 1.0f, 0.2f, 0.2f ) );
    float4 MaskColor = tex2D( MaskTexture, v.vTexCoord1.xy );
    float4 MixColor = float4( 0.1, 0.1, 0.1, 0 );
    OutColor.a = MaskColor.a;
    OutColor += MixColor;
    
    return OutColor;
}

float4 PixelShaderDown( VS_OUTPUT v ) : COLOR
{
    float4 OutColor = tex2D( BaseTexture, v.vTexCoord0.xy );
	OutColor -= tex2D( BaseTexture, v.vTexCoord0.xy-0.0009)*2.7f;
	OutColor += tex2D( BaseTexture, v.vTexCoord0.xy+0.0009)*2.7f;
	OutColor.rgb = ( OutColor.r*0.212671+OutColor.g*0.715160+OutColor.b*0.072169)/3.0f;
	OutColor = dot( OutColor.rgb, float3( 1.0f, 0.2f, 0.2f ) );
    float4 MaskColor = tex2D( MaskTexture, v.vTexCoord1.xy );
    float4 MixColor = float4( 0.1, 0.1, 0.1, 0 );
    OutColor.a = MaskColor.a;
    OutColor -= MixColor;
    
    return OutColor;
}

float4 PixelShaderDisable( VS_OUTPUT v ) : COLOR
{
    float4 OutColor = tex2D( BaseTexture, v.vTexCoord0.xy );
    float4 MaskColor = tex2D( MaskTexture, v.vTexCoord1.xy );
    float Grey = dot( OutColor.rgb, float3( 0.212671f, 0.715160f, 0.072169f ) ); 
    
    OutColor.rgb = Grey;
    OutColor.a = MaskColor.a;
    
    return OutColor;
}

technique up
{
	pass p0
	{
		ALPHABLENDENABLE = True;

		VertexShader = compile vs_2_0 GeneralVertexShader();
		PixelShader = compile ps_2_0 GeneralPixelShader();
	}
}

technique down
{
	pass p0
	{
		ALPHABLENDENABLE = True;

		VertexShader = compile vs_2_0 GeneralVertexShader();
		PixelShader = compile ps_2_0 PixelShaderDown();
	}
}

technique over
{
	pass p0
	{
		ALPHABLENDENABLE = True;

		VertexShader = compile vs_2_0 GeneralVertexShader();
		PixelShader = compile ps_2_0 PixelShaderOver();
	}
}

technique disable
{
	pass p0
	{
		ALPHABLENDENABLE = True;

		VertexShader = compile vs_2_0 GeneralVertexShader();
		PixelShader = compile ps_2_0 PixelShaderDisable();
	}
}