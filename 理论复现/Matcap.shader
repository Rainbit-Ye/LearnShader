Shader "Unlit/matcap"
{
    Properties
    {
        _NormalTex ("法线贴图", 2D) = "bump" {}
        _MatcapTex("Matcap纹理" , 2D) = "gray" {}
        _FresnelPow("菲涅尔强度", Range(0,1)) = 0.5
        _EnvSpecInt("环境总强度",float) = 1
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
                float2 uv : TEXCOORD0;
                float3 nDisWS : TEXCOORD1;
                float4 tDisWS : TEXCOORD4;
                float3 posWS : TEXCOORD5;
            };

            sampler2D _NormalTex;
            float4 _NormalTex_ST;

            sampler2D  _MatcapTex;
            float4  _MatcapTex_ST;
            
            float _FresnelPow;
            float _EnvSpecInt;

            Varyings vert (Attributes  v)
            {
                Varyings o;
                VertexPositionInputs positionInput = GetVertexPositionInputs(v.vertex.xyz); 
                VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normal,v.tangent);
                o.posCS = positionInput.positionCS;
                o.posWS = positionInput.positionWS;
                o.nDisWS = normalInputs.normalWS;
                o.tDisWS = float4(normalInputs.tangentWS.xyz, v.tangent.w);
                o.uv = v.uv;
                return o;
            }

            float4 frag (Varyings i) : SV_Target
            {
                float3 bDisWS = normalize(cross(i.nDisWS,i.tDisWS) * i.tDisWS.w);
                float3 normalTex = UnpackNormal(tex2D(_NormalTex,i.uv));
                float3x3 TBN = float3x3(i.tDisWS.xyz,bDisWS,i.nDisWS);
                //有一个问题就是这里算出来的贴图是旋转的 ???解不开
                float3 nDisWS = normalize(mul(normalTex,TBN));
                //世界空间转视口空间
                float3 nDisVS = normalize(mul(UNITY_MATRIX_V,float4(nDisWS,0.0)));

                float2 mask = (nDisVS.rgb)*0.5 + 0.5;
                float4 matcap = tex2D(_MatcapTex,mask.rg);
                
                float3 cameraDir = GetCameraPositionWS();
                float3 vDirWS = normalize(cameraDir.xyz - i.posWS.xyz);

                float4 fresnel = 1.0 - dot(vDirWS,i.nDisWS);
                fresnel = pow(fresnel,_FresnelPow);

                float4 envSpecLighting = fresnel * matcap * _EnvSpecInt;
                return envSpecLighting;
            }
            ENDHLSL
        }
    }
}
