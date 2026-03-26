import React from "react";
import Canvas from "./Canvas";
import useCanvas from "./CanvasHook";
import Ant from "./objects/Ant";

function App() {
  let objects = [new Ant(0, 0), new Ant(25, 5), new Ant(30, 80)];

  const draw = (ctx, frameCount) => {
    ctx.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height);
    ctx.fillStyle = "#000000";
    ctx.beginPath();
    // ctx.arc(50, 100, 20 * Math.sin(frameCount * 0.05) ** 2, 0, 2 * Math.PI);
    // ctx.strokeRect(frameCount % ctx.canvas.width, frameCount % ctx.canvas.height, 20, 20);
    for (let object of objects) {
      ctx.strokeRect(
        object.x % ctx.canvas.width,
        object.y % ctx.canvas.height,
        object.size,
        object.size,
      );
      object.move(object.x + 1 / 10, object.y + object.speed / 10);
    }
    ctx.fill();
  };

  const canvasRef = useCanvas(draw);

  return (
    <>
      <canvas width={800} height={500} ref={canvasRef} />
    </>
  );
}

export default App;
