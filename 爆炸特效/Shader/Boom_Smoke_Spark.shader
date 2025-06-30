Shader "Boom/Smoke/Spark"
{
    Properties
    {
        _MainTex("主纹理贴图",2D) = "white" {}
        _Clip("透明度",Range(0,1)) = 1
        _HDRInt("HDR强度",Float) = 1
    }

    SubShader
    {
        Tags { 
            "RenderType"="Transparent" 
            "Queue"="Transparent"
        }

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            float _Clip;
            float _HDRInt;
       
            Varyings vert(Attributes input)
            {
                Varyings output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = input.uv;
                output.color = input.color * _HDRInt * 10;
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                float4 mainTex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,input.uv);
                //return float4(stepMeltTex.xxxx);
                float alpha = mainTex.a * _Clip;
                float4 colTex = mainTex * input.color;
                
                return float4(colTex.rgb * alpha,alpha);
            }
            ENDHLSL
        }
    }
}