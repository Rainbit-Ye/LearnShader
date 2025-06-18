Shader "Unlit/AO"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _upColor("顶光方向",Color)=(1,1,1,1)
        _downColor("底光方向",Color)=(1,1,1,1)
        _sideColor("侧光方向",Color)=(1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            struct Attributes 
            {
                float4 vertex : POSITION;
                float4 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings 
            {
                float3 nDisWS : TEXCOORD0;
                float2 uv : TEXCOORD1;
                float3 posWS : TEXCOORD2;
                float4 posCS : SV_POSITION;//由模型信息换算来的顶点屏幕信息
                
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float3 _upColor;
            float3 _downColor;
            float3 _sideColor;

            Varyings vert (Attributes  v)
            {
                Varyings o;
                //URP\HDRP的方法
                VertexPositionInputs positionInput = GetVertexPositionInputs(v.vertex.xyz); 
                VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normal);
                o.posCS = positionInput.positionCS;
                o.posWS = positionInput.positionWS;
                o.nDisWS = normalInputs.normalWS;
                o.uv = v.uv;
                return o;
            }

            float4 frag (Varyings i) : SV_Target
            {
                float3 normal = normalize(i.nDisWS);
                float uplight =max(0.0, normal.g);
                float downLight = max(0.0,-1 * normal.g);
                float sideLight =max(0.0,1-uplight - downLight);

                float3 tex = tex2D(_MainTex,i.uv);
                return float4(tex * (uplight * _upColor + downLight * _downColor + sideLight * _sideColor),1.0);
            }
            ENDHLSL
        }
    }
    Fallback "Diffuse"
}
