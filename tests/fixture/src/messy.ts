import { readFileSync } from "node:fs"
let   greeting="Hello"
export function shout(name:string){return greeting+", "+name.toUpperCase()+"!"}
