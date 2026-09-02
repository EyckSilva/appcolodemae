import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Colo de Mãe",
  description: "Aplicativo de apoio à amamentação e apoio à doação de leite materno.",
  icons: {
    icon: "/icon.svg",
  },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="pt-BR" className="h-full antialiased">
      <body className="flex min-h-full flex-col">{children}</body>
    </html>
  );
}
