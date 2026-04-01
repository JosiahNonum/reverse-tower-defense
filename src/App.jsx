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
  return (
    // We'll wrap our components with an <Application> component to provide
    // the Pixi.js Application context
    <Application>
      <Grid />
      <BunnySprite />
    </Application>
  );
}
