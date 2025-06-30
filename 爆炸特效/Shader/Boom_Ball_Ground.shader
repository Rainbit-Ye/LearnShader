Shader "Boom/Ball/Ground"
{
    Properties
    {
        [Header(Mask)][Space(10)]
        [HDR]_MaskColorA("表面颜色",Color) = (1,1,1,1)
        _MaskTex("蒙版贴图",2D) = "black"{}
        
        [Header(melt)][Space(10)]
        _MeltTex("花纹贴图",2D) = "white" {}
        [HDR]_MaskColorB("花纹颜色",Color) = (1,1,1,1)
        [HDR]_MeltLineColor("计时边缘色",Color) = (1,1,1,1)
        _MeltWidth("计时边宽度",Range(0,0.5)) = 0.5
        _Opacity("透明阈值",Range(0,1)) = 0.5
        
    }
    SubShader
    {
        Tags{
            "Queue" = "Transparent"//指定渲染队列
            "RenderType"="TransparentCutout"//更改渲染队列
            "ForceNoShadowCasting"= "True"//表示关闭投影
            "IgnoreProjector" = "True"//表示不响应投射器
        }

        Pass
        {
            ZWrite off
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
                float4 customData : TEXCOORD1;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float4 customData : TEXCOORD1;
                float2 uv : TEXCOORD2;
                float2 maskUV : TEXCOORD3;
                
            };
            TEXTURE2D(_MeltTex);
            SAMPLER(sampler_MeltTex);
            float4 _MeltTex_ST;

            TEXTURE2D(_MaskTex);
            SAMPLER(sampler_MaskTex);
            

            float4 _MaskColorA;
            float4 _MaskColorB;
            float4 _MeltLineColor;
            
            float _MeltWidth;
            float _Opacity;
            
            Varyings vert(Attributes input)
            {
                Varyings output;
                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                
                output.positionCS = positionInputs.positionCS;
                output.positionWS = positionInputs.positionWS;
                
                output.uv = input.uv * _MeltTex_ST.xy + _MeltTex_ST.zw;
                
                output.maskUV = input.uv;
                output.customData = input.customData;
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                float4 maskTex = SAMPLE_TEXTURE2D(_MaskTex,sampler_MaskTex,input.maskUV);
                float4 meltTex = SAMPLE_TEXTURE2D(_MeltTex,sampler_MeltTex,input.uv);

                float stepMeltTex = step(meltTex.r,input.customData.x);

                float edgeWidth = _MeltWidth * 0.1;
                float edge = step(meltTex.r,input.customData.x + edgeWidth) - stepMeltTex;

                float3 maskRGB = lerp(_MaskColorA * input.customData.y,_MaskColorB * input.customData.y,meltTex);
                float3 meltLineCol = _MeltLineColor * edge;
                
                float3 finalRGB = (meltLineCol + maskRGB);
                float finalA = max(maskTex.a * _Opacity, meltTex.a);  // Use whichever alpha is stronger

                return float4(finalRGB * finalA, finalA);
            }
            ENDHLSL
        }
    }
}
