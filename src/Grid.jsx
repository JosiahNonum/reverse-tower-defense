import { Assets, Texture, Container, Graphics } from "pixi.js";
import { useRef, useState } from "react";
import { useApplication } from "@pixi/react";
import { RenderSquares } from "./render/RenderSquares";
import { RenderAnts } from "./render/RenderAnts";

export function Grid(nodeMap) {
  const gridRef = useRef(null);
  const { app } = useApplication();
  const spawnPoint = { x: 1, y: 0 };

  // 9 x 7 2d array for the game map
  // let squares = renderSquares(nodeMap);
  //   renderTowers();
  //   renderGoal();

  return (
    <pixiContainer>
      <RenderSquares nodeMap={nodeMap} />
      <RenderAnts nodeMap={nodeMap} spawnPoint={spawnPoint} />
    </pixiContainer>
  );
}
