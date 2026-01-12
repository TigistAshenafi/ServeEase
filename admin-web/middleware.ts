import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export default function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;
  
  // Skip middleware for test page and static assets
  if (pathname.startsWith('/test') || 
      pathname.startsWith('/_next') || 
      pathname.startsWith('/favicon.ico')) {
    return NextResponse.next();
  }
  
  // Simple redirect to /en for root path
  if (pathname === '/') {
    return NextResponse.redirect(new URL('/en', request.url));
  }
  
  // Check if user is trying to access protected routes
  const isLoginRoute = pathname.includes('/login');
  const isProtectedRoute = !isLoginRoute;
  
  // Get the token from cookies
  const token = request.cookies.get('adminToken')?.value;
  
  // If trying to access protected route without token, redirect to login
  if (isProtectedRoute && !token) {
    const loginUrl = new URL('/en/login', request.url);
    return NextResponse.redirect(loginUrl);
  }
  
  // If trying to access login with token, redirect to dashboard
  if (isLoginRoute && token) {
    const dashboardUrl = new URL('/en', request.url);
    return NextResponse.redirect(dashboardUrl);
  }
  
  return NextResponse.next();
}

export const config = {
  // Match only internationalized pathnames and exclude API routes
  matcher: ['/', '/(am|en)/:path*', '/((?!api|_next/static|_next/image|favicon.ico|test).*)']
};