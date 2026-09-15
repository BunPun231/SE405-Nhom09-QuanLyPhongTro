import type { Config } from "tailwindcss";

export default {
  content: ["./index.html", "./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        brand: {
          deep: "#0b4f6c",
          warm: "#d9a441",
          sand: "#f8f3e6",
          ink: "#1f2933"
        }
      },
      fontFamily: {
        display: ["'Space Grotesk'", "sans-serif"],
        body: ["'Be Vietnam Pro'", "sans-serif"]
      }
    }
  },
  plugins: []
} satisfies Config;
