Shader "Unlit/AD"
{
    Properties
    {
        _MainTex ("RGB颜色，A透明", 2D) = "white" {}
        _Cutoff ("透明阈值",Float) = 1
    }
    SubShader
    {
        Tags{
            "Queue" = "Transparent"//指定渲染队列
            "RenderType"="TransparentCutout"//更改渲染队列
            "ForceNoShadowCasting"= "True"//表示关闭投影
            "IgnoreProject" = "True"//表示不响应投射器
        }

        Pass
        {
            Blend One One
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float2 uv : TEXCOORD1;
            };
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;
            
            float _Cutoff;

            Varyings vert(Attributes input)
            {
                Varyings output;
                
                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                
                output.positionCS = positionInputs.positionCS;
                output.positionWS = positionInputs.positionWS;
                
                output.uv = input.uv * _MainTex_ST.xy + _MainTex_ST.zw;
                
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                float4 mainTex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,input.uv);
                half opacity = mainTex.a;
                clip(opacity-_Cutoff);
                return float4(mainTex.rgb,1);
            }
            ENDHLSL
        }
    }
}
