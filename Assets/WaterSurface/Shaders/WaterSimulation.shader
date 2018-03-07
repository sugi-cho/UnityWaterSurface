Shader "Water/Simulation"
{

Properties
{
    _S2("PhaseVelocity^2", Range(0.0, 0.5)) = 0.2
    [PowerSlider(0.01)]
    _Atten("Attenuation", Range(0.0, 1.0)) = 0.999
    _DeltaUV("Delta UV", Float) = 3

	_Obstacle("Obstacle Tex", 2D) = "black"{}
	_Flow("Flow Tex", 2D) = "black"{}
	_Rain("Rain",2D) = "black"{}
}

CGINCLUDE

#include "UnityCustomRenderTexture.cginc"

half _S2;
half _Atten;
float _DeltaUV;
sampler2D _Obstacle, _Flow, _Rain;

float4 frag(v2f_customrendertexture i) : SV_Target
{
    float2 uv = i.globalTexcoord;

    float du = 1.0 / _CustomRenderTextureWidth;
    float dv = 1.0 / _CustomRenderTextureHeight;
    float3 duv = float3(du, dv, 0) * _DeltaUV;

    float2 c = tex2D(_SelfTexture2D, uv + duv.xz*0);
	float o = tex2D(_Obstacle, uv).r;

	float o0 = tex2D(_Obstacle, uv - duv.zy).r;
	float o1 = tex2D(_Obstacle, uv + duv.zy).r;
	float o2 = tex2D(_Obstacle, uv - duv.xz).r;
	float o3 = tex2D(_Obstacle, uv + duv.xz).r;

	float v0 = tex2D(_SelfTexture2D, uv - duv.zy).r * (sign(0.5 - o0) - o0*2);
	float v1 = tex2D(_SelfTexture2D, uv + duv.zy).r * (sign(0.5 - o1) - o1*2);
	float v2 = tex2D(_SelfTexture2D, uv - duv.xz).r * (sign(0.5 - o2) - o2*2);
	float v3 = tex2D(_SelfTexture2D, uv + duv.xz).r * (sign(0.5 - o3) - o3*2);
	float p = (2 * c.r - c.g + _S2 * (v0 + v1 + v2 + v3 - 4 * c.r)) * _Atten;
	p *= 0 == o;

	half rain = tex2D(_Rain, uv).r;

	p -= rain;
    return float4(p, c.r, 0, 0);
}

float4 frag_left_click(v2f_customrendertexture i) : SV_Target
{
	float2 c = tex2D(_SelfTexture2D, i.globalTexcoord);
	c.r -= 1;
	return float4(c, 0, 0);
}

float4 frag_right_click(v2f_customrendertexture i) : SV_Target
{
	float2 c = tex2D(_SelfTexture2D, i.globalTexcoord);
	c.r += 1;
	return float4(c, 0, 0);
}

ENDCG

SubShader
{
    Cull Off ZWrite Off ZTest Always

    Pass
    {
        Name "Update"
        CGPROGRAM
        #pragma vertex CustomRenderTextureVertexShader
        #pragma fragment frag
        ENDCG
    }

    Pass
    {
        Name "LeftClick"
        CGPROGRAM
        #pragma vertex CustomRenderTextureVertexShader
        #pragma fragment frag_left_click
        ENDCG
    }

    Pass
    {
        Name "LeftClick"
        CGPROGRAM
        #pragma vertex CustomRenderTextureVertexShader
        #pragma fragment frag_right_click
        ENDCG
    }
}

}