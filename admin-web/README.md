# ServeEase Admin Panel

A comprehensive Next.js admin dashboard for managing the ServeEase platform.

## Features

### 🏢 Provider Management
- **Provider Approvals**: Review and approve/reject provider applications
- **Document Review**: Examine certificates and business documents
- **Provider Status Management**: Track approval status and admin notes

### 👥 User Management
- **User Overview**: View all platform users (seekers, providers, admins)
- **Account Control**: Suspend, activate, or delete user accounts
- **Role-based Filtering**: Filter users by role and status
- **Search Functionality**: Find users by name or email

### 🛠️ Service Moderation
- **Service Review**: Monitor all services offered on the platform
- **Content Moderation**: Approve, reject, or delete inappropriate services
- **Provider Insights**: View service provider information
- **Category Management**: Track services by category

### 📊 Reports & Analytics
- **Dashboard Overview**: Key platform metrics and statistics
- **Growth Analytics**: User and provider growth trends
- **Interactive Charts**: Visual representation of platform data
- **Activity Monitoring**: Track admin actions and system events

### 📋 Document Review
- **Certificate Verification**: Review individual provider certificates
- **Business Document Review**: Examine organization documents
- **Approval Workflow**: Approve or reject documents with notes
- **Document Status Tracking**: Monitor review progress

## Tech Stack

- **Frontend**: Next.js 16, React 19, TypeScript
- **Styling**: Tailwind CSS
- **Charts**: Chart.js with react-chartjs-2
- **Icons**: Heroicons
- **HTTP Client**: Axios
- **Notifications**: React Hot Toast
- **Authentication**: JWT with HTTP-only cookies

## Getting Started

### Prerequisites

- Node.js 18+ 
- npm or yarn
- ServeEase backend API running

### Installation

1. **Install dependencies**:
   ```bash
   npm install
   ```

2. **Set up environment variables**:
   ```bash
   cp .env.local.example .env.local
   ```
   
   Update `.env.local` with your backend API URL:
   ```
   NEXT_PUBLIC_API_URL=http://localhost:3000/api
   ```

3. **Run the development server**:
   ```bash
   npm run dev
   ```

4. **Open your browser**:
   Navigate to [http://localhost:3001](http://localhost:3001)

### Default Admin Credentials

- **Email**: admin@serveease.com
- **Password**: Admin@1234

> ⚠️ **Important**: Change the default admin password in production!

## Project Structure

```
admin-web/
├── app/                    # Next.js app directory
│   ├── page.tsx           # Dashboard page
│   ├── login/             # Authentication
│   ├── providers/         # Provider management
│   ├── users/             # User management
│   ├── services/          # Service moderation
│   ├── reports/           # Analytics & reports
│   └── documents/         # Document review
├── components/            # Reusable components
│   ├── Layout.tsx         # Main layout wrapper
│   └── ui/               # UI components
├── lib/                   # Utilities and configurations
│   ├── api.ts            # API client setup
│   ├── auth.ts           # Authentication helpers
│   ├── types.ts          # TypeScript definitions
│   └── utils.ts          # Utility functions
└── middleware.ts          # Route protection
```

## Key Features Explained

### Authentication & Security
- JWT-based authentication with HTTP-only cookies
- Route protection middleware
- Admin-only access control
- Automatic token refresh

### Provider Approval Workflow
1. Provider submits application with documents
2. Admin reviews provider profile and documents
3. Admin can approve with notes or reject with reason
4. Email notifications sent to providers
5. Approved providers can offer services

### User Management
- View all platform users with pagination
- Suspend users with reason (prevents login)
- Activate suspended users
- Delete users (permanent action)
- Cannot modify admin accounts

### Service Moderation
- Review all services on the platform
- Approve/reject services with reasons
- Delete inappropriate content
- Track service provider information

### Analytics Dashboard
- Real-time platform statistics
- Growth metrics and trends
- Interactive charts and visualizations
- Activity monitoring

## API Integration

The admin panel integrates with the ServeEase backend API:

- **Authentication**: `/api/auth/*`
- **Provider Management**: `/api/provider/admin/*`
- **User Management**: `/api/admin/users/*`
- **Service Management**: `/api/admin/services/*`
- **Reports**: `/api/admin/reports/*`

## Development

### Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run start` - Start production server
- `npm run lint` - Run ESLint

### Code Style

- TypeScript for type safety
- ESLint for code quality
- Tailwind CSS for styling
- Component-based architecture

## Deployment

### Build for Production

```bash
npm run build
npm run start
```

### Environment Variables

Set the following environment variables for production:

```bash
NEXT_PUBLIC_API_URL=https://your-api-domain.com/api
```

## Contributing

1. Follow the existing code structure
2. Use TypeScript for all new components
3. Add proper error handling
4. Include loading states for async operations
5. Test all functionality before submitting

## Security Considerations

- All admin routes are protected by authentication middleware
- JWT tokens are stored in HTTP-only cookies
- API calls include automatic token refresh
- Input validation on all forms
- XSS protection through React's built-in sanitization

## Support

For issues or questions about the admin panel, please check the backend API documentation and ensure all required endpoints are implemented.
