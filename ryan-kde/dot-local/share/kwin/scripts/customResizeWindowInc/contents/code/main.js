/********************************************************************
 Copyright (C) 2020 Ryan Qian <i@bitbili.net>
*********************************************************************/

registerShortcut("customResizeWindowInc", "Incress window's size", "Meta+L", function() {
  var c = workspace.activeClient;
  var maxArea = workspace.clientArea(KWin.MaximizeArea, c);
  if (c.moveable && c.resizeable && (c.width < maxArea.width || c.height < maxArea.height)) {
    var cratio = c.height / c.width;
    c.geometry = {
      x: c.x - 50,
      y: c.y - 50 * cratio,
      width: c.width + 50 * 2,
      height: (c.width + 50 * 2) * cratio
    };
  }
});
