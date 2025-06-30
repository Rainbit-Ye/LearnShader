Shader "Unlit/UVFlow"
{
    Properties
    {
        _MainTex ("RGB颜色，A透贴", 2D) = "white" {}
        _Noise("流动噪声UV",2D) = "white"{}
        _Opacity("透明阈值",Range(0,1)) = 0.5
        _NoiseInt("噪声流动强度",Float) = 1
        _FlowSpeed("UV流动速度",Float) = 1
        
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
                float2 uv1 : TEXCOORD1;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float2 uv : TEXCOORD1;
                float2 uv1 : TEXCOORD2;
            };
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;
            TEXTURE2D(_Noise);
            SAMPLER(sampler_Noise);
            float4 _Noise_ST;

            float _Opacity;
            float _NoiseInt;
            float _FlowSpeed;

            Varyings vert(Attributes input)
            {
                Varyings output;
                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                
                output.positionCS = positionInputs.positionCS;
                output.positionWS = positionInputs.positionWS;
                
                output.uv = input.uv * _MainTex_ST.xy + _MainTex_ST.zw;
                output.uv1 = input.uv1 * _Noise_ST.xy + _Noise_ST.zw;
                output.uv1.y = output.uv1.y + frac(_Time.x * _FlowSpeed);
                
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                float4 mainTex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,input.uv);
                float noiseTex = SAMPLE_TEXTURE2D(_Noise,sampler_Noise,input.uv1).r;
                
                float noise = lerp(1.0,noiseTex * 2,_NoiseInt);
                noise = max(0.0,noise);
                float opacity = mainTex.a * _Opacity * noise;
                
                return float4(mainTex.rgb * opacity,opacity);
            }
            ENDHLSL
        }
    }
}
