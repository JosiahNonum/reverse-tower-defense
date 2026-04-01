import { Assets, Texture, Container, Graphics } from "pixi.js";
import { useEffect, useRef, useState } from "react";
import { useTick, useApplication } from "@pixi/react";

// class Square{
//     constructor(isActive = false){
//         this.isActive = isActive;
//         this.color = this.isActive ? #D3D3D3 : #A9A9A9;
//     }
// }

function renderSquares() {
  let squares = [];
  let isActive = [
    [0, 1, 0, 0, 0, 0, 0],
    [0, 1, 1, 0, 0, 0, 0],
    [0, 0, 1, 0, 1, 1, 1],
    [0, 0, 1, 1, 1, 1, 0],
    [0, 0, 0, 0, 1, 0, 0],
    [0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0],
  ];
  for (let i = 0; i < 7; i++) {
    for (let j = 0; j < 5; j++) {
      console.log(i, j, isActive[i]?.[j]);
      squares.push(
        <pixiGraphics
          draw={(g) => {
            g.clear();
            g.setFillStyle(isActive[j]?.[i] ? 0xd3d3d3 : 0x696969);
            g.rect(i * 110, j * 110, 100, 100);
            g.fill();
          }}
        />,
      );
    }
  }
  return squares;
}

export function Grid() {
  const gridRef = useRef(null);
  const { app } = useApplication();
  // const scene = new Scene(app.screen.width, app.screen.height);

  // 9 x 7 2d array for the game map
  let squares = renderSquares();
  //   renderTowers();
  //   renderAnts();
  //   renderGoal();
  //   const graphics = new Graphics().rect(50, 50, 100, 100).fill(0xd3d3d3);

  return <pixiContainer>{squares}</pixiContainer>;
}
