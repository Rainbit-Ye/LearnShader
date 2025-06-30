Shader "Boom/Demo"
{
    Properties
    {
        [Header(Mask)][Space(10)]
        [HDR]_MaskColorA("表面颜色",Color) = (1,1,1,1)
        [HDR]_MaskColorB("蒙版下颜色",Color) = (1,1,1,1)
        _MaskTex("蒙版贴图",2D) = "black"{}
        _MaskInt("蒙版强度",Range(0,1)) = 1
        
        [Header(melt)][Space(10)]
        _MeltTex("溶解纹理贴图",2D) = "white" {}
        [HDR]_MeltColorA("溶解表面颜色",Color) = (1,1,1,1)
        [HDR]_MeltColorB("溶解后颜色",Color) = (1,1,1,1)
        [HDR]_MeltLineColor("溶解边缘色",Color) = (1,1,1,1)
        [PowerSlider(0.5)]_StepInt("溶解幅度",Range(0,1)) = 0.5
        _MeltWidth("溶解描边宽度",Range(0,0.5)) = 0.5
        
        _Opacity("透明度",Range(0,1)) = 0.5
        
        [Header(Setting)][Space(10)]
        _TranslateParam("平移参数 X：平移幅度 Y：平移速度", Vector) = (0,0,0,0)
        _RotateParam("旋转参数 X：旋转幅度 Y：旋转速度", Vector) = (0,0,0,0)
        _ScaleParam("缩放参数 X：缩放幅度 Y：缩放速度", Vector) = (0,0,0,0)
        
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
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float2 uv : TEXCOORD1;
                float2 maskUV : TEXCOORD2;
            };
            TEXTURE2D(_MeltTex);
            SAMPLER(sampler_MeltTex);
            float4 _MeltTex_ST;

            TEXTURE2D(_MaskTex);
            SAMPLER(sampler_MaskTex);
            
            TEXTURE2D(_MainTexB);
            SAMPLER(sampler_MainTexB);

            float4 _MaskColorA;
            float4 _MaskColorB;
            float4 _MeltLineColor;
            float4 _TranslateParam;
            float4 _RotateParam;
            float4 _ScaleParam;
            
            
            
            float _MaskInt;
            float _StepInt;
            float _MeltWidth;
            float _Opacity;

            //输入平移轴
            void Translate(inout float vertex, float transDis, float transSpeed)
            {
                vertex.x +=transDis * sin(frac(_Time.z * transSpeed) * TWO_PI);
            }

            void Scale(inout float4 vertex, float scale, float scaleSpeed)
            {
                vertex.xyz *= 1.0 + scale * sin(frac(_Time.z * scaleSpeed) * TWO_PI);
            }
            
            //输入除旋转轴外的两个轴
            void Rotate(inout float2 vertex,float rotata, float rotateSpeed)
            {
                //使用旋转矩阵的方法进行计算,绕y轴
                float angle =rotata * sin(frac(_Time.z * rotateSpeed) * TWO_PI);

                //进行角度转换为弧度
                float r = radians(angle);
                //计算sin和cos
                float sin,cos = 0;
                sincos(r,sin,cos);
                //旋转矩阵
                vertex.xy = float2(
                    vertex.x * cos - vertex.y * sin,
                    vertex.x * sin + vertex.y * cos
                    );
            }
            
            Varyings vert(Attributes input)
            {
                Varyings output;
                Translate(input.positionOS.y,_TranslateParam.x,_TranslateParam.y);
                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                
                output.positionCS = positionInputs.positionCS;
                output.positionWS = positionInputs.positionWS;
                
                output.uv = input.uv * _MeltTex_ST.xy + _MeltTex_ST.zw;
                
                output.maskUV = input.uv;
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                float4 maskTex = SAMPLE_TEXTURE2D(_MaskTex,sampler_MaskTex,input.maskUV);
                float3 meltTex = SAMPLE_TEXTURE2D(_MeltTex,sampler_MeltTex,input.uv-0.5);

                float3 stepMeltTex = step(meltTex,_StepInt);
                float edgeWidth = _MeltWidth * 0.1;
                float edge =  step(meltTex,_StepInt + edgeWidth) - stepMeltTex;
                
                float3 maskRGB = lerp(_MaskColorA,_MaskColorB,maskTex * _MaskInt);

                float3 meltLineCol = _MeltLineColor * edge;
                float meltAlpha = lerp(_Opacity * maskTex.a,0.0,stepMeltTex);
                
                
                return float4((maskRGB + meltLineCol) * meltAlpha,meltAlpha);
            }
            ENDHLSL
        }
    }
}
