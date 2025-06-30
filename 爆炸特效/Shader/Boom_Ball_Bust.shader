Shader "Boom/Ball/Bust"
{
    Properties
    {
        [Header(Mask)][Space(10)]
        [HDR]_MaskColor("蒙版下颜色",Color) = (1,1,1,1)
        _MaskTex("RGB:蒙版贴图",2D) = "black"{}
        _MaskInt("蒙版强度",Range(0,1)) = 1
        
        [Header(melt)][Space(10)]
        _MeltTex("RG:溶解纹理贴图 B:扰动噪声",2D) = "white" {}
        [HDR]_MeltLineColor("溶解边缘色",Color) = (1,1,1,1)
        _MeltWidth("溶解描边宽度",Range(0,0.5)) = 0.5
        
        _Opacity("透明度",Range(0,1)) = 0.5
        
        [Header(Setting)][Space(10)]
        _FlowSpeed("UV流动速度",Float) = 1
        _WarpInt("扰动强度",Range(0,1)) = 0.5

        
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
                float4 color : COLOR;
                float4 customData : TEXCOORD1;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float4 color : COLOR;
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
            float4 _MaskTex_ST;
            
            float4 _MaskColor;
            float4 _MeltLineColor;
            
            float _MaskInt;
            float _MeltWidth;
            float _Opacity;
            float _WarpInt;
            float _FlowSpeed;
            
            
            Varyings vert(Attributes input)
            {
                Varyings output;
                //Scale(input.positionOS,_ScaleParam.x,_ScaleParam.y);
                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                
                output.positionCS = positionInputs.positionCS;
                output.positionWS = positionInputs.positionWS;
                
                output.uv = input.uv * _MeltTex_ST.xy + _MeltTex_ST.zw;
                
                output.maskUV = input.uv * _MaskTex_ST.xy + _MaskTex_ST.zw;
                output.customData = input.customData;
                output.color = input.color;
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                float3 meltTex = SAMPLE_TEXTURE2D(_MeltTex,sampler_MeltTex,input.uv - 0.5);

                float warp = meltTex.b;
                float2 uvBis = (warp-0.5) * _WarpInt;
                uvBis.y = frac(_Time.x * _FlowSpeed);
                
                float4 maskTex = SAMPLE_TEXTURE2D(_MaskTex,sampler_MaskTex,input.maskUV + uvBis);
                
                float3 stepMeltTex = step(meltTex,input.customData.x);
                float edgeWidth = _MeltWidth * 0.1;
                float edge =  step(meltTex,input.customData.x + edgeWidth) - stepMeltTex;
                
                float3 maskRGB = lerp(input.color,_MaskColor * input.customData.y,maskTex * _MaskInt);

                float3 meltLineCol = _MeltLineColor * edge;
                float meltAlpha = lerp(_Opacity,0.0,stepMeltTex);
                
                //return warp;
                return float4((maskRGB + meltLineCol) * meltAlpha ,meltAlpha);
            }
            ENDHLSL
        }
    }
}
