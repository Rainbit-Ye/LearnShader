Shader "Unlit/Phong"
{
    Properties
    {
        _Color("Color",Color) = (1,1,1,1)
        _Power("高光次幂",Float) = 1
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
                float3 nDisWS : TEXCOORD0;
                float3 vDirWS : TEXCOORD1;
                float3 posWS : TEXCOORD2;
                float4 posCS : SV_POSITION;//由模型信息换算来的顶点屏幕信息
                
            };

            float _Power;
            float4 _Color;

            Varyings vert (Attributes  v)
            {
                Varyings o;
                //URP\HDRP的方法
                VertexPositionInputs positionInput = GetVertexPositionInputs(v.vertex.xyz); 
                VertexNormalInputs normalInputs = GetVertexNormalInputs(v.normal);
                o.posCS = positionInput.positionCS;//OS to CS
                o.posWS = positionInput.positionWS;//变换顶点OS to WS
                o.nDisWS = normalInputs.normalWS;//OS to WS
                //获取世界空间视线方向
                o.vDirWS = GetWorldSpaceNormalizeViewDir(positionInput.positionWS);
                return o;
            }

            float4 frag (Varyings i) : SV_Target
            {
                //获得主光源
                Light mainLight = GetMainLight();
                float3 IDir = normalize(mainLight.direction);
                
                /*float3 cameraDir = GetCameraPositionWS();
                float3 vDir = normalize(cameraDir - i.posWS) ;*/
                
                //原本范围为-1，1，现在去掉0.0
                //=================兰伯特=====================
                float lambert = dot(IDir,i.nDisWS);
                lambert = max(0,lambert);
                float halfLambert = lambert * 0.5 +0.5;
                //=================Phong=======效果好==============
                float3 rDir =reflect(-IDir, i.nDisWS);
                float phong = dot(i.vDirWS,rDir);
                phong = max(0.0,phong);
                phong = pow(phong,_Power);
                //===============Blingphong=====算力省===================
                float3 hDir = normalize(i.vDirWS + IDir);
                float bilinphong = dot(hDir,i.nDisWS);
                bilinphong = max(0.0,bilinphong);
                bilinphong = pow(bilinphong,_Power);
                return _Color *  halfLambert + bilinphong;
            }
            ENDHLSL
        }
    }
    Fallback "Diffuse"
}
