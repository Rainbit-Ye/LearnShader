Shader "Unlit/Sequence"
{
    Properties
    {
        _MainTex ("RGB颜色，A透贴", 2D) = "white" {}
        _Opacity ("透明度",Range(0,1)) = 1
        _Sequence("序列帧",2D) = "gray"{}
        _RowCount("行数",int) = 1
        _ColCount("列数",int) = 1
        _Speed("速度",Range(0,10)) = 1
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

        Pass
        {
            Name "Forward_AD"
            Tags {"LightMode" = "UniversalForward"}
            Blend One One
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float2 uv : TEXCOORD1;
            };
            
            TEXTURE2D(_Sequence);
            SAMPLER(sampler_Sequence);
            float4 _Sequence_ST;
            
            float _RowCount;
            float _ColCount;
            float _Speed;
            

            Varyings vert(Attributes input)
            {
                Varyings output;
                input.positionOS.xyz += input.normal * 0.0005;
                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS = positionInputs.positionCS;
                output.positionWS = positionInputs.positionWS;

                output.uv = input.uv * _Sequence_ST.xy + _Sequence_ST.zw;

                float id = floor(_Time.y * _Speed);
                float idv = floor(id / _ColCount);//向下取整,算出作为的列数
                float idu = id - idv * _ColCount;//算出行数

                //计算列的步幅,一般在面板封装住
                float stepU = 1.0 / _ColCount;
                //计算行的步幅
                float stepV = 1.0 / _RowCount;
                //缩小+把最开始的uv放到左上角去
                float2 initUV = output.uv * float2(stepU,stepV) + float2(0.0,stepV * (_RowCount - 1));
                //计算偏移
                output.uv = initUV + float2(idu * stepU,-idv * stepV);
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                float4 sequTex = SAMPLE_TEXTURE2D(_Sequence,sampler_Sequence,input.uv);
                return float4(sequTex.xyz,1);
            }
            ENDHLSL
        }
    }
}
