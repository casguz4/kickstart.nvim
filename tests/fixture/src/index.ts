export function greet(name: string): string {
  return `Hello, ${name}!`
}

const visitor = 'world'
export const welcome = greet(visitor)
