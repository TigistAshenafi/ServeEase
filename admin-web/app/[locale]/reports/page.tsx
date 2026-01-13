'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Layout from '@/components/Layout';
import { isAuthenticated } from '@/lib/auth';
import { reportsAPI } from '@/lib/api';
import { formatNumber } from '@/lib/utils';
import toast, { Toaster } from 'react-hot-toast';
import {
  ChartBarIcon,
  DocumentArrowDownIcon,
  CalendarIcon,
  UsersIcon,
  BuildingOfficeIcon,
  ArrowTrendingUpIcon,
  ArrowTrendingDownIcon,
  ClockIcon,
  CheckCircleIcon,
  ExclamationTriangleIcon,
  EyeIcon,
} from '@heroicons/react/24/outline';

interface ActivityLog {
  id: string;
  type: 'user_registration' | 'provider_approval' | 'service_creation' | 'request_completion' | 'payment_processed' | 'system_alert';
  description: string;
  user: {
    name: string;
    email: string;
    role: string;
  };
  timestamp: string;
  severity: 'info' | 'success' | 'warning' | 'error';
  metadata?: any;
}

interface ReportStats {
  totalUsers: number;
  userGrowth: number;
  totalProviders: number;
  providerGrowth: number;
  completedRequests: number;
  requestGrowth: number;
  totalRequests: number;
  activeServices: number;
  serviceGrowth?: number;
  pendingProviders: number;
}

interface UserStats {
  date: string;
  count: number;
  role: string;
}

interface ServiceStats {
  date: string;
  count: number;
  category: string;
}

export default function ReportsPage() {
  const [activityLogs, setActivityLogs] = useState<ActivityLog[]>([]);
  const [stats, setStats] = useState<ReportStats | null>(null);
  const [userStats, setUserStats] = useState<UserStats[]>([]);
  const [serviceStats, setServiceStats] = useState<ServiceStats[]>([]);
  const [loading, setLoading] = useState(true);
  const [dateRange, setDateRange] = useState('30d');
  const [selectedReport, setSelectedReport] = useState<'overview' | 'users' | 'providers' | 'activity'>('overview');
  const router = useRouter();

  useEffect(() => {
    if (!isAuthenticated()) {
      router.push('/login');
      return;
    }

    fetchReportsData();
  }, [router, dateRange]);

  const fetchReportsData = async () => {
    try {
      setLoading(true);
      
      // Fetch dashboard stats
      try {
        const statsResponse = await reportsAPI.getDashboardStats();
        if (statsResponse.data.success) {
          setStats(statsResponse.data);
        }
      } catch (error) {
        console.error('Failed to fetch dashboard stats:', error);
        toast.error('Failed to load dashboard statistics');
      }

      // Fetch activity logs
      try {
        const logsResponse = await reportsAPI.getActivityLogs({ limit: 10 });
        if (logsResponse.data.success) {
          setActivityLogs(logsResponse.data.logs || []);
        }
      } catch (error) {
        console.error('Failed to fetch activity logs:', error);
        toast.error('Failed to load activity logs');
        // Set empty array so UI doesn't break
        setActivityLogs([]);
      }

      // Fetch user stats based on selected period
      if (selectedReport === 'users' || selectedReport === 'overview') {
        try {
          const userStatsResponse = await reportsAPI.getUserStats(dateRange);
          if (userStatsResponse.data.success) {
            setUserStats(userStatsResponse.data.stats || []);
          }
        } catch (error) {
          console.error('Failed to fetch user stats:', error);
          setUserStats([]);
        }
      }

      // Fetch service stats based on selected period
      if (selectedReport === 'providers' || selectedReport === 'overview') {
        try {
          const serviceStatsResponse = await reportsAPI.getServiceStats(dateRange);
          if (serviceStatsResponse.data.success) {
            setServiceStats(serviceStatsResponse.data.stats || []);
          }
        } catch (error) {
          console.error('Failed to fetch service stats:', error);
          setServiceStats([]);
        }
      }

    } catch (error) {
      console.error('General reports fetch error:', error);
      toast.error('Failed to load reports data');
    } finally {
      setLoading(false);
    }
  };

  const handleExportData = async (reportType: string) => {
    try {
      let data;
      let filename;

      switch (reportType) {
        case 'comprehensive':
          data = {
            stats,
            userStats,
            serviceStats,
            activityLogs,
            exportedAt: new Date().toISOString()
          };
          filename = `serveease-comprehensive-report-${new Date().toISOString().split('T')[0]}.json`;
          break;
        case 'users':
          data = { userStats, exportedAt: new Date().toISOString() };
          filename = `serveease-user-stats-${dateRange}-${new Date().toISOString().split('T')[0]}.json`;
          break;
        case 'providers':
          data = { serviceStats, exportedAt: new Date().toISOString() };
          filename = `serveease-service-stats-${dateRange}-${new Date().toISOString().split('T')[0]}.json`;
          break;
        case 'activity':
          data = { activityLogs, exportedAt: new Date().toISOString() };
          filename = `serveease-activity-logs-${new Date().toISOString().split('T')[0]}.json`;
          break;
        default:
          data = stats;
          filename = `serveease-${reportType}-report-${new Date().toISOString().split('T')[0]}.json`;
      }

      // Create and download file
      const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
      const url = URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = filename;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      URL.revokeObjectURL(url);

      toast.success(`${reportType} report exported successfully`);
    } catch (error) {
      toast.error(`Failed to export ${reportType} report`);
      console.error('Export error:', error);
    }
  };

  const getActivityIcon = (type: string) => {
    switch (type) {
      case 'user_registration':
        return <UsersIcon className="h-5 w-5" />;
      case 'provider_approval':
        return <CheckCircleIcon className="h-5 w-5" />;
      case 'service_creation':
        return <BuildingOfficeIcon className="h-5 w-5" />;
      case 'request_completion':
        return <CheckCircleIcon className="h-5 w-5" />;
      case 'payment_processed':
        return <CheckCircleIcon className="h-5 w-5" />;
      case 'system_alert':
        return <ExclamationTriangleIcon className="h-5 w-5" />;
      default:
        return <ClockIcon className="h-5 w-5" />;
    }
  };

  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case 'success':
        return 'text-emerald-600 bg-emerald-50 border-emerald-200';
      case 'warning':
        return 'text-amber-600 bg-amber-50 border-amber-200';
      case 'error':
        return 'text-red-600 bg-red-50 border-red-200';
      default:
        return 'text-blue-600 bg-blue-50 border-blue-200';
    }
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount);
  };

  const formatNumber = (num: number) => {
    return new Intl.NumberFormat('en-US').format(num);
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleString('en-US', {
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

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
      
      <div className="space-y-8">
        {/* Enhanced Header */}
        <div className="bg-gradient-to-r from-blue-600 to-blue-700 rounded-xl p-8 text-white">
          <div className="flex justify-between items-start">
            <div>
              <h1 className="text-3xl font-bold mb-2">Reports & Analytics</h1>
              <p className="text-blue-100 text-lg">Comprehensive platform insights and performance metrics</p>
              <div className="flex items-center space-x-6 mt-4">
                <div className="flex items-center space-x-2">
                  <ChartBarIcon className="h-5 w-5 text-blue-200" />
                  <span className="text-blue-100">Real-time data</span>
                </div>
                <div className="flex items-center space-x-2">
                  <CalendarIcon className="h-5 w-5 text-blue-200" />
                  <span className="text-blue-100">Last {dateRange === '7d' ? '7 days' : dateRange === '30d' ? '30 days' : dateRange === '90d' ? '90 days' : 'year'}</span>
                </div>
              </div>
            </div>
            <button
              onClick={() => handleExportData('comprehensive')}
              className="bg-white text-blue-600 px-6 py-3 rounded-lg font-medium hover:bg-blue-50 transition-colors duration-200 flex items-center space-x-2 shadow-lg"
            >
              <DocumentArrowDownIcon className="h-5 w-5" />
              <span>Export All</span>
            </button>
          </div>
        </div>

        {/* Report Navigation */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <div className="flex flex-wrap gap-3">
            {[
              { key: 'overview', label: 'Overview', icon: ChartBarIcon },
              { key: 'users', label: 'User Analytics', icon: UsersIcon },
              { key: 'providers', label: 'Provider Metrics', icon: BuildingOfficeIcon },
              { key: 'activity', label: 'Activity Logs', icon: ClockIcon }
            ].map((report) => (
              <button
                key={report.key}
                onClick={() => setSelectedReport(report.key as any)}
                className={`px-4 py-2 rounded-lg text-sm font-medium transition-all duration-200 flex items-center space-x-2 ${
                  selectedReport === report.key
                    ? 'bg-blue-600 text-white shadow-md'
                    : 'bg-gray-50 text-gray-700 border border-gray-200 hover:bg-gray-100 hover:border-gray-300'
                }`}
              >
                <report.icon className="h-4 w-4" />
                <span>{report.label}</span>
              </button>
            ))}
          </div>

          {/* Date Range Filter */}
          <div className="flex items-center space-x-4 mt-6">
            <label className="text-sm font-medium text-gray-700">Time Period:</label>
            <select
              value={dateRange}
              onChange={(e) => setDateRange(e.target.value)}
              className="border border-gray-300 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >
              <option value="7d">Last 7 days</option>
              <option value="30d">Last 30 days</option>
              <option value="90d">Last 90 days</option>
              <option value="1y">Last year</option>
            </select>
          </div>
        </div>

        {/* Overview Stats Cards */}
        {selectedReport === 'overview' && stats && (
          <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {[
              {
                name: 'Active Users',
                value: formatNumber(stats.totalUsers),
                change: stats.userGrowth,
                icon: UsersIcon,
                color: 'text-blue-600',
                bgColor: 'bg-gradient-to-br from-blue-50 to-blue-100',
                borderColor: 'border-blue-200'
              },
              {
                name: 'Providers',
                value: formatNumber(stats.totalProviders),
                change: stats.providerGrowth,
                icon: BuildingOfficeIcon,
                color: 'text-purple-600',
                bgColor: 'bg-gradient-to-br from-purple-50 to-purple-100',
                borderColor: 'border-purple-200'
              },
              {
                name: 'Completed Requests',
                value: formatNumber(stats.completedRequests),
                change: stats.requestGrowth,
                icon: CheckCircleIcon,
                color: 'text-amber-600',
                bgColor: 'bg-gradient-to-br from-amber-50 to-amber-100',
                borderColor: 'border-amber-200'
              }
            ].map((stat) => (
              <div
                key={stat.name}
                className={`${stat.bgColor} ${stat.borderColor} border rounded-xl p-6 shadow-sm hover:shadow-md transition-all duration-200`}
              >
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium text-gray-600 mb-1">
                      {stat.name}
                    </p>
                    <p className="text-3xl font-bold text-gray-900 mb-2">
                      {stat.value}
                    </p>
                    <div className={`flex items-center text-sm font-medium ${
                      stat.change > 0 ? 'text-emerald-600' : stat.change < 0 ? 'text-red-600' : 'text-gray-500'
                    }`}>
                      {stat.change > 0 ? (
                        <ArrowTrendingUpIcon className="h-4 w-4 mr-1" />
                      ) : stat.change < 0 ? (
                        <ArrowTrendingDownIcon className="h-4 w-4 mr-1" />
                      ) : null}
                      <span>
                        {stat.change === 0 ? 'No change' : `${Math.abs(stat.change)}% from last period`}
                      </span>
                    </div>
                  </div>
                  <div className={`${stat.color} ${stat.bgColor} p-3 rounded-lg`}>
                    <stat.icon className="h-8 w-8" />
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* Additional Stats for Overview */}
        {selectedReport === 'overview' && stats && (
          <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
            <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-semibold text-gray-900">Service Overview</h3>
                <BuildingOfficeIcon className="h-6 w-6 text-blue-600" />
              </div>
              <div className="space-y-3">
                <div className="flex justify-between">
                  <span className="text-gray-600">Active Services</span>
                  <span className="font-semibold">{formatNumber(stats.activeServices || 0)}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Total Requests</span>
                  <span className="font-semibold">{formatNumber(stats.totalRequests || 0)}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Completion Rate</span>
                  <span className="font-semibold text-emerald-600">
                    {stats.totalRequests > 0 ? Math.round((stats.completedRequests / stats.totalRequests) * 100) : 0}%
                  </span>
                </div>
              </div>
            </div>

            <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-semibold text-gray-900">Provider Status</h3>
                <UsersIcon className="h-6 w-6 text-purple-600" />
              </div>
              <div className="space-y-3">
                <div className="flex justify-between">
                  <span className="text-gray-600">Approved Providers</span>
                  <span className="font-semibold text-emerald-600">{formatNumber(stats.totalProviders)}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Pending Approval</span>
                  <span className="font-semibold text-amber-600">{formatNumber(stats.pendingProviders || 0)}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Approval Rate</span>
                  <span className="font-semibold">
                    {(stats.totalProviders + stats.pendingProviders) > 0 
                      ? Math.round((stats.totalProviders / (stats.totalProviders + stats.pendingProviders)) * 100) 
                      : 0}%
                  </span>
                </div>
              </div>
            </div>

            <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-semibold text-gray-900">Growth Metrics</h3>
                <ChartBarIcon className="h-6 w-6 text-emerald-600" />
              </div>
              <div className="space-y-3">
                <div className="flex justify-between">
                  <span className="text-gray-600">User Growth</span>
                  <span className={`font-semibold ${stats.userGrowth >= 0 ? 'text-emerald-600' : 'text-red-600'}`}>
                    {stats.userGrowth >= 0 ? '+' : ''}{stats.userGrowth}%
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Provider Growth</span>
                  <span className={`font-semibold ${stats.providerGrowth >= 0 ? 'text-emerald-600' : 'text-red-600'}`}>
                    {stats.providerGrowth >= 0 ? '+' : ''}{stats.providerGrowth}%
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Request Growth</span>
                  <span className={`font-semibold ${stats.requestGrowth >= 0 ? 'text-emerald-600' : 'text-red-600'}`}>
                    {stats.requestGrowth >= 0 ? '+' : ''}{stats.requestGrowth}%
                  </span>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* User Analytics */}
        {selectedReport === 'users' && (
          <div className="space-y-6">
            <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
              <div className="flex items-center justify-between mb-6">
                <h3 className="text-lg font-semibold text-gray-900">User Registration Trends</h3>
                <button
                  onClick={() => handleExportData('users')}
                  className="text-blue-600 hover:text-blue-700 text-sm font-medium"
                >
                  Export Data
                </button>
              </div>
              
              {userStats.length === 0 ? (
                <div className="text-center py-12">
                  <UsersIcon className="mx-auto h-16 w-16 text-gray-300 mb-4" />
                  <h3 className="text-lg font-medium text-gray-900 mb-2">No user data available</h3>
                  <p className="text-gray-500">User registration data will appear here once available</p>
                </div>
              ) : (
                <div className="space-y-4">
                  <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
                    <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
                      <div className="flex items-center">
                        <UsersIcon className="h-8 w-8 text-blue-600 mr-3" />
                        <div>
                          <p className="text-sm font-medium text-blue-600">Total Seekers</p>
                          <p className="text-2xl font-bold text-blue-900">
                            {userStats.filter(s => s.role === 'seeker').reduce((sum, s) => sum + s.count, 0)}
                          </p>
                        </div>
                      </div>
                    </div>
                    <div className="bg-purple-50 border border-purple-200 rounded-lg p-4">
                      <div className="flex items-center">
                        <BuildingOfficeIcon className="h-8 w-8 text-purple-600 mr-3" />
                        <div>
                          <p className="text-sm font-medium text-purple-600">Total Providers</p>
                          <p className="text-2xl font-bold text-purple-900">
                            {userStats.filter(s => s.role === 'provider').reduce((sum, s) => sum + s.count, 0)}
                          </p>
                        </div>
                      </div>
                    </div>
                    <div className="bg-emerald-50 border border-emerald-200 rounded-lg p-4">
                      <div className="flex items-center">
                        <ChartBarIcon className="h-8 w-8 text-emerald-600 mr-3" />
                        <div>
                          <p className="text-sm font-medium text-emerald-600">Daily Average</p>
                          <p className="text-2xl font-bold text-emerald-900">
                            {Math.round(userStats.reduce((sum, s) => sum + s.count, 0) / Math.max(userStats.length, 1))}
                          </p>
                        </div>
                      </div>
                    </div>
                  </div>
                  
                  <div className="overflow-x-auto">
                    <table className="min-w-full divide-y divide-gray-200">
                      <thead className="bg-gray-50">
                        <tr>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Date</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Role</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Registrations</th>
                        </tr>
                      </thead>
                      <tbody className="bg-white divide-y divide-gray-200">
                        {userStats.map((stat, index) => (
                          <tr key={index} className="hover:bg-gray-50">
                            <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                              {new Date(stat.date).toLocaleDateString()}
                            </td>
                            <td className="px-6 py-4 whitespace-nowrap">
                              <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
                                stat.role === 'seeker' ? 'bg-blue-100 text-blue-800' : 'bg-purple-100 text-purple-800'
                              }`}>
                                {stat.role}
                              </span>
                            </td>
                            <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                              {stat.count}
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </div>
              )}
            </div>
          </div>
        )}

        {/* Provider/Service Analytics */}
        {selectedReport === 'providers' && (
          <div className="space-y-6">
            <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
              <div className="flex items-center justify-between mb-6">
                <h3 className="text-lg font-semibold text-gray-900">Service Creation Trends</h3>
                <button
                  onClick={() => handleExportData('providers')}
                  className="text-blue-600 hover:text-blue-700 text-sm font-medium"
                >
                  Export Data
                </button>
              </div>
              
              {serviceStats.length === 0 ? (
                <div className="text-center py-12">
                  <BuildingOfficeIcon className="mx-auto h-16 w-16 text-gray-300 mb-4" />
                  <h3 className="text-lg font-medium text-gray-900 mb-2">No service data available</h3>
                  <p className="text-gray-500">Service creation data will appear here once available</p>
                </div>
              ) : (
                <div className="space-y-4">
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
                    {Array.from(new Set(serviceStats.map(s => s.category))).map(category => (
                      <div key={category} className="bg-gradient-to-br from-indigo-50 to-indigo-100 border border-indigo-200 rounded-lg p-4">
                        <div className="flex items-center">
                          <BuildingOfficeIcon className="h-6 w-6 text-indigo-600 mr-2" />
                          <div>
                            <p className="text-sm font-medium text-indigo-600">{category || 'Uncategorized'}</p>
                            <p className="text-xl font-bold text-indigo-900">
                              {serviceStats.filter(s => s.category === category).reduce((sum, s) => sum + s.count, 0)}
                            </p>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                  
                  <div className="overflow-x-auto">
                    <table className="min-w-full divide-y divide-gray-200">
                      <thead className="bg-gray-50">
                        <tr>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Date</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Category</th>
                          <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Services Created</th>
                        </tr>
                      </thead>
                      <tbody className="bg-white divide-y divide-gray-200">
                        {serviceStats.map((stat, index) => (
                          <tr key={index} className="hover:bg-gray-50">
                            <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                              {new Date(stat.date).toLocaleDateString()}
                            </td>
                            <td className="px-6 py-4 whitespace-nowrap">
                              <span className="inline-flex px-2 py-1 text-xs font-semibold rounded-full bg-indigo-100 text-indigo-800">
                                {stat.category || 'Uncategorized'}
                              </span>
                            </td>
                            <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                              {stat.count}
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </div>
              )}
            </div>
          </div>
        )}

        {/* Activity Logs */}
        {selectedReport === 'activity' && (
          <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
            <div className="px-6 py-4 border-b border-gray-200">
              <div className="flex items-center justify-between">
                <h3 className="text-lg font-semibold text-gray-900">
                  Recent Activity
                </h3>
                <div className="flex items-center space-x-2">
                  <span className="text-sm text-gray-500">
                    {activityLogs.length} activities
                  </span>
                  <button
                    onClick={() => handleExportData('activity')}
                    className="text-blue-600 hover:text-blue-700 text-sm font-medium"
                  >
                    Export
                  </button>
                </div>
              </div>
            </div>
            
            {activityLogs.length === 0 ? (
              <div className="px-6 py-16 text-center">
                <ClockIcon className="mx-auto h-16 w-16 text-gray-300 mb-4" />
                <h3 className="text-lg font-medium text-gray-900 mb-2">No activity logs found</h3>
                <p className="text-gray-500 mb-4">Activity logs are not currently being tracked in the system.</p>
                <p className="text-sm text-gray-400">
                  Note: Activity logging will be implemented in a future update to track user actions, 
                  provider approvals, service creations, and system events.
                </p>
              </div>
            ) : (
              <div className="divide-y divide-gray-100">
                {activityLogs.map((log) => (
                  <div key={log.id} className="p-6 hover:bg-gray-50 transition-colors duration-200">
                    <div className="flex items-start space-x-4">
                      <div className={`flex-shrink-0 p-2 rounded-lg border ${getSeverityColor(log.severity)}`}>
                        {getActivityIcon(log.type)}
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium text-gray-900 mb-1">
                          {log.description}
                        </p>
                        <div className="flex items-center space-x-4 text-sm text-gray-500">
                          <span>by {log.user.name}</span>
                          <span>•</span>
                          <span>{log.user.role}</span>
                          <span>•</span>
                          <span>{formatDate(log.timestamp)}</span>
                        </div>
                      </div>
                      <button
                        onClick={() => toast('Activity details coming soon')}
                        className="flex-shrink-0 p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-all duration-200"
                        title="View Details"
                      >
                        <EyeIcon className="h-4 w-4" />
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {/* Placeholder for other report types */}
        {selectedReport !== 'overview' && selectedReport !== 'activity' && (
          <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-12 text-center">
            <ChartBarIcon className="mx-auto h-16 w-16 text-gray-300 mb-4" />
            <h3 className="text-lg font-medium text-gray-900 mb-2">
              {selectedReport.charAt(0).toUpperCase() + selectedReport.slice(1)} Report
            </h3>
            <p className="text-gray-500 mb-6">
              Detailed {selectedReport} analytics and insights coming soon
            </p>
            <button
              onClick={() => handleExportData(selectedReport)}
              className="bg-blue-600 text-white px-6 py-3 rounded-lg font-medium hover:bg-blue-700 transition-colors duration-200 flex items-center space-x-2 mx-auto"
            >
              <DocumentArrowDownIcon className="h-5 w-5" />
              <span>Export {selectedReport} Data</span>
            </button>
          </div>
        )}
      </div>
    </Layout>
  );
}