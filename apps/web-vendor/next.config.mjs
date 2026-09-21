/** @type {import('next').NextConfig} */
const nextConfig = {
  output: "export",
  transpilePackages: ["@solary/shared-types", "@solary/ui-web"],
};
export default nextConfig;
