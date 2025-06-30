Shader "Unlit/2DShake"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _WarpTex ("抖动效果", 2D) = "white" {}
        _WarpInt ("噪声扰动强度",Range(0,1)) = 0.5
        _Offset("偏移控制",Range(0,0.5)) = 0.01
        _FrameCount ("总帧数", Int) = 4     
        _FrameRate ("每秒播放帧数", Float) = 8     
    }
    SubShader
    {
        Tags 
        { 
            "RenderType" = "Transparent" 
            "Queue" = "Transparent" 
            "IgnoreProjector" = "True" 
        }
        LOD 100

        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attribute
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varying
            {
                float2 uv : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;

            TEXTURE2D(_WarpTex);
            SAMPLER(sampler_WarpTex);
            float4 _WarpTex_ST;
            
            float _WarpInt;
            float _Offset;

            int _FrameCount;
            float _FrameRate;

            Varying vert (Attribute IN)
            {
                Varying o;
                // 先做标准顶点变换
                o.vertex = TransformObjectToHClip(IN.vertex.xyz);
                
                o.uv = IN.uv;
                o.uv1 = IN.uv * _WarpTex_ST.xy + _WarpTex_ST.zw;
                // 离散化时间计算（核心逻辑）
                float frameInterval = 1.0 / _FrameRate;                      // 每帧持续时间
                float discreteTime = floor(_Time.y / frameInterval);         // 离散时间计数器
                float frameIndex = fmod(discreteTime, _FrameCount);          // 循环帧索引 [0, _FrameCount-1]
                
                // 垂直方向帧动画（假设WarpTex是纵向排列的帧动画图集）
                o.uv1.x = (frameIndex / _FrameCount) + (o.uv1.x / _FrameCount);
                return o;
            }

            half4 frag (Varying i) : SV_Target
            {
                float4 warpTex = SAMPLE_TEXTURE2D(_WarpTex,sampler_WarpTex,i.uv1);
                float2 uvBis = (warpTex.rg - 0.5) * _WarpInt;
                float2 uv = i.uv + uvBis;
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex,uv +_Offset);
                return col;
            }
            ENDHLSL
        }
    }
}