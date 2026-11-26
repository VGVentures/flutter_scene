// The WebGL2 backend renders into a target with a depth-stencil attachment
// and no color attachment, and a later pass can load the depth it wrote.
//
//   flutter test --platform chrome \
//     test/gpu/webgl/webgl_depth_only_target_browser_test.dart
//
// ignore_for_file: implementation_imports
@TestOn('browser')
library;

import 'package:flutter_scene/src/gpu/web/_gpu.dart' as gpu;
import 'package:flutter_scene/src/gpu/web/webgl/_webgl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;

void main() {
  if (gpu.useWebGpuBackend) {
    test('needs the WebGL2 shim', () {
      markTestSkipped('The shim is WebGPU in this build.');
    });
    return;
  }

  test('the WebGL2 host reports depth-only targets', () async {
    await gpu.initializeGpuBackend();
    expect(gpu.gpuHost.capabilities.depthOnlyRenderTargets, isTrue);
  });

  test('a depth-only pass clears depth that a color pass then loads', () async {
    await gpu.initializeGpuBackend();
    final gl = (gpu.gpuContext as WebGlContext).gl;
    final depth = gpu.gpuContext.createTexture(
      gpu.StorageMode.devicePrivate,
      8,
      8,
      format: gpu.gpuContext.defaultDepthStencilFormat,
      enableRenderTargetUsage: true,
    );
    final color = gpu.gpuContext.createTexture(
      gpu.StorageMode.devicePrivate,
      8,
      8,
    );

    final commands = gpu.gpuContext.createCommandBuffer();
    commands.createRenderPass(
      gpu.RenderTarget(
        depthStencilAttachment: gpu.DepthStencilAttachment(
          texture: depth,
          depthClearValue: 0.25,
          depthStoreAction: gpu.StoreAction.store,
        ),
      ),
    );
    expect(gl.getError(), web.WebGL2RenderingContext.NO_ERROR);
    expect(
      gl.checkFramebufferStatus(web.WebGL2RenderingContext.FRAMEBUFFER),
      web.WebGL2RenderingContext.FRAMEBUFFER_COMPLETE,
    );
    commands.createRenderPass(
      gpu.RenderTarget.singleColor(
        gpu.ColorAttachment(texture: color),
        depthStencilAttachment: gpu.DepthStencilAttachment(
          texture: depth,
          depthLoadAction: gpu.LoadAction.load,
        ),
      ),
    );
    expect(gl.getError(), web.WebGL2RenderingContext.NO_ERROR);
    commands.submit();
  });

  test('a target with neither color nor depth is refused', () async {
    await gpu.initializeGpuBackend();
    final commands = gpu.gpuContext.createCommandBuffer();
    expect(
      () => commands.createRenderPass(const gpu.RenderTarget()),
      throwsA(isA<Exception>()),
    );
  });
}
