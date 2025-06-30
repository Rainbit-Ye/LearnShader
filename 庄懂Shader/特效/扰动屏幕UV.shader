Shader "Unlit/扰动屏幕UV"
{
    Properties
    {
        _MainTex ("RGB颜色，A透贴", 2D) = "white" {}
        _Opacity("透明阈值",Range(0,5)) = 1
        _WarpMidVal("扭曲中值",Range(0,10))=5
        _Warpint("扭曲强度",Range(0,1)) = 0.5
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
                float2 uv : TEXCOORD0;
                float4 screenUV : TEXCOORD1;
            };
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            //这里替代urp中不支持的GrabPass，可以用 renderer feature获取，这里就不折腾了
            TEXTURE2D(_CameraOpaqueTexture);
            SAMPLER(sampler_CameraOpaqueTexture);

            float _Opacity;
            float _WarpMidVal;
            float _Warpint;

            Varyings vert(Attributes input)
            {
                Varyings output;
                
                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS = positionInputs.positionCS;
                
                output.screenUV = ComputeScreenPos(output.positionCS);
                output.uv = input.uv;
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                float4 mainTex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,input.uv);
                //获取屏幕的RT的UV进行偏移扰动，不透明就不扰动
                input.screenUV.xy += (mainTex.r - _WarpMidVal) * _Opacity * _Warpint;
                float3 warptex = SAMPLE_TEXTURE2D(_CameraOpaqueTexture,sampler_CameraOpaqueTexture,input.screenUV);
                //正片叠底
                float3 finalRGB = warptex * mainTex.rgb;
                float opacity = mainTex.a * _Opacity;
                return float4(finalRGB * opacity ,opacity);
            }
            ENDHLSL
        }
    }
}
