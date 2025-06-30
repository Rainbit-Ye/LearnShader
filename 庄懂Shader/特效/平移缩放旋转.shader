Shader "Unlit/平移"
{
    Properties
    {
        _MainTex ("RGB颜色，A透贴", 2D) = "white" {}
        _TransDis("平移范围",float) = 2
        _TransSpeed("平移速度",Float) = 1
        _Scale("缩放系数",Float) = 1
        _ScaleSpeed("缩放速度",Float) = 1
        _Rotate("旋转系数",Float) = 1
        _RotateSpeed("旋转速度",Float) = 1
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
            #define TWO_PI 6.28 //定义宏
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

            float _TransDis;
            float _TransSpeed;
            float _Scale;
            float _ScaleSpeed;
            float _Rotate;
            float _RotateSpeed;

            void Translate(inout float4 vertex)
            {
                vertex.y +=_TransDis * sin(frac(_Time.z * _TransSpeed) * TWO_PI);
            }

            void Scale(inout float4 vertex)
            {
                vertex.xyz *= 1.0 + _Scale * sin(frac(_Time.z * _ScaleSpeed) * TWO_PI);
            }

            void Rotate(inout float4 vertex)
            {
                //使用旋转矩阵的方法进行计算,绕y轴
                float angle =_Rotate * sin(frac(_Time.z * _RotateSpeed) * TWO_PI);

                //进行角度转换为弧度
                float r = radians(angle);
                //计算sin和cos
                float sin,cos = 0;
                sincos(r,sin,cos);
                //旋转矩阵
                vertex.xz = float2(
                    vertex.x * cos - vertex.z * sin,
                    vertex.x * sin + vertex.z * cos
                    );
            }
            Varyings vert(Attributes input)
            {
                Varyings output;
                Rotate(input.positionOS);
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
