
float4x4 WorldViewProjectionMatrix;

struct VS_INPUT
{
    float4 vPosition	: POSITION;
    float4 vColor		: COLOR;
};

struct VS_OUTPUT
{
    float4  vPosition : POSITION;
	float4  vColor	  : TEXCOORD0;
};

VS_OUTPUT VertexShader_DebugLines(const VS_INPUT In )
{
    VS_OUTPUT Out = (VS_OUTPUT)0;
	
    Out.vPosition  	= mul( In.vPosition, WorldViewProjectionMatrix );
	Out.vColor		= In.vColor;
    return Out;
}

float4 PixelShader_DebugLines( VS_OUTPUT In ) : COLOR
{
    return In.vColor;
}

technique tec0
{
	pass p0
	{
		AlphaBlendEnable = True;
		AlphaTestEnable = False;
		ZWriteEnable = True;
		ZEnable = False;
		ColorWriteEnable = RED|GREEN|BLUE;
		CullMode = NONE;

		VertexShader = compile vs_2_0 VertexShader_DebugLines();
		PixelShader = compile ps_2_0 PixelShader_DebugLines();
	}
}
