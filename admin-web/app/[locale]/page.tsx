'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
// import { useTranslations } from 'next-intl';
import Layout from '@/components/Layout';
import { isAuthenticated } from '@/lib/auth';
import { reportsAPI } from '@/lib/api';
import { DashboardStats } from '@/lib/types';
import { formatNumber, formatCurrency } from '@/lib/utils';
import {
  UsersIcon,
  BuildingOfficeIcon,
  WrenchScrewdriverIcon,
  ChartBarIcon,
  ArrowUpIcon,
  ArrowDownIcon,
} from '@heroicons/react/24/outline';
import toast, { Toaster } from 'react-hot-toast';

export default function DashboardPage() {
  // Temporarily disable translations for testing
  // const t = useTranslations('dashboard');
  // const tCommon = useTranslations('common');
  // const tErrors = useTranslations('errors');
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);
  const router = useRouter();

  useEffect(() => {
    console.log('Dashboard: Checking authentication...');
    const authenticated = isAuthenticated();
    console.log('Dashboard: Is authenticated?', authenticated);
    
    if (!authenticated) {
      console.log('Dashboard: Not authenticated, redirecting to login');
      router.push('/login');
      return;
    }

    console.log('Dashboard: Authenticated, fetching stats');
    fetchDashboardStats();
  }, [router]);

  const fetchDashboardStats = async () => {
    try {
      const response = await reportsAPI.getDashboardStats();
      setStats(response.data);
    } catch (error) {
      toast.error('Failed to load dashboard stats');
      console.error('Dashboard stats error:', error);
    } finally {
      setLoading(false);
    }
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

  const statCards = [
    {
      name: 'Total Users',
      value: stats?.totalUsers || 0,
      change: stats?.userGrowth || 0,
      icon: UsersIcon,
      color: 'text-blue-600',
      bgColor: 'bg-gradient-to-br from-blue-50 to-blue-100',
      borderColor: 'border-blue-200',
    },
    {
      name: 'Total Providers',
      value: stats?.totalProviders || 0,
      change: stats?.providerGrowth || 0,
      icon: BuildingOfficeIcon,
      color: 'text-emerald-600',
      bgColor: 'bg-gradient-to-br from-emerald-50 to-emerald-100',
      borderColor: 'border-emerald-200',
    },
    {
      name: 'Pending Approvals',
      value: stats?.pendingProviders || 0,
      change: 0,
      icon: ChartBarIcon,
      color: 'text-amber-600',
      bgColor: 'bg-gradient-to-br from-amber-50 to-amber-100',
      borderColor: 'border-amber-200',
    },
    {
      name: 'Active Services',
      value: stats?.activeServices || 0,
      change: stats?.serviceGrowth || 0,
      icon: WrenchScrewdriverIcon,
      color: 'text-purple-600',
      bgColor: 'bg-gradient-to-br from-purple-50 to-purple-100',
      borderColor: 'border-purple-200',
    },
  ];

  return (
    <Layout>
      <Toaster position="top-right" />
      
      <div className="space-y-8">
        {/* Enhanced Header */}
        <div className="bg-gradient-to-r from-blue-600 to-blue-700 rounded-xl p-8 text-white">
          <div className="flex justify-between items-center">
            <div>
              <h1 className="text-3xl font-bold mb-2">Welcome back, Admin!</h1>
              <p className="text-blue-100 text-lg">Here's what's happening with ServeEase today</p>
            </div>
            <div className="text-right">
              <p className="text-blue-100 text-sm">Last updated</p>
              <p className="text-white font-medium">{new Date().toLocaleTimeString()}</p>
            </div>
          </div>
        </div>

        {/* Enhanced Stats Grid */}
        <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
          {statCards.map((item) => (
            <div
              key={item.name}
              className={`relative ${item.bgColor} ${item.borderColor} border rounded-xl p-6 shadow-sm hover:shadow-md transition-all duration-200`}
            >
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600 mb-1">
                    {item.name}
                  </p>
                  <p className="text-3xl font-bold text-gray-900 mb-2">
                    {formatNumber(item.value)}
                  </p>
                  {item.change !== 0 && (
                    <div className={`flex items-center text-sm font-medium ${
                      item.change > 0 ? 'text-emerald-600' : 'text-red-600'
                    }`}>
                      {item.change > 0 ? (
                        <ArrowUpIcon className="h-4 w-4 mr-1" />
                      ) : (
                        <ArrowDownIcon className="h-4 w-4 mr-1" />
                      )}
                      <span>{Math.abs(item.change)}% from last month</span>
                    </div>
                  )}
                </div>
                <div className={`${item.color} ${item.bgColor} p-3 rounded-lg`}>
                  <item.icon className="h-8 w-8" />
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Enhanced Additional Stats */}
        <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
          <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <div className="flex items-center justify-between mb-6">
              <h3 className="text-lg font-semibold text-gray-900">
                Recent Activity
              </h3>
              <span className="text-sm text-gray-500">Last 30 days</span>
            </div>
            <div className="space-y-4">
              <div className="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
                <div className="flex items-center space-x-3">
                  <div className="w-2 h-2 bg-blue-500 rounded-full"></div>
                  <span className="text-sm font-medium text-gray-700">Total Requests</span>
                </div>
                <span className="text-lg font-bold text-gray-900">
                  {formatNumber(stats?.totalRequests || 0)}
                </span>
              </div>
              <div className="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
                <div className="flex items-center space-x-3">
                  <div className="w-2 h-2 bg-emerald-500 rounded-full"></div>
                  <span className="text-sm font-medium text-gray-700">Completed Requests</span>
                </div>
                <span className="text-lg font-bold text-gray-900">
                  {formatNumber(stats?.completedRequests || 0)}
                </span>
              </div>
              <div className="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
                <div className="flex items-center space-x-3">
                  <div className="w-2 h-2 bg-amber-500 rounded-full"></div>
                  <span className="text-sm font-medium text-gray-700">Total Revenue</span>
                </div>
                <span className="text-lg font-bold text-gray-900">
                  {formatCurrency(stats?.totalRevenue || 0)}
                </span>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
            <div className="flex items-center justify-between mb-6">
              <h3 className="text-lg font-semibold text-gray-900">
                Quick Actions
              </h3>
              <span className="text-sm text-gray-500">Manage platform</span>
            </div>
            <div className="space-y-3">
              <button
                onClick={() => router.push('/providers')}
                className="w-full flex items-center justify-between p-4 text-left bg-gradient-to-r from-blue-50 to-blue-100 hover:from-blue-100 hover:to-blue-200 rounded-lg transition-all duration-200 border border-blue-200"
              >
                <div className="flex items-center space-x-3">
                  <BuildingOfficeIcon className="h-5 w-5 text-blue-600" />
                  <span className="font-medium text-blue-900">Review Pending Providers</span>
                </div>
                <ArrowUpIcon className="h-4 w-4 text-blue-600 transform rotate-45" />
              </button>
              <button
                onClick={() => router.push('/users')}
                className="w-full flex items-center justify-between p-4 text-left bg-gradient-to-r from-emerald-50 to-emerald-100 hover:from-emerald-100 hover:to-emerald-200 rounded-lg transition-all duration-200 border border-emerald-200"
              >
                <div className="flex items-center space-x-3">
                  <UsersIcon className="h-5 w-5 text-emerald-600" />
                  <span className="font-medium text-emerald-900">Manage Users</span>
                </div>
                <ArrowUpIcon className="h-4 w-4 text-emerald-600 transform rotate-45" />
              </button>
              <button
                onClick={() => router.push('/services')}
                className="w-full flex items-center justify-between p-4 text-left bg-gradient-to-r from-purple-50 to-purple-100 hover:from-purple-100 hover:to-purple-200 rounded-lg transition-all duration-200 border border-purple-200"
              >
                <div className="flex items-center space-x-3">
                  <WrenchScrewdriverIcon className="h-5 w-5 text-purple-600" />
                  <span className="font-medium text-purple-900">View Services</span>
                </div>
                <ArrowUpIcon className="h-4 w-4 text-purple-600 transform rotate-45" />
              </button>
            </div>
          </div>
        </div>
      </div>
    </Layout>
  );
}