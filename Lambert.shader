Shader "Unlit/Lambert"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="UniversalForward" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            struct Attributes 
            {
                float4 vertex : POSITION;//输入模型顶点信息
                float4 normal : NORMAL;//输入模型法线信息
            };

            struct Varyings 
            {
                float3 nDisWS : TEXCOORD0;//由模型法线信息换算来的世界空间发现
                float4 vertex : SV_POSITION;//由模型信息换算来的顶点屏幕信息
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            Varyings vert (Attributes  v)
            {
                Varyings o;
                //URP\HDRP的方法
                VertexPositionInputs positionInput = GetVertexPositionInputs(v.vertex.xyz); 
                VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normal);
                o.vertex = positionInput.positionCS;
                o.nDisWS = normalInputs.normalWS;
                
                /*//与上面等价
                o.vertex = TransformObjectToHClip(v.vertex);
                o.nDisWS = TransformObjectToWorld(v.normal);*/
                
                //o.nDisWS = UnityObjectToWorldNormal(v.normal);  cgprogram的方法
                return o;
            }

            float4 frag (Varyings i) : SV_Target
            {
                //float3 IDir = _WorldSpaceLightPos0.xzy;  cgprogram的方法
                //获得主光源
                Light mainLight = GetMainLight();
                float3 IDir = normalize(mainLight.direction);
                float lambert = dot(IDir,i.nDisWS);
                //原本范围为-1，1，现在去掉0.0
                lambert = max(0,lambert);
                float halfLambert = lambert * 0.5 +0.5;
                return float4(halfLambert.xxx,1.0);
            }
            ENDHLSL
        }
    }
    Fallback "Diffuse"
}
