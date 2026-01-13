import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

const locales = ['en', 'am'];
const defaultLocale = 'en';

export default function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;
  
  // Skip middleware for static assets
  if (pathname.startsWith('/_next') || 
      pathname.startsWith('/favicon.ico')) {
    return NextResponse.next();
  }
  
  // Check if pathname is missing a locale
  const pathnameIsMissingLocale = locales.every(
    (locale) => !pathname.startsWith(`/${locale}/`) && pathname !== `/${locale}`
  );
  
  // Redirect if there is no locale
  if (pathnameIsMissingLocale) {
    return NextResponse.redirect(
      new URL(`/${defaultLocale}${pathname}`, request.url)
    );
  }
  
  // Check if user is trying to access protected routes
  const isLoginRoute = pathname.includes('/login');
  const isProtectedRoute = !isLoginRoute && pathname !== '/' && !locales.some(locale => pathname === `/${locale}`);
  
  // Get the token from cookies
  const token = request.cookies.get('adminToken')?.value;
  
  // If trying to access protected route without token, redirect to login
  if (isProtectedRoute && !token) {
    const locale = pathname.split('/')[1];
    const validLocale = locales.includes(locale) ? locale : defaultLocale;
    const loginUrl = new URL(`/${validLocale}/login`, request.url);
    return NextResponse.redirect(loginUrl);
  }
  
  // If trying to access login with token, redirect to dashboard
  if (isLoginRoute && token) {
    const locale = pathname.split('/')[1];
    const validLocale = locales.includes(locale) ? locale : defaultLocale;
    const dashboardUrl = new URL(`/${validLocale}`, request.url);
    return NextResponse.redirect(dashboardUrl);
  }
  
  return NextResponse.next();
}

export const config = {
  // Match all pathnames except for
  // - api, _next/static, _next/image, favicon.ico
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)']
};