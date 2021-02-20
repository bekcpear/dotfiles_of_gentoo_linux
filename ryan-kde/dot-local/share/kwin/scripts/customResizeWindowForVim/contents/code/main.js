/********************************************************************
 Copyright (C) 2020 Ryan Qian <i@bitbili.net>
*********************************************************************/

registerShortcut("customResizeWindowForVim", "Move window to right and resize", "Meta+Ctrl+P", function() {
  var client = workspace.activeClient;
  var maxArea = workspace.clientArea(KWin.MaximizeArea, client);
  if (client.moveable && client.resizeable && (client.width < maxArea.width || client.height < maxArea.height)) {
    client.geometry = {
      x: 640 + maxArea.x,
      y: maxArea.y,
      width: 1280,
      height: 1170
    };
  }
});
