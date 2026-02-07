import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Emmy - Digital Twin",
  description:
    "Chat with Emmy's AI digital twin. Ask about his career, skills, and experience.",
  icons: {
    icon: "/favicon.ico",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
