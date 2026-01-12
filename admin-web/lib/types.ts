// User types
export interface User {
  id: string;
  name: string;
  email: string;
  role: 'seeker' | 'provider' | 'admin';
  emailVerified: boolean;
  isActive?: boolean;
  suspendedAt?: string;
  suspensionReason?: string;
  createdAt: string;
  updatedAt?: string;
}

// Provider types
export interface Provider {
  id: string;
  userId: string;
  providerType: 'individual' | 'organization';
  businessName: string;
  description: string;
  category: string;
  location: string;
  phone: string;
  profileImageUrl?: string;
  documents?: any[];
  certificates?: any[];
  isApproved: boolean;
  approvalDate?: string;
  adminNotes?: string;
  user: {
    name: string;
    email: string;
    createdAt: string;
  };
  createdAt: string;
  updatedAt?: string;
}

// Service types
export interface Service {
  id: string;
  providerId: string;
  categoryId: string;
  title: string;
  description: string;
  price: number;
  durationHours: number;
  isActive: boolean;
  provider?: {
    businessName: string;
    user: {
      name: string;
      email: string;
    };
  };
  category?: {
    name: string;
  };
  createdAt: string;
  updatedAt?: string;
}

// Service Request types
export interface ServiceRequest {
  id: string;
  seekerId: string;
  serviceId: string;
  providerId: string;
  assignedEmployeeId?: string;
  status: 'pending' | 'accepted' | 'assigned' | 'in_progress' | 'completed' | 'cancelled';
  requestedDate: string;
  scheduledDate?: string;
  completionDate?: string;
  notes?: string;
  seekerRating?: number;
  seekerReview?: string;
  providerRating?: number;
  providerReview?: string;
  employeeRating?: number;
  employeeReview?: string;
  seeker?: User;
  service?: Service;
  provider?: Provider;
  createdAt: string;
  updatedAt?: string;
}

// Dashboard Stats types
export interface DashboardStats {
  totalUsers: number;
  totalProviders: number;
  pendingProviders: number;
  totalServices: number;
  activeServices: number;
  totalRequests: number;
  completedRequests: number;
  revenue: number;
  totalRevenue: number; // Added for consistency with dashboard usage
  userGrowth: number;
  providerGrowth: number;
  serviceGrowth: number;
  requestGrowth: number;
}

// Activity Log types
export interface ActivityLog {
  id: string;
  userId?: string;
  action: string;
  entityType: string;
  entityId: string;
  details?: any;
  ipAddress?: string;
  userAgent?: string;
  user?: {
    name: string;
    email: string;
  };
  createdAt: string;
}

// Chart data types
export interface ChartData {
  labels: string[];
  datasets: {
    label: string;
    data: number[];
    backgroundColor?: string | string[];
    borderColor?: string | string[];
    borderWidth?: number;
  }[];
}

// Pagination types
export interface PaginationInfo {
  page: number;
  limit: number;
  total: number;
  pages: number;
}

// API Response types
export interface ApiResponse<T> {
  success: boolean;
  message?: string;
  data?: T;
  pagination?: PaginationInfo;
}

export interface ProvidersResponse {
  success: boolean;
  providers: Provider[];
  pagination: PaginationInfo;
}

export interface UsersResponse {
  success: boolean;
  users: User[];
  pagination: PaginationInfo;
}

export interface ServicesResponse {
  success: boolean;
  services: Service[];
  pagination: PaginationInfo;
}

export interface ActivityLogsResponse {
  success: boolean;
  logs: ActivityLog[];
  pagination: PaginationInfo;
}