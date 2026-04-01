import { NodeType, NodeColor } from "../constants";

export function RenderSquares({ nodeMap }) {
  let squares = [];
  nodeMap = nodeMap.nodeMap;

  for (let i = 0; i < nodeMap[0].length + 1; i++) {
    for (let j = 0; j < nodeMap.length; j++) {
      const type = nodeMap[j]?.[i] ?? NodeType.WALL;
      const color = NodeColor[type] ?? NodeColor.WALL;

      squares.push(
        <pixiGraphics
          key={`${i}-${j}`}
          draw={(g) => {
            g.clear();
            g.setFillStyle(color);
            g.rect(i * 88, j * 88, 80, 80);
            g.fill();
          }}
        />,
      );
    }
  }
  return squares;
}
