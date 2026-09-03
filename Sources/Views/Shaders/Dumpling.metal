// The squish. A SwiftUI `distortionEffect` shader: given a destination point it
// returns the source point to sample, so warping the mapping warps the pixels
// of whatever view it is attached to (here, the filled dumpling silhouette).
//
// Three deformations compose, all in view-space points:
//   1. breath      — inflate/deflate by scaling about the centre, with a touch
//                    of squash so an empty dumpling sits wider and flatter.
//   2. dimple      — a soft local pinch that follows the thumb while pressed and
//                    springs back (with a little overshoot → a gentle "pop") on
//                    release, driven by a `press` value that may go slightly
//                    negative.
//   3. rest wobble — a barely-there idle sway so it looks alive before it is
//                    touched. The view passes wobble = 0 during a session and
//                    whenever Reduce Motion is on.
//
// Agent 1 (Core interaction & feel) owns this file.

#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
using namespace metal;

[[ stitchable ]]
float2 dumplingSquish(float2 position,
                      float2 size,
                      float  openness,     // 0 deflated … 1 inflated
                      float2 touch,        // thumb, view-space points
                      float  press,        // ~ -0.25 … 1, dimple depth
                      float  time,         // seconds, for the idle wobble
                      float  wobble)       // 0 disables the idle wobble
{
    float2 center = size * 0.5;
    float2 rel    = position - center;
    float  maxDim = max(size.x, size.y);
    float2 src    = position;

    // 1. Breath: scale about the centre. Bigger when full → sample closer in.
    float scale   = mix(0.87, 1.05, clamp(openness, 0.0, 1.0));
    float squashX = mix(1.035, 1.0, clamp(openness, 0.0, 1.0));
    float squashY = mix(0.90, 1.0, clamp(openness, 0.0, 1.0));
    src = center + float2(rel.x / (scale * squashX),
                          rel.y / (scale * squashY));

    // 2. Thumb dimple: pull the sample away from the touch within a soft radius
    //    so the surface (and the silhouette edge nearest the thumb) presses in.
    if (fabs(press) > 0.001) {
        float2 d      = position - touch;
        float  dist   = length(d);
        float  radius = maxDim * 0.42;
        float  sigma  = radius * 0.55;
        float  fall   = exp(-(dist * dist) / (2.0 * sigma * sigma));
        float2 dir    = dist > 0.001 ? d / dist : float2(0.0, 1.0);
        src += dir * (radius * 0.5 * press) * fall;
    }

    // 3. Rest wobble: a slow, low-amplitude radial breathing of the outline.
    if (wobble > 0.001) {
        float r   = length(rel);
        float ang = atan2(rel.y, rel.x);
        float w   = sin(ang * 2.0 + time * 1.6) * 0.6
                  + sin(time * 0.9) * 0.4;
        float2 dir = r > 0.001 ? rel / r : float2(0.0);
        src += dir * w * wobble * (r / maxDim) * 5.0;
    }

    return src;
}
