# ServeEase Project
# ServeEase - Connecting Service Providers & Seekers

ServeEase is a comprehensive platform that connects service providers with service seekers. Built with Flutter (mobile app) and Node.js/Express (backend) with PostgreSQL database.

## Features

### User Management
- **Dual Role Registration**: Users can register as service seekers or providers
- **Email Verification**: Secure email verification system
- **Role-based Access**: Different dashboards and features for seekers, providers, and admins

### Enhanced Provider System
- **Provider Types**: Choose between Individual or Organization registration
- **Individual Providers**: Must upload certificates for admin verification
- **Organization Providers**: Can manage employees and assign them to service requests
- **Employee Management**: Organizations can add, update, and manage their workforce
- **Certificate Verification**: Individual providers require certificate uploads for approval

### AI Assistant
- **Intelligent Chat**: Context-aware AI assistant powered by OpenAI
- **Service Recommendations**: AI-powered service and provider suggestions
- **Platform Guidance**: Help users navigate features and complete tasks
- **Query Analysis**: Understand user intent and provide relevant actions
- **Conversation History**: Maintain context throughout conversations

### For Service Seekers
- Browse service categories (Home Repair, Cleaning, Gardening, IT Support, etc.)
- View provider profiles and services
- Request services from specific providers
- Track service request status

### For Service Providers
- **Choose Provider Type**: Register as Individual or Organization
- **Individuals**: Upload certificates for verification and approval
- **Organizations**: Manage employees and assign them to service requests
- **Employee Management**: Add, update, and remove employees (organizations only)
- **Profile Setup**: Complete detailed provider profile with type-specific requirements
- **Service Management**: Create, update, and manage services
- **Request Handling**: Accept requests and assign employees (organizations)

### For Admins
- Approve/reject provider applications
- Manage users and service categories
- Platform oversight and analytics

## Project Structure

```
serveease-cursor/
├── serveease_app/          # Flutter mobile application
│   ├── lib/
│   │   ├── models/         # Data models
│   │   ├── providers/      # State management
│   │   ├── screens/        # UI screens
│   │   ├── services/       # API services
│   │   └── widgets/        # Reusable widgets
│   ├── pubspec.yaml        # Flutter dependencies
│   └── ...
└── serveease_backend/      # Node.js/Express backend (ES modules)
    ├── controllers/        # Route controllers (ES modules)
    ├── middleware/         # Authentication middleware (ES modules)
    ├── routes/            # API routes (ES modules)
    ├── config/            # Database configuration (ES modules)
    ├── database/          # Database schema (SQL)
    ├── server.js          # Main server file (ES modules)
    ├── package.json       # Node.js dependencies (type: "module")
    └── ...
```

## Setup Instructions

### Prerequisites

1. **Flutter SDK**: Install Flutter from [flutter.dev](https://flutter.dev)
   - Download and install Flutter SDK
   - Add Flutter to your system PATH
   - Run `flutter doctor` to verify installation

2. **Node.js**: Install Node.js (v16 or higher) from [nodejs.org](https://nodejs.org)
   - The backend uses ES modules (type: "module")

3. **PostgreSQL**: Install PostgreSQL database server

4. **Git**: Version control system

### Backend Setup (ES Modules)

1. **Navigate to backend directory:**
   ```bash
   cd serveease_backend
   ```

2. **Install dependencies:**
   ```bash
   npm install
   # Note: package.json includes "type": "module" for ES modules support
   ```

3. **Set up PostgreSQL database:**
   - Create a new database named `serveease_db`
   - Run the schema file:
   ```sql
   psql -d serveease_db -f database/schema.sql
   ```

4. **Configure environment variables:**
   - Copy `env.example` to `.env`
   - Update the following variables in `.env`:
   ```env
   DB_HOST=localhost
   DB_PORT=5432
   DB_NAME=serveease_db
   DB_USER=your_postgres_username
   DB_PASSWORD=your_postgres_password

   JWT_SECRET=your_jwt_secret_key_here

   EMAIL_HOST=smtp.gmail.com
   EMAIL_PORT=587
   EMAIL_USER=your_email@gmail.com
   EMAIL_PASS=your_app_password
   ```

5. **Start the backend server:**
   ```bash
   npm start     # Production mode
   npm run dev   # Development mode with auto-reload
   ```
   The API will be available at `http://localhost:3000`

   **Note:** The backend uses ES modules. All imports use ES6 `import` syntax instead of CommonJS `require`.

### Frontend Setup

1. **Navigate to Flutter app directory:**
   ```bash
   cd serveease_app
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Update API base URL:**
   - Open `lib/services/api_service.dart`
   - Change `baseUrl` to match your backend URL:
   ```dart
   static const String baseUrl = 'http://your-backend-url:3000/api';
   ```

4. **Run the Flutter app:**
   ```bash
   flutter run
   ```

## API Endpoints

### Authentication
- `POST /api/auth/register` - User registration
- `GET /api/auth/verify-email` - Email verification
- `POST /api/auth/login` - User login
- `GET /api/auth/profile` - Get user profile

### Provider Management
- `POST /api/provider/profile` - Create/update provider profile
- `GET /api/provider/profile` - Get provider profile
- `GET /api/provider/admin/providers` - Get all providers (admin)
- `PUT /api/provider/admin/providers/:id/approve` - Approve provider (admin)
- `PUT /api/provider/admin/providers/:id/reject` - Reject provider (admin)

### AI Assistant
- `POST /api/ai/chat` - Chat with AI assistant
- `POST /api/ai/analyze` - Analyze user query for intent
- `GET /api/ai/recommendations/services` - Get AI-powered service recommendations
- `GET /api/ai/recommendations/providers` - Get AI-powered provider recommendations
- `GET /api/ai/insights` - Get platform insights and statistics

## User Flow

### Service Seeker Registration
1. Register with name, email, password, and role "seeker"
2. Verify email via link sent to email
3. Login and access seeker dashboard
4. Browse service categories
5. View providers and request services

### Service Provider Registration
1. Register with name, email, password, and role "provider"
2. Verify email via link sent to email
3. Complete provider profile setup
4. Wait for admin approval
5. Once approved: Can offer services
6. While waiting: Can use seeker features

### Admin Features
1. Login with admin credentials
2. Review provider applications
3. Approve or reject providers
4. Manage platform settings

## Database Schema

The application uses PostgreSQL with the following main tables:
- `users` - User accounts and authentication
- `provider_profiles` - Provider business information (with type: individual/organization)
- `employees` - Employee management for organizations
- `service_categories` - Service category definitions
- `services` - Individual services offered by providers
- `service_requests` - Service booking requests (with employee assignment)
- `messages` - Communication between seekers and providers

### Provider Types
- **Individual Providers**: Must upload certificates for verification
- **Organization Providers**: Can manage employees and assign them to service requests
- **Service Request Flow**: Organizations can assign specific employees to accepted requests

## Development Notes

### Backend
- Uses Express.js for API routing
- JWT for authentication
- Nodemailer for email verification
- PostgreSQL with pg library
- bcryptjs for password hashing

### Frontend
- Flutter for cross-platform mobile development
- Provider for state management
- Go Router for navigation
- HTTP package for API calls
- Shared Preferences for local storage

## Troubleshooting

### Flutter Issues
If you encounter import errors like "Target of URI doesn't exist" for packages:

1. **Install Flutter dependencies:**
   ```bash
   cd serveease_app
   flutter pub get
   ```

2. **Verify Flutter installation:**
   ```bash
   flutter doctor
   ```

3. **Check Flutter version:**
   - Ensure you're using Flutter 3.0 or higher
   - Update pubspec.yaml dependencies if needed

4. **Clean and rebuild:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

### Backend Issues
If the backend fails to start:

1. **Check Node.js version:**
   ```bash
   node --version
   ```

2. **Install backend dependencies:**
   ```bash
   cd serveease_backend
   npm install
   ```

3. **Set up PostgreSQL database:**
   - Create database: `serveease_db`
   - Run the schema: `psql -d serveease_db -f database/schema.sql`

4. **Configure environment variables:**
   - Copy `env.example` to `.env`
   - Update database and email settings

## Technical Implementation

### Backend Architecture:
- **Node.js with ES Modules**: Uses modern `import`/`export` syntax instead of CommonJS
- **Express.js**: RESTful API framework with middleware support
- **PostgreSQL**: Relational database with comprehensive schema
- **JWT Authentication**: Secure token-based authentication
- **Email Notifications**: Automated emails using Nodemailer
- **AI Integration**: OpenAI GPT-powered intelligent assistant

### Database Schema:
- **Users Table**: Authentication and role management
- **Provider Profiles**: Business information with type support (individual/organization)
- **Employees Table**: Workforce management for organizations
- **Services & Categories**: Service catalog management
- **Service Requests**: Request tracking with employee assignment
- **Messages**: Communication system

### API Features:
- **Role-based Access Control**: Different permissions for seekers, providers, and admins
- **Provider Types**: Specialized workflows for individuals vs organizations
- **Employee Assignment**: Organizations can assign employees to service requests
- **Certificate Verification**: Individual providers require certificate uploads
- **Rating System**: Multi-level ratings for services, providers, and employees

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For questions or support, please contact the development team or create an issue in the repository.
