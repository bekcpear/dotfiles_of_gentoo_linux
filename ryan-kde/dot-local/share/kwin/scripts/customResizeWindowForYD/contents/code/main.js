/********************************************************************
 Copyright (C) 2020 Ryan Qian <i@bitbili.net>
*********************************************************************/

registerShortcut("customResizeWindowForYD", "Move window to right and resize", "Meta+Ctrl+Y", function() {
  var client = workspace.activeClient;
  var maxArea = workspace.clientArea(KWin.MaximizeArea, client);
  if (client.moveable && client.resizeable && (client.width < maxArea.width || client.height < maxArea.height)) {
    client.geometry = {
      x: maxArea.x,
      y: maxArea.y + 600,
      width: maxArea.width / 6,
      height: maxArea.height - 800
    };
  }
});
