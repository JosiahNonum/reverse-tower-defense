import { Application, extend } from "@pixi/react";
import { Container, Graphics, Sprite } from "pixi.js";

import { BunnySprite } from "./BunnySprite";
import { Grid } from "./Grid";

// extend tells @pixi/react what Pixi.js components are available
extend({
  Container,
  Graphics,
  Sprite,
});

export default function App() {
  const nodeMap = [
    ["WALL", "SOURCE", "WALL", "WALL", "WALL", "WALL", "WALL", "WALL"],
    ["WALL", "PATH", "PATH", "WALL", "WALL", "FLAG", "PATH", "PATH"],
    ["WALL", "WALL", "PATH", "WALL", "WALL", "WALL", "WALL", "PATH"],
    ["WALL", "WALL", "PATH", "PATH", "WALL", "WALL", "WALL", "PATH"],
    ["WALL", "WALL", "WALL", "PATH", "WALL", "WALL", "WALL", "PATH"],
    ["WALL", "WALL", "WALL", "PATH", "PATH", "PATH", "PATH", "PATH"],
    ["WALL", "WALL", "WALL", "WALL", "WALL", "WALL", "WALL", "WALL"],
  ];
  return (
    // We'll wrap our components with an <Application> component to provide
    // the Pixi.js Application context
    <Application>
      <Grid nodeMap={nodeMap} />
      <BunnySprite />
    </Application>
  );
}
