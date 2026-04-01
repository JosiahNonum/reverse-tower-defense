import { useTick } from "@pixi/react";
import { useRef, useEffect } from "react";
import { MOVE_INTERVAL, NodeType } from "../constants";

export function RenderAnts({ nodeMap, spawnPoint }) {
  const graphicsRef = useRef(null);
  nodeMap = nodeMap.nodeMap;

  // simulation state (NOT React state)
  const state = useRef({
    row: spawnPoint.y,
    col: spawnPoint.x,
    momentum: "down",
    elapsed: 0,
  });

  useEffect(() => {
    const g = graphicsRef.current;
    g.clear();
    g.setFillStyle(0x00ffff);
    g.circle(spawnPoint.x, spawnPoint.y, 20);
    g.fill();
  }, []);

  useTick((ticker) => {
    const s = state.current;
    s.elapsed += ticker.deltaMS;

    if (s.elapsed < MOVE_INTERVAL) return;
    s.elapsed = 0;

    const { row, col, momentum } = s;

    // --- movement logic ---
    if (nodeMap[row]?.[col] === NodeType.FLAG) {
      s.row = spawnPoint.y;
      s.col = spawnPoint.x;
    } else if (
      (nodeMap[row + 1]?.[col] === NodeType.PATH || nodeMap[row + 1]?.[col] === NodeType.FLAG) &&
      momentum !== "up"
    ) {
      s.row += 1;
      s.momentum = "down";
    } else if (
      (nodeMap[row]?.[col + 1] === NodeType.PATH || nodeMap[row]?.[col + 1] === NodeType.FLAG) &&
      momentum !== "left"
    ) {
      s.col += 1;
      s.momentum = "right";
    } else if (
      (nodeMap[row - 1]?.[col] === NodeType.PATH || nodeMap[row - 1]?.[col] === NodeType.FLAG) &&
      momentum !== "down"
    ) {
      s.row -= 1;
      s.momentum = "up";
    } else if (
      (nodeMap[row]?.[col - 1] === NodeType.PATH || nodeMap[row]?.[col - 1] === NodeType.FLAG) &&
      momentum !== "right"
    ) {
      s.col -= 1;
      s.momentum = "left";
    }

    // --- render update (imperative) ---
    const g = graphicsRef.current;
    if (!g) return;

    const x = s.col * 88 + 44;
    const y = s.row * 88 + 44;

    g.x = x;
    g.y = y;
  });

  return <pixiGraphics ref={graphicsRef} />;
}
