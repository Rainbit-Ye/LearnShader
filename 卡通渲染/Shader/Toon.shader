Shader "Unlit/Toon"
{
    Properties
    {
        [Header(Texture)][Space(20)]
        _MainTex("主贴图",2D) = "white" {}
        _DiffRampTex("漫反射色阶贴图",2D) = "white" {}
        _ToonRampTex("卡通渐变贴图",2D) = "white" {}
        
        [Space(20)]
        _MainColor("主颜色",Color) = (1,1,1,1)
        _DiffRampInt("漫反射色阶强度",Range(0,1)) = 0.5
        _ToonSmooth("渐变平滑度", Range(0, 2)) = 0.1
        _CelShadingLevels("渐变色阶数量", Range(1, 10)) = 3
        _AdditionalLightsIntensity("附加光源强度", Range(0,1)) = 0.5
        

        [Header(Specular)][Space(20)]
        _SpecularColor("高光颜色", Color) = (1,1,1,1)
        _SpecPow("高光强度",Range(0,100)) = 2
        _SpecularThreshold("高光阈值", Range(0,1)) = 0.8
        _SpecularSmooth("高光平滑度", Range(0,1)) = 0.02
        
        [Header(Shadow)][Space(20)]
        _ShadowColor("阴影颜色",Color)=(1,1,1,1)
        _NormalBias("法线偏移",Range(0,0.1)) = 0.02
        
        [Header(OutLine)][Space(20)]
        _OutLineCol("描边颜色",Color) = (1,1,1,1)
        _OutLineWidth("描边宽度",Range(0,0.1)) = 0.01
        
        [Header(Rim)][Space(20)]
        _RimColor("边缘光颜色", Color) = (1,1,1,1)
        _RimThreshold("边缘阈值", Range(0, 1)) = 0.7
        _RimSmooth("边缘平滑度", Range(0, 0.5)) = 0.1
        
        [Header(Other)][Space(20)]
        _Opacity("透明度",Range(0,1)) = 0.5
    }
    SubShader
    {
        Tags{"RenderType"="Transparent"}
        
        Pass
        {
            Tags{ "LightMode" = "UniversalForward"}
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT//柔化阴影，得到软阴影
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float2 uv : TEXCOORD2;
                float4 shadow : TEXCOORD3;
            };
            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            TEXTURE2D(_DiffRampTex);
            SAMPLER(sampler_DiffRampTex);
            TEXTURE2D(_ToonRampTex);
            SAMPLER(sampler_ToonRampTex);

            float4 _MainColor;
            float4 _SpecularColor;
            float4 _ShadowColor;
            float4 _RimColor;

            float _SpecularThreshold;
            float _SpecularSmooth;
            float _SpecPow;
            float _DiffRampInt;
            float _AdditionalLightsIntensity;
            float _NormalBias; 
            float _ToonSmooth; 
            float _CelShadingLevels; 
            float _RimThreshold; 
            float _RimSmooth; 
            float _Opacity;
            
                // 新增的软阴影采样方法
            float SampleSoftShadow(float4 shadowCoord, float3 normalWS)
            {
                float shadow = 0;
                // 1. 法线偏移
                float3 lightDir = _MainLightPosition.xyz;
                float bias = saturate(1.0 - dot(normalWS, lightDir)) * _NormalBias * 0.01;
                shadowCoord.xyz += normalWS * bias;
                
                // 2. 软阴影采样
                    float2 texelSize = GetMainLightShadowParams().y; // 获取纹素大小
                    
                    // 3x3 PCF采样
                    for(int x = -1; x <= 1; x++)
                    {
                        for(int y = -1; y <= 1; y++)
                        {
                            float2 offset = float2(x, y) * texelSize;
                            Light sampleLight = GetMainLight(shadowCoord + float4(offset, 0, 0));
                            shadow += sampleLight.shadowAttenuation;
                        }
                    }
                    return shadow / 9.0;
            }

            
            Varyings vert(Attributes input)
            {
                Varyings output;
                
                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs vertexNormalInputs = GetVertexNormalInputs(input.normal);
                
                output.positionCS = positionInputs.positionCS;
                output.positionWS = positionInputs.positionWS;

                output.normal = vertexNormalInputs.normalWS;
                output.uv = input.uv;
                output.shadow = TransformWorldToShadowCoord(output.positionWS);
                
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                Light mainLight = GetMainLight();
                
                float shadowAtten = SampleSoftShadow(input.shadow,input.normal);
                //shadowAtten = lerp(0.3, 1.0, shadowAtten);
                float3 viewDir = GetCameraPositionWS();
                float3 vDirWS = normalize(viewDir - input.positionWS);
                float3 hDir = normalize(vDirWS + mainLight.direction);
                float NdotH = dot(hDir,input.normal);

                float NdotL = dot(input.normal,mainLight.direction);
                float lambert = max(0.0,NdotL * 0.5 + 0.5);

                float ramp = smoothstep(0, _ToonSmooth, NdotL * 0.5 + 0.5);
                ramp = floor(ramp * _CelShadingLevels) / _CelShadingLevels;
                
                float4 rempTex = SAMPLE_TEXTURE2D(_DiffRampTex,sampler_DiffRampTex,float2(lambert,_DiffRampInt));
                float4 lightTex = SAMPLE_TEXTURE2D(_ToonRampTex,sampler_ToonRampTex,float2(ramp.rr));
                // 主光源漫反射
                float3 mainLightDiffuse = (lightTex + rempTex) * _MainColor * mainLight.color * shadowAtten;
                    
                // 附加光源处理
                float3 additionalLights = 0;
                uint pixelLightCount = GetAdditionalLightsCount();
                for (uint lightIndex = 0; lightIndex < pixelLightCount; ++lightIndex)
                {
                    // 1. 正确获取光源（传入世界坐标）
                    Light light = GetAdditionalLight(lightIndex, input.positionWS);
                    
                    // 2. 计算漫反射强度
                    float addNdotL = saturate(dot(input.normal, light.direction));
                    float3 diffuse = addNdotL * light.distanceAttenuation;
                    
                    // 3. 正确混合阴影（lerp代替直接乘法）
                    float shadow = lerp(0.3, 1.0, diffuse); // 基础阴影过渡
                    
                    diffuse = lerp(_ShadowColor,light.color,diffuse) * shadow;
                    
                    additionalLights += diffuse;
                }

                // 4. 控制附加光源阴影强度
                additionalLights *= _AdditionalLightsIntensity;
                //SampleSH(input.normal) * 1 是 Unity 中用于采样球谐光照（Spherical Harmonics Lighting） 的方法，主要用于实现 环境漫反射光（Ambient/Diffuse Global Illumination）
                float3 envLight = SampleSH(input.normal) * 1;

                //得到总光照
                float3 totalDiffuse = (mainLightDiffuse.rgb + additionalLights + envLight);

                //计算高光
                float specular = pow(NdotH, _SpecPow);
                specular = smoothstep(_SpecularThreshold, _SpecularThreshold + _SpecularSmooth, specular);
                specular *= _SpecularColor; 

                //边缘光
                float rim = smoothstep(_RimThreshold, _RimThreshold + _RimSmooth, 1 - dot(vDirWS, input.normal));

                //主贴图
                float4 mainTex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,input.uv);
                
                //阴影
                float3 shadow = float4(lerp(_ShadowColor,mainLight.color,shadowAtten),1);
                //透明度
                float opacity = mainTex.a * _Opacity;
                //计算总和
                float3 finalColor = mainTex * (totalDiffuse + specular  + _RimColor * rim);
                finalColor.rgb *= shadow;
                //return float4(shadow,1);
                return float4(finalColor * opacity,opacity);
            }
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
        Pass
        {
            //法线外扩描边，对于正方体会出现法线错误的问题
            Name "OutLine"
            Tags {"LightMode" = "SRPDefaultUnlit"}
            Cull Front
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

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
            
            float4 _OutLineCol;
            float _OutLineWidth;
            
            Varyings vert(Attributes input)
            {
                Varyings output;
                input.positionOS.xyz += input.normal * _OutLineWidth;
                VertexPositionInputs vertexPositionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS = vertexPositionInputs.positionCS;
                output.positionWS = vertexPositionInputs.positionWS;
                output.uv = input.uv;
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {

                return _OutLineCol;
            }
            ENDHLSL
        }
        
    }

}
