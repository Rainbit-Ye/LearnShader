Shader "Boom/Smoke/Cloud"
{
    Properties
    {
        _ColorTex("颜色纹理贴图",2D) = "white" {}
        _Color("整体颜色", Color) = (1,1,1,1)
        [HDR]_WarpColor("烟雾颜色",Color) = (1,1,1,1)
        [HDR]_MeltLineColor("溶解边缘色",Color) = (1,1,1,1)
        _NoiseScale("X 颜色扭曲大小 Y 颜色移动速度大小 Z 颜色扰动幅度 W 扩散大小", Vector) = (0,0,0,0)
        _NoiseSpeed("烟雾滚动速度",Range(0,1)) = 1
        _MeltWidth("溶解描边宽度",Range(0,0.5)) = 0.5
        
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
                float4 customData : TEXCOORD1;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 clipValue  : TEXCOORD1;
                float2 uv1 : TEXCOORD2;
            };

            TEXTURE2D(_ColorTex);
            SAMPLER(sampler_ColorTex);
            float4 _ColorTex_ST;
            
            float4 _Color;
            float4 _WarpColor;
            float4 _MeltLineColor;
            float4 _NoiseScale;

            float _NoiseSpeed;
            float _MeltWidth;
        
            float2 random2(float2 st) {
                st = float2(dot(st,float2(127.1,311.7)),dot(st,float2(269.5,183.3)));
                return -1.0 + 2.0 * frac(sin(st) * 43758.5453123);
            }

            float voronoi(float2 uv, float scale) {
                uv *= scale;
                float2 iuv = floor(uv);
                float2 fuv = frac(uv);
                
                float minDist = 1.0;
                for (int y = -1; y <= 1; y++) {
                    for (int x = -1; x <= 1; x++) {
                        float2 neighbor = float2(x, y);
                        float2 p = random2(iuv + neighbor);
                        p = 0.5 + 0.5 * sin(_Time.y * _NoiseSpeed + 6.2831 * p);
                        float2 diff = neighbor + p - fuv;
                        float dist = length(diff);
                        minDist = min(minDist, dist);
                    }
                }
                return minDist;
            }

            void Anim(inout float3 vertex)
            {
                vertex.x +=_NoiseScale.x  * sin(frac(_Time.z  *_NoiseScale.y + vertex.y * _NoiseScale.z) * TWO_PI);
                vertex.z +=_NoiseScale.z * sin(frac(_Time.z * _NoiseScale.y + vertex.y * _NoiseScale.z) * TWO_PI);
            }
            
            Varyings vert(Attributes input)
            {
                Varyings output;
                Anim(input.positionOS.xzy);
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.clipValue = input.customData;
                output.uv = input.uv * _ColorTex_ST.xy + _ColorTex_ST.zw;
                output.uv1 = input.uv;
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                // 计算噪声
                float noise = voronoi(input.uv1, _NoiseScale.w);
                input.uv.x = input.uv.x + frac(_Time.y * _NoiseSpeed);
                float4 colTex = SAMPLE_TEXTURE2D(_ColorTex,sampler_ColorTex,input.uv);
                float4 col = lerp(0.0,_WarpColor,colTex * input.clipValue.y);
                
                float stepMeltTex = step((1.0 - noise),input.clipValue.x);
                float edgeWidth = _MeltWidth * 0.1;
                float edge =  stepMeltTex - step((1.0 - noise),input.clipValue.x - edgeWidth);
                float4 noiseCol = stepMeltTex * _Color ;
                float3 meltLineCol = _MeltLineColor * edge;
                
                //return float4(stepMeltTex.xxxx);
                return half4((noiseCol.rgb + meltLineCol + col) , stepMeltTex * input.clipValue.x);
            }
            ENDHLSL
        }
    }
}