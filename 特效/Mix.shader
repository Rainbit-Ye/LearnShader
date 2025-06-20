Shader "Unlit/Mix"
{
    Properties
    {
        _MainTex ("RGB颜色，A透贴", 2D) = "white" {}
        [Enum(UnityEngine.Rendering.BlendMode)]
        _BlendSrc("源乘子",int) = 0
        [Enum(UnityEngine.Rendering.BlendMode)]
        _BlendDst("目标乘子",int) = 0
        [Enum(UnityEngine.Rendering.BlendOp)]
        _BlendOp("混合运算符",int) = 0
        
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
            //增加声明混合方式
            BlendOp [_BlendOp]
            Blend [_BlendSrc] [_BlendDst] //构建选择
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
                return mainTex;
            }
            ENDHLSL
        }
    }
}
