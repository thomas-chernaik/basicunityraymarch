Shader "Unlit/testytesty"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

#define MAX_STEPS 100
#define MAX_DIST 100
#define SURF_DIST 1e-3

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 ro : TEXCOORD1;
                float3 hitPos : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.ro = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos,1));
                o.hitPos = v.vertex;
                return o;
            }

            //returns distance from p to surface of scene
            float GetDist(float3 p)
            {
                //distance to sphere at origin
                float d = length(p) - .5;
                return d;
            }

            //returns depth along viewing ray
            float RayMarch(float3 ro, float3 rd)
            {
                //keep track of the distance from origin we have marched
                float dO = 0;
                //distance from surface
                float dS;
                //march until we reach the max number of steps we can march for
                for (int i = 0; i < MAX_STEPS; i++)
                {
                    //calcualte ray point
                    float3 p = ro + rd * dO;
                    //calculate distance to the surface from p
                    dS = GetDist(p);
                    //move forward along the ray
                    dO += dS;
                    //check we've not gone too far or got too close
                    if (dS < SURF_DIST || dO > MAX_DIST)
                    {
                        break;
                    }
                }
                return dO;
            }
            
            float3 GetNormal(float3 p)
            {
                //set offset to calc normal
                float2 offset = float2(1e-2, 0);
                //calc normal
                float3 n = GetDist(p) - float3(
                    GetDist(p - offset.xyy),
                    GetDist(p - offset.yxy),
                    GetDist(p - offset.yyx)
                    );
                return normalize(n);
            }

            fixed4 frag(v2f i) : SV_Target
            {
                //get uv coord
                float2 uv = i.uv - 0.5;
                //camera/ray origin
                float3 ro = i.ro;//float3(0,0,-3);
                //ray direction
                float3 rd = normalize(i.hitPos - ro);//normalize(float3(uv.x, uv.y, 1));
                //light position
                float3 lightPos = float3(5, 3, 2);
                //light vector
                float3 l = lightPos - ro;
                //output pixel colour
                fixed4 col = 0;
                //raymarch
                float d = RayMarch(ro, rd);
                //work out the hit point
                float3 p = ro + rd * d;
                //if we hit the surface
                if (d < MAX_DIST)
                {
                    col.r = dot(GetNormal(p), l);
                }
                else
                {
                    discard;
                }
                return col;
            }
            ENDCG
        }
    }
}
