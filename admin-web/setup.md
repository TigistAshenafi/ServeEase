# Admin Panel Setup Guide

## Quick Setup

1. **Install dependencies**:
   ```bash
   cd admin-web
   npm install
   ```

2. **Start the development server**:
   ```bash
   npm run dev
   ```

3. **Access the admin panel**:
   - URL: http://localhost:3001
   - Email: admin@serveease.com
   - Password: Admin@1234

## Backend Requirements

Make sure your backend has these endpoints:

### Authentication
- `POST /api/auth/login` - Admin login
- `GET /api/auth/profile` - Get current user

### Provider Management
- `GET /api/provider/admin/providers` - Get all providers
- `PUT /api/provider/admin/providers/:id/approve` - Approve provider
- `PUT /api/provider/admin/providers/:id/reject` - Reject provider

### User Management
- `GET /api/admin/users` - Get all users
- `PUT /api/admin/users/:id/suspend` - Suspend user
- `PUT /api/admin/users/:id/activate` - Activate user
- `DELETE /api/admin/users/:id` - Delete user

### Service Management
- `GET /api/admin/services` - Get all services
- `PUT /api/admin/services/:id/approve` - Approve service
- `PUT /api/admin/services/:id/reject` - Reject service
- `DELETE /api/admin/services/:id` - Delete service

### Reports
- `GET /api/admin/reports/dashboard` - Dashboard stats
- `GET /api/admin/reports/activity` - Activity logs

## Database Updates

Run this SQL to add required columns:

```sql
-- Add suspension fields to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS suspended_at TIMESTAMP;
ALTER TABLE users ADD COLUMN IF NOT EXISTS suspension_reason TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS refresh_token VARCHAR(255);

-- Update existing users to be active by default
UPDATE users SET is_active = TRUE WHERE is_active IS NULL;
```

## Features Included

✅ **Provider Approvals** - Review and approve provider applications
✅ **User Management** - Suspend, activate, delete users  
✅ **Service Moderation** - Approve, reject, delete services
✅ **Reports & Analytics** - Dashboard with charts and statistics
✅ **Document Review** - Review provider certificates and documents
✅ **Activity Monitoring** - Track admin actions
✅ **Responsive Design** - Works on desktop and mobile
✅ **Authentication** - Secure JWT-based login
✅ **Search & Filtering** - Find users, providers, services easily

## Troubleshooting

### Common Issues

1. **API Connection Failed**
   - Check if backend is running on port 3000
   - Verify NEXT_PUBLIC_API_URL in .env.local

2. **Login Failed**
   - Ensure admin user exists in database
   - Check password hash matches

3. **Charts Not Loading**
   - Chart.js dependencies should install automatically
   - Check browser console for errors

4. **Styling Issues**
   - Tailwind CSS should compile automatically
   - Try clearing Next.js cache: `rm -rf .next`