Shader "Unlit/tornado"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _TintColor ("Tint Color", Color) = (1, 1, 1, 1)
        _Distance ("Distance", float) = 0
        _Amplitude ("Amplitude", float) = .21
        _Speed ("Speed", float) = 5.88
        _Magnitude_Rotate("Rotation Magnitude", float) = 7
        _Amplitude_BigTwist("Big Twist Amplitude", float) = .08
        _Speed_BigTwist("Big Twist Speed", float) = .001
        _Distance_Bigtwist("Big Twist Distance", float) = 0
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
            // make fog work
            //#pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float fresnel : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _TintColor;
            float _Distance;
            float _Amplitude;
            float _Speed;
            float _Magnitude_Rotate;
            float _Amplitude_BigTwist;
            float _Speed_BigTwist;
            float _Distance_Bigtwist;       

            float4 rotate(float magnitude, float4 p)
            {
                float sinTheta = sin(magnitude);
                float cosTheta = cos(magnitude);
                float4x4 rotationMatrix = { cosTheta, 0, sinTheta, 0,
                                            0, 1, 0, 0,
                                            -sinTheta, 0, cosTheta, 0,
                                            0, 0, 0, 1 };
                return mul(rotationMatrix, p);
            }      

            v2f vert (appdata v)
            {
                v2f o;
                v.vertex = rotate(_Magnitude_Rotate * _Time.y, v.vertex);
                
                // using vertex color as a mask to constrain bottom verts
                v.vertex += v.color.r * _Amplitude * sin(_Time.y * _Speed + v.vertex.y + _Distance);
                
                v.vertex.xz += v.color.r * _Amplitude_BigTwist * cos(_Time.y * _Speed_BigTwist + v.vertex.y + _Distance_Bigtwist);
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                //calculate world position of vertex
                float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
                
                //calculate world normal
                float3 worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
                
                // get view direction by subtracting world position of vertex by world space camera position
                float3 viewDir = normalize(worldPos - _WorldSpaceCameraPos);

                //get the dot product between the normal and the direction
                float fresnel = dot(worldNormal, viewDir);
                //clamp the value between 0 and 1 so we don't get dark artifacts at the backside
                o.fresnel = saturate(1 - fresnel);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv) + _TintColor;
                col += i.fresnel;

                return col;
            }
            ENDHLSL
        }
    }
}
