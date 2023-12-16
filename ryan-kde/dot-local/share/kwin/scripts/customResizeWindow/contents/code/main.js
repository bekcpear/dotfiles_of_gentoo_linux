/********************************************************************
 Copyright (C) 2020 Ryan Qian <i@bitbili.net>
*********************************************************************/

registerShortcut("customResizeWindow", "Move window to right bottom", "Meta+Ctrl+M", function() {
  var client = workspace.activeClient;
  var maxArea = workspace.clientArea(KWin.MaximizeArea, client);
  if (client.moveable && client.resizeable && (client.width < maxArea.width || client.height < maxArea.height)) {
    if (client.resourceName == "superkonsole") {
      client.geometry = {
        x: 603 + maxArea.x,
        y: 823 + maxArea.y,
        width: 1878,
        height: 1925
      };
    } else {
      client.geometry = {
        x: maxArea.width / 2 - 600 + maxArea.x,
        y: maxArea.height / 2 - 500 + maxArea.y,
        width: maxArea.width / 2 + 530,
        height: maxArea.height / 2 + 130
      };
    }
  }
});
