Shader "Unlit/URPUnlitShadowShader"
{
    Properties
    {
        // Add any properties you need here
    }
    
    SubShader
    {
        Tags 
        { 
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
        }
        
        LOD 100

        Pass
        {
            Name "ForwardLit"
            Tags 
            { 
                "LightMode" = "UniversalForward" 
            }
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // Required includes for URP
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
                float2 uv           : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float3 positionWS   : TEXCOORD0;
                float3 normalWS     : TEXCOORD1;
                float2 uv           : TEXCOORD2;
                
                // Shadow coords
                float4 shadowCoord  : TEXCOORD3;
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                
                VertexPositionInputs vertexInput = GetVertexPositionInputs(IN.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(IN.normalOS, IN.tangentOS);
                
                OUT.positionHCS = vertexInput.positionCS;
                OUT.positionWS = vertexInput.positionWS;
                OUT.normalWS = normalInput.normalWS;
                OUT.uv = IN.uv;
                
                // Calculate shadow coordinates
                OUT.shadowCoord = TransformWorldToShadowCoord(OUT.positionWS);
                
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                // Get main light
                Light mainLight = GetMainLight(IN.shadowCoord);
                
                // Calculate shadow attenuation
                float shadowAttenuation = mainLight.shadowAttenuation;
                
                // Return shadow value as grayscale
                return half4(shadowAttenuation.xxx, 1.0);
            }
            ENDHLSL
        }
    }
    
    FallBack "Diffuse"
}