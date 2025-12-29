import Cookies from 'js-cookie';
import { authAPI } from './api';

export const AUTH_TOKEN_KEY = 'adminToken';

export const setAuthToken = (token: string) => {
  Cookies.set(AUTH_TOKEN_KEY, token, { expires: 7 }); // 7 days
};

export const getAuthToken = () => {
  return Cookies.get(AUTH_TOKEN_KEY);
};

export const removeAuthToken = () => {
  Cookies.remove(AUTH_TOKEN_KEY);
};

export const isAuthenticated = () => {
  return !!getAuthToken();
};

export const login = async (email: string, password: string) => {
  try {
    const response = await authAPI.login(email, password);
    
    if (response.data.success && response.data.user.role === 'admin') {
      setAuthToken(response.data.accessToken);
      return { success: true, user: response.data.user };
    } else {
      return { success: false, message: 'Access denied. Admin privileges required.' };
    }
  } catch (error: any) {
    return { 
      success: false, 
      message: error.response?.data?.message || 'Login failed' 
    };
  }
};

export const logout = () => {
  removeAuthToken();
  window.location.href = '/login';
};

export const getCurrentUser = async () => {
  try {
    const response = await authAPI.getProfile();
    return response.data.user;
  } catch (error) {
    removeAuthToken();
    throw error;
  }
};