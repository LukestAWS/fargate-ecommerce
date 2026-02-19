import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "export", // Enables static exports for GitHub Pages
  images: {
    unoptimized: true, // Required for static exports if using Next/Image
  },
};

export default nextConfig;