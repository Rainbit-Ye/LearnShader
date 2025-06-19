Shader "Shader Graphs/cubemap"
{
    Properties
    {
        _FresnelPow("菲涅尔强度", Range(0, 1)) = 0
        _EnvIntensity("环境整体强度", Range(0, 1)) = 0
        _MipLevel("mipmap", Range(0, 8)) = 0
        _NormalStrength("法线强度", Float) = 0
        [NoScaleOffset]_Cubemap("Cubemap", CUBE) = "gray" {}
        [NoScaleOffset]_NormalTex("法线贴图", 2D) = "bump" {}
    }

    SubShader
    {
        Tags{"RenderType"="Opaque"}

        Pass
        {
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float4 tangentWS : TEXCOORD2;
                float2 uv : TEXCOORD3;
            };
            TEXTURE2D(_NormalTex);
            SAMPLER(sampler_NormalTex);
            TEXTURECUBE(_Cubemap);
            SAMPLER(sampler_Cubemap);
            
            float _FresnelPow;
            float _EnvIntensity;
            float _MipLevel;
            float _NormalStrength;

            Varyings vert(Attributes input)
            {
                Varyings output;
                
                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                
                output.positionCS = positionInputs.positionCS;
                output.positionWS = positionInputs.positionWS;
                output.normalWS = normalInputs.normalWS;
                output.tangentWS = float4(normalInputs.tangentWS.xyz, input.tangentOS.w);
                output.uv = input.uv;
                
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                // 准备向量
                float3 viewDirWS = GetCameraPositionWS();
                viewDirWS = normalize(viewDirWS - input.positionWS);
                // 采样法线贴图
                float3 normalTS = UnpackNormal(SAMPLE_TEXTURE2D(_NormalTex,sampler_NormalTex,input.uv));
                //计算发现强度
                normalTS.xy *= _NormalStrength;
                normalTS = normalize(normalTS);
                
                // 构建TBN矩阵
                float3 bitangentWS = cross(input.normalWS, input.tangentWS.xyz) * (input.tangentWS.w);
                float3x3 TBN = float3x3(input.tangentWS.xyz, bitangentWS, input.normalWS);
                float3 normalWS = normalize(mul(normalTS, TBN));
                
                // 计算反射向量
                float3 reflectDir = reflect(-viewDirWS, normalWS);
                
                // 采样环境贴图
                float4 envColor = SAMPLE_TEXTURECUBE_LOD(_Cubemap, sampler_Cubemap, reflectDir, _MipLevel);
                
                // 菲涅尔效果
                float fresnel = pow(1.0 - saturate(dot(normalWS, viewDirWS)), _FresnelPow);
                
                // 最终颜色
                half4 color = envColor * fresnel * _EnvIntensity;
                return color;
            }
            ENDHLSL
        }
    }
}
