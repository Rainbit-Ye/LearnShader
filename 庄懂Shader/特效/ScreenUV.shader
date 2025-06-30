Shader "Unlit/ScreenUV"
{
    Properties
    {
        _MainTex ("RGB颜色，A透贴", 2D) = "white" {}
        _WarpTex("RG:扰动 B：噪声",2D) = "white"{}
        _Opacity("透明阈值",Range(0,5)) = 1
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
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD1;
                float2 screenUV : TEXCOORD2;
            };
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            TEXTURE2D(_WarpTex);
            SAMPLER(sampler_WarpTex);
            float4 _WarpTex_ST;

            float _Opacity;

            Varyings vert(Attributes input)
            {
                Varyings output;
                
                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                VertexPositionInputs positionOri = GetVertexPositionInputs(float3(0,0,0));
                output.positionCS = positionInputs.positionCS;
                //转换到视口空间
                float3 positionVS = positionInputs.positionVS;
                //相机看到的uv作为视屏幕uv,并且除以深度，防止扰动
                output.screenUV = positionVS.xy / positionVS.z;
                //将原点作为 取模型原点到相机距离，防止畸变锁定纹理大小
                float originVS = positionOri.positionVS.z;
                output.screenUV *= originVS;
                
                output.screenUV = output.screenUV * _WarpTex_ST.xy -frac(_Time.x * _WarpTex_ST.zw);
                output.uv = input.uv;
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                float4 mainTex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,input.uv);
                float3 warptex = SAMPLE_TEXTURE2D(_WarpTex,sampler_WarpTex,input.screenUV);
                float noise = warptex.b;

                float opacity = noise * mainTex.a * _Opacity;
                return float4(mainTex.rgb * opacity,opacity);
            }
            ENDHLSL
        }
    }
}
