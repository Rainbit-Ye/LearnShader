Shader "Unlit/OldSchool_Mix"
{
    Properties
    {
        _MainTex ("AO贴图", 2D) = "white" {}
        _UpColor("顶部环境光",Color) = (1,1,1,1)
        _SideColor("侧面环境光",Color) = (1,1,1,1)
        _DownColor("底部环境光",Color) = (1,1,1,1)
        _AoColor("整体环境光",Color) = (1,1,1,1)
        _String3Col("3Col强度",Range(0,1)) = 1
        
        _Pow("高光次幂",Range(1,100)) = 10
        _SpecColor("高光颜色",Color) = (1,1,1,1)
        
        _BaseColor("基本颜色",Color)=(1,1,1,1)
        _ShadowColor("阴影颜色",Color) = (1,1,1,1)
        
        _AoStrong("AO强度",Range(0,1)) = 1
        
    }
    SubShader
    {
        Tags {"RenderType" = "Opaque"}
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            float4 _UpColor;
            float4 _SideColor;
            float4 _DownColor;

            float _Pow;
            float _AoStrong;
            float4 _AoColor;
            float4 _SpecColor;
            
            float _String3Col;
            float4 _BaseColor;
            float4 _ShadowColor;
            struct Attributes 
            {
                float4 vertex : POSITION;
                float4 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings 
            {
                float3 posWS : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float2 uv : TEXCOORD2;
                float4 shadow : TEXCOORD3;
                float4 posCS : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                VertexPositionInputs position_inputs = GetVertexPositionInputs(IN.vertex.xyz);
                VertexNormalInputs normal_inputs = GetVertexNormalInputs(IN.normal);

                OUT.uv = IN.uv;
                OUT.normal = normal_inputs.normalWS;
                OUT.posWS = position_inputs.positionWS;
                OUT.posCS = position_inputs.positionCS;
                OUT.shadow = TransformWorldToShadowCoord(OUT.posWS);
                
                return OUT;
            }

            float4 frag (Varyings IN) : SV_Target
            {
                //归一化和初始化
                float3 nDir = normalize(IN.normal);
                float3 pos = IN.posWS;
                
                Light mainLight = GetMainLight();
                float3 dir = normalize(mainLight.direction);
                float3 camera = GetCameraPositionWS();

                //计算视图方向
                float3 vDir = normalize(camera - pos);
                //=======兰伯特======
                float lambert = max(0.0f,dot(dir,nDir));
                lambert = lambert*0.5+0.5;
                //=======镜面高光======
                float3 rDir = normalize(reflect(-dir,nDir));//计算反射光方向
                float phong = pow(max(0.0,dot(rDir,vDir)),_Pow);
                //=======3Col=========
                float upLight = max(0.0,nDir.g);
                float downLight = max(0.0,-nDir.g);
                float sideLight = max(0.0,1-upLight-downLight);

                float4 col_3 = _String3Col * (upLight*_UpColor + downLight * _DownColor + sideLight * _SideColor);
                //=======AO遮蔽=======
                float4 tex = tex2D(_MainTex,IN.uv) * _AoStrong;
                //======阴影===========
                Light shadowMainLight = GetMainLight(IN.shadow);
                float shadow = shadowMainLight.shadowAttenuation;
                //======光照模型=======
                float4 shadowColor = lerp(_ShadowColor,_BaseColor,shadow);
                float4 light = lambert * _BaseColor + phong * _SpecColor;
                return  tex * col_3 + light * shadowColor;
            }
            ENDHLSL
        }
    }
}
