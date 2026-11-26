// Halves linear depth by taking the same texel of every 2x2 block, for the
// ambient-occlusion chain's base level when it runs below the prepass's
// resolution. Unlike the rotated-grid minifier used for the coarser mip
// levels, every sample sits at the same offset, so a sloped surface keeps a
// constant depth step per texel instead of an alternating one, which the
// occlusion's normal reconstruction and the bilateral blur both rely on.

uniform sampler2D source;

in vec2 v_uv;

out vec4 frag_color;

void main() {
  ivec2 target = ivec2(gl_FragCoord.xy);
  ivec2 maxCoord = textureSize(source, 0) - ivec2(1);
  float depth = texelFetch(source, min(target * 2, maxCoord), 0).r;
  frag_color = vec4(depth, 0.0, 0.0, 1.0);
}
