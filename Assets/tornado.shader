Shader "Unlit/tornado"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        _ClippingThreshold("Clipping Threshold", Float) = 0.5
        _ClipOverTime("ClipOverTime", Range(0, 1)) = 0
        _MainColor("Main Color",Color) = (1,1,1,1)
        _SecondaryColor("Secondary Color",Color) = (0,0,0,1)
  
        _FresnelExponent("Fresnel Exponent", Range(1,5)) = 1
        _FresnelAmount("Fresnel Amount", Range(0,5)) = 0


        _SPeriod("Small Twist Period", Float) = 3
        _SAmplitude("Small Twist Amplitude", Float) = 0.15
        _LPeriod("Large Twist Period", Float) = 2
        _LAmplitude("Large Twist Amplitude", Float) = 1
        _MaxLTwistWidth("Large Twist Width", Float)= .05 
        _Inflate("Inflate", Float) = 0

        _VerticalSpeed("Vertical Speed", Range(-3,3)) = 0.2
        _HorizontalSpeed("Horizontal Speed", Range(-3,3)) = 1

        _Contrast("Contrast",Range(0,5)) = 1
        _BloomFactor("Bloom Factor", Range(1,1.3)) = 1
        _PeriodicGlow("Periodic Glowing", Float) = 0
        _GlowAmount("Glow Amount", Float) = 1

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {   
            Cull Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
   
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
                float3 worldSpaceViewDir : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;
                float4 color : COLOR;
                
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            //for fresnel
            fixed _ClippingThreshold;
            fixed _ClipOverTime;
            fixed4 _MainColor;
            fixed4 _SecondaryColor;
            fixed _Contrast;
            fixed _BloomFactor;
            fixed _FresnelExponent;
            fixed _FresnelAmount;

            //for vert rotation
            fixed _SPeriod;
            fixed _SAmplitude;
            fixed _LPeriod;
            fixed _LAmplitude;
            fixed _MaxLTwistWidth;

            //for uv rotation
            fixed _VerticalSpeed;
            fixed _HorizontalSpeed; 

            //extra
            fixed _PeriodicGlow;
            fixed _GlowAmount;
            fixed _Inflate;

            v2f vert (appdata v)
            {
                v2f o;

                //apply rotations to vertex
                // small twist
                v.vertex.xz += v.color.r * _SAmplitude * sin(v.vertex.y + _Time.y * _SPeriod);
                // large twist
                v.vertex.xz += lerp(0, _MaxLTwistWidth, (_LAmplitude * sin(_Time.y * _LPeriod))) * lerp(0, v.normal.xz, v.vertex.y);

                //inflate to fix overlap
                v.vertex.xz += v.normal.xz * _Inflate * v.vertex.y;               

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                //calculate world position of vertex
                float4 worldPos = mul(unity_ObjectToWorld, v.vertex);

                // get view direction by subtracting world position of vertex by world space camera position
                o.worldSpaceViewDir = worldPos.xyz - _WorldSpaceCameraPos.xyz;
                
                //calculate world normal
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                o.color = v.color;
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
          
                float2 AdjustedUV = float2(i.uv.x - _Time[1] * _HorizontalSpeed, i.uv.y - _Time[1] * _VerticalSpeed);   

                // sample the texture
                fixed4 Mask = tex2D(_MainTex, AdjustedUV);

                //Fresnel code
                // need to normalize again because interpolation unnormalizes the vector
                // ref: https://forum.unity.com/threads/math-behind-computing-world-space-view-direction.377631/
                float3 worldSpaceViewDir = normalize(i.worldSpaceViewDir);
            
                //get the dot product between the normal and the direction
                float fresnel = _FresnelAmount * pow(1.0 - abs(dot(i.worldNormal.xyz, worldSpaceViewDir)), _FresnelExponent);
             
                // constrains value between 0 and 1
                Mask = saturate(Mask + fresnel);
                
                fixed4 Color = lerp(_SecondaryColor, _MainColor, Mask);

                // make sure sin range is (0,1) for lerp to work
                //make glow animate through height of tornado
                float t = .5 * sin(_PeriodicGlow * .5 * _Time[1]) + .5;
                Color *= lerp(1, _GlowAmount, t);
                Color *= _BloomFactor;

                // discards current pixel if value is less than zero
                float clip_amount = _ClippingThreshold - _ClipOverTime * (.02*sin(_LPeriod * _Time.y)+.4);
                clip(Mask - clip_amount);
                           
                return saturate(lerp(half4(0.5, 0.5, 0.5, 1), Color, _Contrast));
            }
            ENDCG
        }
    }
}
