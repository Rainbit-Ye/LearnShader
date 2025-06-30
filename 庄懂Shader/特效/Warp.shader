Shader "Unlit/UVFlow"
{
    Properties
    {
        _MainTex ("RGB颜色，A透贴", 2D) = "white" {}
        _WarpTex("流动噪声UV",2D) = "white"{}
        _Opacity("透明阈值",Range(0,5)) = 0.5
        _NoiseInt("噪声流动强度",Float) = 1
        _FlowSpeed("UV流动速度",Float) = 1
        _WarpInt("扭曲强度",Float) = 1
        
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
                float2 uv : TEXCOORD1;//给主贴图采样
                float2 uv1 : TEXCOORD2;//给扰动采样
            };
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            
            TEXTURE2D(_WarpTex);
            SAMPLER(sampler_WarpTex);
            float4 _WarpTex_ST;

            float _Opacity;
            float _NoiseInt;
            float _FlowSpeed;
            float _WarpInt;

            Varyings vert(Attributes input)
            {
                Varyings output;
                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                
                output.positionCS = positionInputs.positionCS;
                output.positionWS = positionInputs.positionWS;
                
                output.uv = input.uv;
                output.uv1 = input.uv * _WarpTex_ST.xy + _WarpTex_ST.zw;//流动
                output.uv1.y = output.uv1.y + frac(_Time.x * _FlowSpeed);
                
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                //先采出一张贴图，对uv进行操作之后，再用操作过的uv去采样另外一张
                float3 warpTex = SAMPLE_TEXTURE2D(_WarpTex,sampler_WarpTex,input.uv1).rgb;
                //计算UV偏移量，由于原先的法线uv是 （0-1）会产生一个方向的移动，因此采用-0。5保证左右扰动偏移
                float2 uvBis = (warpTex.rg-0.5) * _WarpInt;
                float2 uv = input.uv + uvBis;

                float4 mainTex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,uv);
                float noise = lerp(1.0,warpTex.b * 2,_NoiseInt);
                noise = max(0.0,noise);
                float opacity = mainTex.a * _Opacity * noise;
                
                return float4(mainTex.rgb ,opacity);
            }
            ENDHLSL
        }
    }
}
