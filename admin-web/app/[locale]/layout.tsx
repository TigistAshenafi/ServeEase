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

async function getMessages(locale: string) {
  try {
    return (await import(`../../messages/${locale}.json`)).default;
  } catch (error) {
    notFound();
  }
}

export default async function LocaleLayout({
  children,
  params
}: Props) {
  // Await the params Promise
  const { locale } = await params;
  
  // Validate that the incoming `locale` parameter is valid
  if (!locales.includes(locale as any)) notFound();

  // Get messages for this locale (for future use)
  const messages = await getMessages(locale);

  return (
    <div lang={locale}>
      {children}
    </div>
  );
}