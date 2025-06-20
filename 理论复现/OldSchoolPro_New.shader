Shader "Unlit/OldSchoolPro"
{
    Properties
    {
        [Header(texture)]
        _MainTex("主贴图",2D) = ""{}
        _NormalTex("法线贴图",2D) = "" {}
        _Emission("自发光贴图",2D) = "white"{}
        _SpecTex("高光贴图",2D) = ""{}
        _Cubemap("Cubemap",Cube) = ""{}
        
        
        [Header(Color)]
        _SkyColor("天空散射颜色",Color) = (1,1,1,1)
        _GroundColor("地面散射颜色",Color) = (1,1,1,1)
        _EnvColor("环境散射颜色",Color) = (1,1,1,1)
        _BaseColor("基础色",Color) = (1,1,1,1)
        _SpecColor("高光颜色",Color) = (1,1,1,1)
        
        [Header(Slider)]
        _FresnelPow("菲涅尔强度",Range(0,5)) = 2.5
        _EnvSpecInt("环境整体光亮强度",Range(0,1)) = 0.5
        _NormalStrength("法线强度",Range(0,1)) = 0.5
        _3ColStrength("环境散射强度",Range(0,1)) = 0.5
        _EmissionStrength("自发光强度",Range(0,50)) = 0.5
        _MapMipStrength("MapMip强度",Range(0,7)) = 1
        _SpecPow("高光强度",Range(1,100)) = 1
        _DiffInt("环境光漫反射强度",Range(0,5)) = 1
    }
    SubShader
    { 
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            #include "DiffEnv.hlsl"
            
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
            
            struct Attributes 
            {
                float4 vertex : POSITION;
                float4 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv : TEXCOORD0;
            };

            struct Varyings 
            {
                float4 posCS : SV_POSITION;//由模型信息换算来的顶点屏幕信息
                float3 posWS : TEXCOORD1;
                float3 nDirWS : TEXCOORD2;
                float4 tDirWS : TEXCOORD3;
                float2 uv : TEXCOORD0;
            };

            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;//偏移和缩放
            
            TEXTURE2D(_NormalTex);
            SAMPLER(sampler_NormalTex);
            TEXTURE2D(_Emission);
            SAMPLER(sampler_Emission);
            TEXTURE2D(_SpecTex);
            SAMPLER(sampler_SpecTex);
            TEXTURECUBE(_Cubemap);
            SAMPLER(sampler_Cubemap);
            
            
            float4 _SkyColor;
            float4 _GroundColor;
            float4 _EnvColor;
            float4 _BaseColor;
            float4 _SpecColor;
            
            float _FresnelPow;
            float _EnvSpecInt;
            float _NormalStrength;
            float _3ColStrength;
            float _EmissionStrength;
            float _MapMipStrength;
            float _SpecPow;
            float _DiffInt;

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                VertexPositionInputs positionInput = GetVertexPositionInputs(IN.vertex.xyz); 
                VertexNormalInputs normalInputs = GetVertexNormalInputs(IN.normal,IN.tangent);
                OUT.posCS = positionInput.positionCS;
                OUT.posWS = positionInput.positionWS;
                OUT.nDirWS = normalInputs.normalWS;
                OUT.tDirWS = float4(normalInputs.tangentWS.xyz, IN.tangent.w);
                OUT.uv = IN.uv; // * _MainTex_ST.xy + _MainTex_ST.zw;
                return OUT;
            }

            float4 frag (Varyings i) : SV_Target
            {
                //准备
                Light light = GetMainLight();
                Light shadow = GetMainLight(TransformWorldToShadowCoord(i.posWS));
                float3 iDirWS = light.direction;

                float3 cameraDir = GetCameraPositionWS();
                float3 vDirWS = normalize(cameraDir - i.posWS);
                float3 irDirWS = normalize(reflect(-iDirWS,i.nDirWS));
                
                
                float3 bDirWS = normalize(cross(i.nDirWS,i.tDirWS) * i.tDirWS.w);
                float3x3 TBN = float3x3(i.tDirWS.xyz,bDirWS,i.nDirWS.xyz);
                float3 normalTS = UnpackNormal(SAMPLE_TEXTURE2D(_NormalTex,sampler_NormalTex,i.uv));
                normalTS.rg *= _NormalStrength;
                //中间量

                float3 nDirWS = normalize(mul(normalTS,TBN));
                float3 vrDirWS = normalize(reflect(-vDirWS,nDirWS));
                //纹理
                
                float4 mainTS = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
                float3 emissionTS = SAMPLE_TEXTURE2D(_Emission,sampler_Emission,i.uv).rgb;
                float4 specTS = SAMPLE_TEXTURE2D(_SpecTex,sampler_SpecTex,i.uv);
                float4 cubeMap = SAMPLE_TEXTURECUBE_LOD(_Cubemap, sampler_Cubemap, vrDirWS, _MapMipStrength);

                //光照
                float aoLight = mainTS.a;
                float phonglight = specTS.a;
                float lambert = max(0.0,dot(iDirWS,i.nDirWS) * 0.5 + 0.5);
                float specPow = lerp(1,_SpecPow,phonglight);
                float phong =pow(max(0.0,dot(irDirWS,vDirWS)),specPow);
                float3 mainCol = _BaseColor * mainTS.rgb;
                float3 finalLight =  (mainCol * lambert + phong * _SpecColor) * light.color * shadow.shadowAttenuation;
                float3 col3 = EnvDiff(i.nDirWS,_SkyColor,_EnvColor,_GroundColor);
                // 环境漫反射
                
                float3 envDiff = mainCol * _DiffInt * float4(col3,1);
                //镜面
                float fresnel = pow(1 - dot(nDirWS,vDirWS),_FresnelPow);
                float4 spec = _EnvSpecInt * fresnel * cubeMap;
                float3 finaEnv =  aoLight * (spec + envDiff);

                //自发光
                float3 emission = emissionTS * _EmissionStrength;
                
                float3 fina =  finaEnv +finalLight +emission;
                //return envDiff;
                return float4(fina,1);
            }
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    }
}
