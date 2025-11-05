import utilsShader from "./utils.wgsl?raw" with { type: "text" };

type NodeProperties = Record<string, number | Array<number>>;

interface Resolution {
  x: number;
  y: number;
  z: number;
}

interface Tile {
  x: number;
  y: number;
}

function getRandomSeed() {
  return Math.floor(Math.random() * 100000);
}


function getTiles(resolution: Resolution, layout: string): Tile {
  const sqr = Math.sqrt(resolution.z);
  if (layout === "auto") return {x: Number.isInteger(sqr) ? Math.ceil(sqr) : 1, y: Number.isInteger(sqr) ? Math.ceil(sqr) : resolution.z}
  if (layout === "square") return {x: Math.ceil(sqr), y: Math.ceil(sqr)}
  if (layout === "horizontal") return {x: resolution.z, y: 1}
  if (layout === "vertical") return {x: 1, y: resolution.z}
  return {x: 1, y: 1}
}


function getNodePropertiesData(properties: NodeProperties): Float32Array {
  const data: Array<number> = [];
  for (const key in properties) {
    const prop = properties[key];
    if (!Object.prototype.hasOwnProperty.call(properties, key)) continue;
    if (typeof prop == "number") {
      data.push(prop);
    } else if (typeof prop == "boolean") {
      data.push(prop ? 1 : 0);
    } else if (prop instanceof Array) {
      for (const item of prop) data.push(item);
    }
  }
  return new Float32Array(data);
}


function toHex(r: Array<number>) {
  if (r == undefined) return `#00000000`;
  const sr = Math.round(r[0] * 255).toString(16).padStart(2, '0');
  const sg = Math.round(r[1] * 255).toString(16).padStart(2, '0');
  const sb = Math.round(r[2] * 255).toString(16).padStart(2, '0');
  const sa = Math.round(r[3] * 255).toString(16).padStart(2, '0');
  return `#${sr}${sg}${sb}${sa}`;
}


function toRgbHex(r: Array<number>) {
  if (r == undefined) return `#000000`;
  const sr = Math.round(r[0] * 255).toString(16).padStart(2, '0');
  const sg = Math.round(r[1] * 255).toString(16).padStart(2, '0');
  const sb = Math.round(r[2] * 255).toString(16).padStart(2, '0');
  return `#${sr}${sg}${sb}`;
}


function fromHex(hex: string) {
  hex = hex.replace(/^#/, '');
  const r = parseInt(hex.slice(0, 2), 16) / 255;
  const g = parseInt(hex.slice(2, 4), 16) / 255;
  const b = parseInt(hex.slice(4, 6), 16) / 255;
  const a = parseInt(hex.slice(6, 8), 16) / 255;
  return [r, g, b, a];
}


function fromRgbHex(hex: string) {
  hex = hex.replace(/^#/, '');
  const r = parseInt(hex.slice(0, 2), 16) / 255;
  const g = parseInt(hex.slice(2, 4), 16) / 255;
  const b = parseInt(hex.slice(4, 6), 16) / 255;
  return [r, g, b, 1.0];
}


export {
  utilsShader,
  getTiles,
  getRandomSeed,
  getNodePropertiesData,
  toHex,
  toRgbHex,
  fromHex,
  fromRgbHex,
}