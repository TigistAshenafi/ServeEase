import axios from 'axios';
import Cookies from 'js-cookie';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000/api';

// Create axios instance
const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor to add auth token
api.interceptors.request.use(
  (config) => {
    const token = Cookies.get('adminToken');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor to handle auth errors
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      Cookies.remove('adminToken');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

export default api;

// Auth API
export const authAPI = {
  login: (email: string, password: string) =>
    api.post('/auth/login', { email, password }),
  
  getProfile: () =>
    api.get('/auth/profile'),
};

// Provider API
export const providerAPI = {
  getAll: (params?: { status?: string; page?: number; limit?: number }) =>
    api.get('/provider/admin/providers', { params }),
  
  approve: (providerId: string, adminNotes?: string) =>
    api.put(`/provider/admin/providers/${providerId}/approve`, { adminNotes }),
  
  reject: (providerId: string, adminNotes?: string) =>
    api.put(`/provider/admin/providers/${providerId}/reject`, { adminNotes }),
};

// User API
export const userAPI = {
  getAll: (params?: { page?: number; limit?: number; role?: string }) =>
    api.get('/admin/users', { params }),
  
  suspend: (userId: string, reason?: string) =>
    api.put(`/admin/users/${userId}/suspend`, { reason }),
  
  delete: (userId: string) =>
    api.delete(`/admin/users/${userId}`),
  
  activate: (userId: string) =>
    api.put(`/admin/users/${userId}/activate`),
};

// Service API
export const serviceAPI = {
  getAll: (params?: { page?: number; limit?: number; status?: string }) =>
    api.get('/admin/services', { params }),
  
  approve: (serviceId: string) =>
    api.put(`/admin/services/${serviceId}/approve`),
  
  reject: (serviceId: string, reason?: string) =>
    api.put(`/admin/services/${serviceId}/reject`, { reason }),
  
  delete: (serviceId: string) =>
    api.delete(`/admin/services/${serviceId}`),
};

// Reports API
export const reportsAPI = {
  getDashboardStats: () =>
    api.get('/admin/reports/dashboard'),
  
  getActivityLogs: (params?: { page?: number; limit?: number; type?: string }) =>
    api.get('/admin/reports/activity', { params }),
  
  getUserStats: (period?: string) =>
    api.get('/admin/reports/users', { params: { period } }),
  
  getServiceStats: (period?: string) =>
    api.get('/admin/reports/services', { params: { period } }),
};