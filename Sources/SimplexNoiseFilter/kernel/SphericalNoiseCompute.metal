//
//  File.metal
//  SimplexNoiseFilter
//
//  Created by Влад Янковенко on 27.05.2025.
//

#include <metal_stdlib>
using namespace metal;

#define M_PI 3.14159265358979323846

// Твоя таблица пермутаций - constant, в read-only памяти
static constant uint8_t perm[256] = {87, 34, 171, 119, 15, 162, 234, 180, 116, 5, 161, 43, 126, 163, 117, 193, 96, 218, 86, 47, 29, 84, 189, 199, 64, 2, 197, 10, 120, 195, 127, 59, 103, 198, 98, 23, 207, 51, 200, 33, 155, 148, 107, 187, 236, 131, 216, 239, 156, 182, 48, 113, 210, 229, 128, 212, 149, 204, 153, 111, 58, 147, 71, 118, 36, 158, 179, 241, 74, 62, 122, 41, 83, 253, 244, 228, 9, 85, 16, 112, 141, 135, 186, 53, 165, 157, 27, 188, 20, 101, 72, 4, 175, 17, 211, 70, 136, 32, 173, 1, 75, 151, 26, 81, 150, 223, 183, 252, 93, 95, 65, 206, 67, 18, 68, 90, 66, 185, 245, 37, 12, 191, 91, 137, 242, 176, 205, 255, 190, 222, 220, 77, 250, 196, 177, 134, 192, 168, 133, 19, 94, 45, 219, 164, 60, 170, 208, 221, 217, 154, 194, 159, 169, 55, 209, 8, 61, 76, 146, 22, 240, 246, 184, 152, 167, 144, 3, 106, 99, 109, 50, 233, 115, 238, 110, 44, 174, 108, 249, 31, 54, 97, 121, 69, 202, 56, 105, 251, 237, 57, 224, 226, 203, 247, 104, 30, 140, 7, 132, 11, 49, 40, 24, 129, 139, 227, 166, 143, 231, 82, 14, 46, 28, 39, 13, 172, 124, 138, 73, 178, 160, 0, 142, 88, 213, 230, 130, 78, 243, 125, 145, 181, 215, 232, 201, 89, 92, 102, 25, 235, 248, 42, 79, 254, 114, 123, 214, 35, 38, 63, 225, 21, 52, 100, 6, 80};

// fastfloor с float -> int
inline int fastfloor(float fp) {
    int i = int(fp);
    return (fp < i) ? (i - 1) : i;
}

// Хэш с seed: просто добавим seed в индекс и возьмём по модулю 256
inline uint8_t hash(int i, int seed) {
    // Добавим seed, чтобы получить изменчивый результат
    return perm[uint8_t(i + seed)];
}

// Градиент
inline float grad(int hash, float x, float y, float z) {
    int h = hash & 15;
    float u = h < 8 ? x : y;
    float v = h < 4 ? y : (h == 12 || h == 14) ? x : z;
    return ((h & 1) ? -u : u) + ((h & 2) ? -v : v);
}

// Simplex noise с seed
float noise(float x, float y, float z, int seed) {
    const float F3 = 1.0f / 3.0f;
    const float G3 = 1.0f / 6.0f;

    float s = (x + y + z) * F3;
    int i = fastfloor(x + s);
    int j = fastfloor(y + s);
    int k = fastfloor(z + s);

    float t = (i + j + k) * G3;
    float X0 = i - t;
    float Y0 = j - t;
    float Z0 = k - t;
    float x0 = x - X0;
    float y0 = y - Y0;
    float z0 = z - Z0;

    int i1, j1, k1;
    int i2, j2, k2;

    if (x0 >= y0) {
        if (y0 >= z0) {
            i1 = 1; j1 = 0; k1 = 0;
            i2 = 1; j2 = 1; k2 = 0;
        } else if (x0 >= z0) {
            i1 = 1; j1 = 0; k1 = 0;
            i2 = 1; j2 = 0; k2 = 1;
        } else {
            i1 = 0; j1 = 0; k1 = 1;
            i2 = 1; j2 = 0; k2 = 1;
        }
    } else {
        if (y0 < z0) {
            i1 = 0; j1 = 0; k1 = 1;
            i2 = 0; j2 = 1; k2 = 1;
        } else if (x0 < z0) {
            i1 = 0; j1 = 1; k1 = 0;
            i2 = 0; j2 = 1; k2 = 1;
        } else {
            i1 = 0; j1 = 1; k1 = 0;
            i2 = 1; j2 = 1; k2 = 0;
        }
    }

    float x1 = x0 - i1 + G3;
    float y1 = y0 - j1 + G3;
    float z1 = z0 - k1 + G3;
    float x2 = x0 - i2 + 2.0f * G3;
    float y2 = y0 - j2 + 2.0f * G3;
    float z2 = z0 - k2 + 2.0f * G3;
    float x3 = x0 - 1.0f + 3.0f * G3;
    float y3 = y0 - 1.0f + 3.0f * G3;
    float z3 = z0 - 1.0f + 3.0f * G3;

    int gi0 = hash(i + hash(j + hash(k, seed), seed), seed);
    int gi1 = hash(i + i1 + hash(j + j1 + hash(k + k1, seed), seed), seed);
    int gi2 = hash(i + i2 + hash(j + j2 + hash(k + k2, seed), seed), seed);
    int gi3 = hash(i + 1 + hash(j + 1 + hash(k + 1, seed), seed), seed);

    float t0 = 0.6f - x0*x0 - y0*y0 - z0*z0;
    float n0 = (t0 < 0) ? 0.0f : pow(t0, 4) * grad(gi0, x0, y0, z0);

    float t1 = 0.6f - x1*x1 - y1*y1 - z1*z1;
    float n1 = (t1 < 0) ? 0.0f : pow(t1, 4) * grad(gi1, x1, y1, z1);

    float t2 = 0.6f - x2*x2 - y2*y2 - z2*z2;
    float n2 = (t2 < 0) ? 0.0f : pow(t2, 4) * grad(gi2, x2, y2, z2);

    float t3 = 0.6f - x3*x3 - y3*y3 - z3*z3;
    float n3 = (t3 < 0) ? 0.0f : pow(t3, 4) * grad(gi3, x3, y3, z3);

    return 32.0f * (n0 + n1 + n2 + n3);
}

kernel void noiseKernel(texture2d<float, access::write> outTexture [[texture(0)]],
                        constant int &seed [[buffer(0)]],
                        uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
        return;
    }

    float2 uv = float2(gid) / float2(outTexture.get_width(), outTexture.get_height());

    float n = noise(uv.x * 10.0, uv.y * 10.0, 0.0, seed); // масштабируй по вкусу
    float4 color = float4(n * 0.5 + 0.5, n * 0.5 + 0.5, n * 0.5 + 0.5, 1.0); // шум в серый

    outTexture.write(color, gid);
}


//struct Uniforms {
//    float4 lowColor;
//    float4 highColor;
//    float offsetX;
//    float offsetY;
//    float offsetZ;
//    float zoom;
//    float contrast;
//    float width;
//    float height;
//};
//
//kernel void sphericalSimplexNoise(
//    texture2d<float, access::write> outTexture [[texture(0)]],
//    constant Uniforms& uniforms [[buffer(0)]],
//    uint2 gid [[thread_position_in_grid]]
//) {
//    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
//
//    float2 uv = float2(gid) / float2(uniforms.width, uniforms.height);
//    float theta = 2.0 * M_PI * uv.x;
//    float phi = M_PI * (uv.y - 0.5);
//
//    float3 spherePos = float3(
//        cos(phi) * cos(theta),
//        cos(phi) * sin(theta),
//        sin(phi)
//    );
//
//    float3 samplePos = spherePos * uniforms.zoom + float3(uniforms.offsetX, uniforms.offsetY, uniforms.offsetZ);
//    float noise = noise(samplePos.x, samplePos.y, samplePos);
//
//    noise = (noise + 1.0) * 0.5;
//
//    if (uniforms.contrast != 1.0) {
//        noise = clamp(noise, 0.0001, 0.9999);
//        noise = 1.0 / (1.0 + pow(noise / (1.0 - noise), -uniforms.contrast));
//    }
//
//    float4 color = mix(uniforms.lowColor, uniforms.highColor, noise);
//    outTexture.write(color, gid);
//}
