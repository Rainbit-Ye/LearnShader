Shader "Unlit/摆动集合"
{
    Properties
    {
        _MainTex ("RGB颜色，A透贴", 2D) = "white" {}
        _ScalePara("缩放系数 X 强度 Y 速度 Z 矫正",Vector) = (1,1,1,1)
        _SwingXPara("X轴平移系数 X 强度 Y 速度 Z 波长",Vector) = (1,1,1,1)
        _SwingZPara("Z轴平移系数 X 强度 Y 速度 Z 波长",Vector) = (1,1,1,1)
        _SwingYPara("Y轴平移系数 X 强度 Y 速度 Z 滞后",Vector) = (1,1,1,1)
        _ShakeYPara("Y轴旋转系数 X 强度 Y 速度 Z 滞后",Vector) = (1,1,1,1)
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
            //增加声明混合方式
            Blend One OneMinusSrcAlpha //Blend SrcAlpha OneMinusSrcAlpha
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #define TWO_PI 6.281 //定义宏
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
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

            vector _ScalePara;
            vector _SwingXPara;
            vector _SwingZPara;
            vector _SwingYPara;
            vector _ShakeYPara;
            float _Opacity;
            

            void Anim(inout float3 vertex, inout float4 color)
            {
                color = saturate(color);
                float3 scale = _ScalePara.x * color.g * sin(frac(_Time.z * _ScalePara.y) * TWO_PI);
                vertex.xyz *= 1.0 + scale;
                vertex.z -= _ScalePara.z * scale;

                vertex.x +=_SwingXPara.x  * sin(frac(_Time.z * color.r *_SwingXPara.y + vertex.z * _SwingXPara.z) * TWO_PI);
                vertex.y +=_SwingZPara.x * sin(frac(_Time.z * color.r * _SwingZPara.y + vertex.z * _SwingZPara.z) * TWO_PI);

                //使用旋转矩阵的方法进行计算,绕y轴
                float angle = radians(_ShakeYPara.x) * ( 1- color.r) * sin(frac(_Time.z * _ShakeYPara.y - color.g * _ShakeYPara.z) * TWO_PI);
                //进行角度转换为弧度
                //计算sin和cos
                float sinY,cosY = 0;
                sincos(angle,sinY,cosY);
                //旋转矩阵
                vertex.xy = float2(
                    vertex.x * cosY - vertex.y * sinY,
                    vertex.x * sinY + vertex.y * cosY
                    );

                vertex.z +=_SwingYPara.x  * sin(frac(_Time.z *_SwingYPara.y - color.g * _SwingYPara.z) * TWO_PI);
            }
            Varyings vert(Attributes input)
            {
                Varyings output;
                Anim(input.positionOS.xyz,input.color);
                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                
                output.positionCS = positionInputs.positionCS;
                output.positionWS = positionInputs.positionWS;
                
                output.uv = input.uv * _MainTex_ST.xy + _MainTex_ST.zw;
                output.color = input.color;
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                float4 mainTex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,input.uv);
                float opacity = _Opacity * mainTex.a;
                return float4(opacity * mainTex.xyz,opacity);
            }
            ENDHLSL
        }
    }
}
