import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { VitePWA } from "vite-plugin-pwa";
import { fileURLToPath, URL } from "node:url";
export default defineConfig({
    resolve: {
        alias: {
            "@": fileURLToPath(new URL("./src", import.meta.url))
        }
    },
    plugins: [
        react(),
        VitePWA({
            registerType: "autoUpdate",
            manifest: {
                name: "Smart Boarding House Management",
                short_name: "RoomRental",
                start_url: "/",
                display: "standalone",
                theme_color: "#0b4f6c",
                background_color: "#f8f3e6"
            }
        })
    ],
    server: {
        port: 5173
    }
});
