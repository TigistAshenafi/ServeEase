import { ReactNode } from 'react';
import { notFound } from 'next/navigation';

const locales = ['en', 'am'];

type Props = {
  children: ReactNode;
  params: Promise<{ locale: string }>;
};

export function generateStaticParams() {
  return locales.map((locale) => ({ locale }));
}

export default async function LocaleLayout({
  children,
  params
}: Props) {
  // Await the params Promise
  const { locale } = await params;
  
  // Validate that the incoming `locale` parameter is valid
  if (!locales.includes(locale as any)) notFound();

  // Temporarily disable NextIntlClientProvider for testing
  return children;
}