Shader "Unlit/极坐标缩放"
{
    Properties
    {
        _MainTex ("RGB颜色，A透明", 2D) = "white" {}
        _Opacity ("透明度",Range(0,1)) = 1
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
            Name "Forward_AB"
            Tags {"LightMode" = "SRPDefaultUnlit"}
            //增加声明混合方式
            Blend One OneMinusSrcAlpha //Blend SrcAlpha OneMinusSrcAlpha
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;//顶点着色
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float2 uv : TEXCOORD1;
                float4 color : COLOR;
            };
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;
            
            float _Opacity;

            //做线性插值
            Varyings vert(Attributes input)
            {
                Varyings output;
                
                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS = positionInputs.positionCS;
                output.positionWS = positionInputs.positionWS;
                
                output.uv = input.uv;
                output.color = input.color;
                
                return output;
            }

            //顶点色混合在这里进行
            half4 frag(Varyings input) : SV_Target
            {
                //极坐标计算
                input.uv = input.uv -0.5;//将uv的原点坐标从左下角移动到图片中心
                /*float theta = atan2(input.uv.y,input.uv.x);//atan返回的是-二分之Π到二分之Π，atan2返回的是-Π到Π

                theta = theta /3.1415926 * 0.5 + 0.5;*/

                float thetaApprox = (input.uv.y / (abs(input.uv.x) + abs(input.uv.y) + 0.0001)) * 0.5 + 0.5;
                float r = length(input.uv)+frac(_Time.x * 3);
                input.uv = float2(thetaApprox,r);

                float4 mainTex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,input.uv);
                float3 finaRGB = mainTex.rgb;
                //在顶点上进行颜色设置，就可以实现渐入渐出
                float opacity = mainTex.a * _Opacity * input.color.r;
                //return  opacity;
                return float4(finaRGB * opacity,opacity);
            }
            ENDHLSL
        }
    }
}
