import { Assets, Texture } from "pixi.js";
import { useEffect, useRef, useState } from "react";
import { useTick } from "@pixi/react";

export function BunnySprite() {
  // The Pixi.js `Sprite`
  const spriteRef = useRef(null);

  const [texture, setTexture] = useState(Texture.EMPTY);
  const [isHovered, setIsHover] = useState(false);
  const [isActive, setIsActive] = useState(false);
  const [x, setX] = useState(100);
  const [y, setY] = useState(100);
  const [momentum, setMomentum] = useState([2, 2]);

  // Preload the sprite if it hasn't been loaded yet
  useEffect(() => {
    if (texture === Texture.EMPTY) {
      Assets.load("https://pixijs.com/assets/bunny.png").then((result) => {
        setTexture(result);
      });
    }
  }, [texture]);

  useTick(() => {
    setX(x + momentum[0]);
    setY(y + momentum[1]);

    if (x > 800) setMomentum([-2, momentum[1]]);
    if (y > 600) setMomentum([momentum[0], -2]);
    if (x < 0) setMomentum([2, momentum[1]]);
    if (y < 0) setMomentum([momentum[0], 2]);
  });

  return (
    <pixiSprite
      ref={spriteRef}
      anchor={0.5}
      eventMode={"static"}
      onClick={(event) => setIsActive(!isActive)}
      onPointerOver={(event) => setIsHover(true)}
      onPointerOut={(event) => setIsHover(false)}
      scale={isActive ? 1 : 1.5}
      texture={texture}
      x={x}
      y={y}
    />
  );
}
