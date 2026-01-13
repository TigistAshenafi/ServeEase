'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Layout from '@/components/Layout';
import { isAuthenticated, getCurrentUser } from '@/lib/auth';
import { settingsAPI } from '@/lib/api';
import { formatDate } from '@/lib/utils';
import toast, { Toaster } from 'react-hot-toast';
import ConfirmDialog from '@/components/ConfirmDialog';
import {
  UserCircleIcon,
  KeyIcon,
  GlobeAltIcon,
  BellIcon,
  CogIcon,
  ServerIcon,
  ShieldCheckIcon,
  ExclamationTriangleIcon,
} from '@heroicons/react/24/outline';

interface User {
  id: string;
  name: string;
  email: string;
  role: string;
}

interface AppSettings {
  [category: string]: Array<{
    key: string;
    value: string;
    description: string;
    isPublic: boolean;
    updatedAt: string;
  }>;
}

interface AdminPreferences {
  notifications: {
    email: boolean;
    providerApprovals: boolean;
    systemAlerts: boolean;
    userRegistrations: boolean;
  };
  display: {
    language: string;
    timezone: string;
    dateFormat: string;
    theme: string;
  };
  dashboard: {
    defaultView: string;
    refreshInterval: number;
    showWelcomeMessage: boolean;
  };
}

export default function SettingsPage() {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('profile');
  const [appSettings, setAppSettings] = useState<AppSettings>({});
  const [preferences, setPreferences] = useState<AdminPreferences | null>(null);
  const [systemInfo, setSystemInfo] = useState<any>(null);
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    currentPassword: '',
    newPassword: '',
    confirmPassword: '',
  });
  const [passwordDialog, setPasswordDialog] = useState({ isOpen: false });
  const [settingToUpdate, setSettingToUpdate] = useState<{ key: string; value: string; description: string } | null>(null);
  const router = useRouter();

  useEffect(() => {
    if (!isAuthenticated()) {
      router.push('/login');
      return;
    }

    fetchInitialData();
  }, [router]);

  const fetchInitialData = async () => {
    try {
      setLoading(true);
      
      // Fetch user profile
      const userData = await getCurrentUser();
      setUser(userData);
      setFormData(prev => ({
        ...prev,
        name: userData.name,
        email: userData.email,
      }));

      // Fetch app settings
      const settingsResponse = await settingsAPI.getAppSettings();
      if (settingsResponse.data.success) {
        setAppSettings(settingsResponse.data.settings);
      }

      // Fetch admin preferences
      const preferencesResponse = await settingsAPI.getPreferences();
      if (preferencesResponse.data.success) {
        setPreferences(preferencesResponse.data.preferences);
      }

      // Fetch system info
      const systemResponse = await settingsAPI.getSystemInfo();
      if (systemResponse.data.success) {
        setSystemInfo(systemResponse.data.systemInfo);
      }

    } catch (error: any) {
      const errorMessage = error.response?.data?.message || 'Failed to load settings';
      toast.error(errorMessage);
      console.error('Settings fetch error:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleProfileUpdate = async (e: React.FormEvent) => {
    e.preventDefault();
    
    try {
      const updateData: any = {};
      if (formData.name !== user?.name) updateData.name = formData.name;
      if (formData.email !== user?.email) updateData.email = formData.email;

      if (Object.keys(updateData).length === 0) {
        toast.error('No changes to save');
        return;
      }

      const response = await settingsAPI.updateProfile(updateData);
      if (response.data.success) {
        setUser(response.data.user);
        toast.success('Profile updated successfully');
      }
    } catch (error: any) {
      const errorMessage = error.response?.data?.message || 'Failed to update profile';
      toast.error(errorMessage);
    }
  };

  const handlePasswordChange = async () => {
    if (formData.newPassword !== formData.confirmPassword) {
      toast.error('New passwords do not match');
      return;
    }

    if (formData.newPassword.length < 6) {
      toast.error('Password must be at least 6 characters long');
      return;
    }

    try {
      await settingsAPI.changePassword({
        currentPassword: formData.currentPassword,
        newPassword: formData.newPassword
      });
      
      toast.success('Password changed successfully');
      setFormData(prev => ({
        ...prev,
        currentPassword: '',
        newPassword: '',
        confirmPassword: ''
      }));
    } catch (error: any) {
      const errorMessage = error.response?.data?.message || 'Failed to change password';
      toast.error(errorMessage);
    }
  };

  const handlePreferencesUpdate = async (section: string, key: string, value: any) => {
    if (!preferences) return;

    try {
      const updatedPreferences = {
        ...preferences,
        [section]: {
          ...preferences[section as keyof AdminPreferences],
          [key]: value
        }
      };

      await settingsAPI.updatePreferences(updatedPreferences);
      setPreferences(updatedPreferences);
      toast.success('Preferences updated');
    } catch (error: any) {
      const errorMessage = error.response?.data?.message || 'Failed to update preferences';
      toast.error(errorMessage);
    }
  };

  const handleSettingUpdate = async (key: string, newValue: string) => {
    try {
      await settingsAPI.updateAppSetting(key, newValue);
      
      // Update local state
      const updatedSettings = { ...appSettings };
      Object.keys(updatedSettings).forEach(category => {
        updatedSettings[category] = updatedSettings[category].map(setting => 
          setting.key === key ? { ...setting, value: newValue } : setting
        );
      });
      setAppSettings(updatedSettings);
      
      toast.success('Setting updated successfully');
    } catch (error: any) {
      const errorMessage = error.response?.data?.message || 'Failed to update setting';
      toast.error(errorMessage);
    }
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value,
    });
  };

  const formatBytes = (bytes: number) => {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  };

  const formatUptime = (seconds: number) => {
    const days = Math.floor(seconds / 86400);
    const hours = Math.floor((seconds % 86400) / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    return `${days}d ${hours}h ${minutes}m`;
  };

  const tabs = [
    { id: 'profile', name: 'Profile', icon: UserCircleIcon },
    { id: 'security', name: 'Security', icon: KeyIcon },
    { id: 'notifications', name: 'Notifications', icon: BellIcon },
    { id: 'display', name: 'Display', icon: GlobeAltIcon },
    { id: 'system', name: 'System Settings', icon: CogIcon },
    { id: 'info', name: 'System Info', icon: ServerIcon },
  ];

  if (loading) {
    return (
      <Layout>
        <div className="flex items-center justify-center h-64">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
        </div>
      </Layout>
    );
  }

  return (
    <Layout>
      <Toaster position="top-right" />
      
      {/* Password Change Confirmation Dialog */}
      <ConfirmDialog
        isOpen={passwordDialog.isOpen}
        onClose={() => setPasswordDialog({ isOpen: false })}
        onConfirm={handlePasswordChange}
        title="Change Password"
        message="Are you sure you want to change your password? You will need to use the new password for future logins."
        confirmText="Change Password"
        cancelText="Cancel"
        type="warning"
      />
      
      <div className="space-y-8">
        {/* Enhanced Header */}
        <div className="bg-gradient-to-r from-blue-600 to-blue-700 rounded-xl p-8 text-white">
          <div className="flex justify-between items-start">
            <div>
              <h1 className="text-3xl font-bold mb-2">Settings</h1>
              <p className="text-blue-100 text-lg">Manage your account settings and system configuration</p>
              <div className="flex items-center space-x-6 mt-4">
                <div className="flex items-center space-x-2">
                  <ShieldCheckIcon className="h-5 w-5 text-blue-200" />
                  <span className="text-blue-100">Admin Access</span>
                </div>
                <div className="flex items-center space-x-2">
                  <UserCircleIcon className="h-5 w-5 text-blue-200" />
                  <span className="text-blue-100">{user?.name}</span>
                </div>
              </div>
            </div>
            <div className="text-right">
              <p className="text-blue-100 text-sm">Last Updated</p>
              <p className="text-white font-medium">{new Date().toLocaleDateString()}</p>
            </div>
          </div>
        </div>

        <div className="flex space-x-8">
          {/* Sidebar */}
          <div className="w-64">
            <nav className="space-y-1">
              {tabs.map((tab) => (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  className={`w-full flex items-center px-4 py-3 text-sm font-medium rounded-lg transition-all duration-200 ${
                    activeTab === tab.id
                      ? 'bg-blue-600 text-white shadow-md'
                      : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
                  }`}
                >
                  <tab.icon className="mr-3 h-5 w-5" />
                  {tab.name}
                </button>
              ))}
            </nav>
          </div>

          {/* Content */}
          <div className="flex-1 max-w-4xl">
            {activeTab === 'profile' && (
              <div className="bg-white shadow-sm rounded-xl border border-gray-200 p-8">
                <h3 className="text-xl font-semibold text-gray-900 mb-6">Profile Information</h3>
                <form onSubmit={handleProfileUpdate} className="space-y-6">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">Full Name</label>
                      <input
                        type="text"
                        name="name"
                        value={formData.name}
                        onChange={handleInputChange}
                        className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-200"
                        placeholder="Enter your full name"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">Email Address</label>
                      <input
                        type="email"
                        name="email"
                        value={formData.email}
                        onChange={handleInputChange}
                        className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-200"
                        placeholder="Enter your email address"
                      />
                    </div>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">Role</label>
                    <input
                      type="text"
                      value={user?.role || ''}
                      disabled
                      className="w-full px-4 py-3 border border-gray-300 rounded-lg bg-gray-50 text-gray-500 cursor-not-allowed"
                    />
                  </div>
                  <div className="flex justify-end">
                    <button
                      type="submit"
                      className="bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-all duration-200 font-medium"
                    >
                      Update Profile
                    </button>
                  </div>
                </form>
              </div>
            )}

            {activeTab === 'security' && (
              <div className="bg-white shadow-sm rounded-xl border border-gray-200 p-8">
                <h3 className="text-xl font-semibold text-gray-900 mb-6">Security Settings</h3>
                <form onSubmit={(e) => { e.preventDefault(); setPasswordDialog({ isOpen: true }); }} className="space-y-6">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">Current Password</label>
                    <input
                      type="password"
                      name="currentPassword"
                      value={formData.currentPassword}
                      onChange={handleInputChange}
                      className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-200"
                      placeholder="Enter your current password"
                      required
                    />
                  </div>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">New Password</label>
                      <input
                        type="password"
                        name="newPassword"
                        value={formData.newPassword}
                        onChange={handleInputChange}
                        className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-200"
                        placeholder="Enter new password"
                        required
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">Confirm New Password</label>
                      <input
                        type="password"
                        name="confirmPassword"
                        value={formData.confirmPassword}
                        onChange={handleInputChange}
                        className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-200"
                        placeholder="Confirm new password"
                        required
                      />
                    </div>
                  </div>
                  <div className="bg-amber-50 border border-amber-200 rounded-lg p-4">
                    <div className="flex">
                      <ExclamationTriangleIcon className="h-5 w-5 text-amber-400 mr-2 mt-0.5" />
                      <div>
                        <h4 className="text-sm font-medium text-amber-800">Password Requirements</h4>
                        <ul className="text-sm text-amber-700 mt-1 list-disc list-inside">
                          <li>Minimum 6 characters long</li>
                          <li>Use a strong, unique password</li>
                          <li>Consider using a password manager</li>
                        </ul>
                      </div>
                    </div>
                  </div>
                  <div className="flex justify-end">
                    <button
                      type="submit"
                      className="bg-red-600 text-white px-6 py-3 rounded-lg hover:bg-red-700 focus:ring-2 focus:ring-red-500 focus:ring-offset-2 transition-all duration-200 font-medium"
                    >
                      Change Password
                    </button>
                  </div>
                </form>
              </div>
            )}

            {activeTab === 'notifications' && preferences && (
              <div className="bg-white shadow-sm rounded-xl border border-gray-200 p-8">
                <h3 className="text-xl font-semibold text-gray-900 mb-6">Notification Preferences</h3>
                <div className="space-y-6">
                  {[
                    { key: 'email', label: 'Email Notifications', description: 'Receive notifications via email' },
                    { key: 'providerApprovals', label: 'Provider Approvals', description: 'Get notified when providers need approval' },
                    { key: 'systemAlerts', label: 'System Alerts', description: 'Receive system maintenance and security alerts' },
                    { key: 'userRegistrations', label: 'User Registrations', description: 'Get notified about new user registrations' }
                  ].map((notification) => (
                    <div key={notification.key} className="flex items-center justify-between p-4 border border-gray-200 rounded-lg">
                      <div>
                        <h4 className="text-sm font-medium text-gray-900">{notification.label}</h4>
                        <p className="text-sm text-gray-500">{notification.description}</p>
                      </div>
                      <label className="relative inline-flex items-center cursor-pointer">
                        <input
                          type="checkbox"
                          checked={preferences.notifications[notification.key as keyof typeof preferences.notifications]}
                          onChange={(e) => handlePreferencesUpdate('notifications', notification.key, e.target.checked)}
                          className="sr-only peer"
                        />
                        <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                      </label>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {activeTab === 'display' && preferences && (
              <div className="bg-white shadow-sm rounded-xl border border-gray-200 p-8">
                <h3 className="text-xl font-semibold text-gray-900 mb-6">Display Settings</h3>
                <div className="space-y-6">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">Language</label>
                      <select 
                        value={preferences.display.language}
                        onChange={(e) => handlePreferencesUpdate('display', 'language', e.target.value)}
                        className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-200"
                      >
                        <option value="en">English</option>
                        <option value="am">አማርኛ (Amharic)</option>
                      </select>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">Time Zone</label>
                      <select 
                        value={preferences.display.timezone}
                        onChange={(e) => handlePreferencesUpdate('display', 'timezone', e.target.value)}
                        className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-200"
                      >
                        <option value="UTC">UTC</option>
                        <option value="Africa/Addis_Ababa">Africa/Addis Ababa</option>
                        <option value="America/New_York">America/New York</option>
                        <option value="Europe/London">Europe/London</option>
                      </select>
                    </div>
                  </div>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">Date Format</label>
                      <select 
                        value={preferences.display.dateFormat}
                        onChange={(e) => handlePreferencesUpdate('display', 'dateFormat', e.target.value)}
                        className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-200"
                      >
                        <option value="MM/dd/yyyy">MM/dd/yyyy</option>
                        <option value="dd/MM/yyyy">dd/MM/yyyy</option>
                        <option value="yyyy-MM-dd">yyyy-MM-dd</option>
                      </select>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">Theme</label>
                      <select 
                        value={preferences.display.theme}
                        onChange={(e) => handlePreferencesUpdate('display', 'theme', e.target.value)}
                        className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-200"
                      >
                        <option value="light">Light</option>
                        <option value="dark">Dark</option>
                        <option value="auto">Auto</option>
                      </select>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {activeTab === 'system' && (
              <div className="space-y-6">
                {Object.entries(appSettings).map(([category, settings]) => (
                  <div key={category} className="bg-white shadow-sm rounded-xl border border-gray-200 p-8">
                    <h3 className="text-xl font-semibold text-gray-900 mb-6 capitalize">
                      {category.replace('_', ' ')} Settings
                    </h3>
                    <div className="space-y-4">
                      {settings.map((setting) => (
                        <div key={setting.key} className="flex items-center justify-between p-4 border border-gray-200 rounded-lg">
                          <div className="flex-1">
                            <h4 className="text-sm font-medium text-gray-900">{setting.key.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())}</h4>
                            <p className="text-sm text-gray-500">{setting.description}</p>
                            <p className="text-xs text-gray-400 mt-1">Last updated: {formatDate(setting.updatedAt)}</p>
                          </div>
                          <div className="ml-4">
                            {setting.key.includes('enabled') || setting.key.includes('mode') ? (
                              <label className="relative inline-flex items-center cursor-pointer">
                                <input
                                  type="checkbox"
                                  checked={setting.value === 'true'}
                                  onChange={(e) => handleSettingUpdate(setting.key, e.target.checked ? 'true' : 'false')}
                                  className="sr-only peer"
                                />
                                <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                              </label>
                            ) : (
                              <input
                                type="text"
                                value={setting.value}
                                onChange={(e) => handleSettingUpdate(setting.key, e.target.value)}
                                className="px-3 py-2 border border-gray-300 rounded-md text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                              />
                            )}
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                ))}
              </div>
            )}

            {activeTab === 'info' && systemInfo && (
              <div className="space-y-6">
                {/* Database Stats */}
                <div className="bg-white shadow-sm rounded-xl border border-gray-200 p-8">
                  <h3 className="text-xl font-semibold text-gray-900 mb-6">Database Statistics</h3>
                  <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
                    {[
                      { label: 'Users', value: systemInfo.database.totalUsers, color: 'blue' },
                      { label: 'Providers', value: systemInfo.database.totalProviders, color: 'green' },
                      { label: 'Services', value: systemInfo.database.totalServices, color: 'purple' },
                      { label: 'Requests', value: systemInfo.database.totalRequests, color: 'orange' },
                      { label: 'Logs', value: systemInfo.database.totalLogs, color: 'red' }
                    ].map((stat) => (
                      <div key={stat.label} className="text-center p-4 bg-gray-50 rounded-lg">
                        <div className={`text-2xl font-bold text-${stat.color}-600`}>{stat.value.toLocaleString()}</div>
                        <div className="text-sm text-gray-600">{stat.label}</div>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Server Info */}
                <div className="bg-white shadow-sm rounded-xl border border-gray-200 p-8">
                  <h3 className="text-xl font-semibold text-gray-900 mb-6">Server Information</h3>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div className="space-y-4">
                      <div className="flex justify-between">
                        <span className="text-gray-600">Node.js Version:</span>
                        <span className="font-medium">{systemInfo.server.nodeVersion}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-gray-600">Platform:</span>
                        <span className="font-medium">{systemInfo.server.platform}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-gray-600">Uptime:</span>
                        <span className="font-medium">{formatUptime(systemInfo.server.uptime)}</span>
                      </div>
                    </div>
                    <div className="space-y-4">
                      <div className="flex justify-between">
                        <span className="text-gray-600">Memory Usage:</span>
                        <span className="font-medium">{formatBytes(systemInfo.server.memoryUsage.rss)}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-gray-600">Heap Used:</span>
                        <span className="font-medium">{formatBytes(systemInfo.server.memoryUsage.heapUsed)}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-gray-600">Heap Total:</span>
                        <span className="font-medium">{formatBytes(systemInfo.server.memoryUsage.heapTotal)}</span>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Recent Activity */}
                <div className="bg-white shadow-sm rounded-xl border border-gray-200 p-8">
                  <h3 className="text-xl font-semibold text-gray-900 mb-6">Recent System Activity</h3>
                  <div className="space-y-3">
                    {systemInfo.recentActivity.map((activity: any, index: number) => (
                      <div key={index} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                        <div>
                          <span className="text-sm font-medium text-gray-900">{activity.type.replace('_', ' ').replace(/\b\w/g, (l: string) => l.toUpperCase())}</span>
                          <p className="text-sm text-gray-600">{activity.description}</p>
                        </div>
                        <span className="text-xs text-gray-500">{formatDate(activity.created_at)}</span>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </Layout>
  );
}