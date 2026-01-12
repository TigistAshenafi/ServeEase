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
    if (!isAuthenticated()) {
      router.push('/login');
      return;
    }

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
      bgColor: 'bg-blue-100',
    },
    {
      name: 'Total Providers',
      value: stats?.totalProviders || 0,
      change: stats?.providerGrowth || 0,
      icon: BuildingOfficeIcon,
      color: 'text-green-600',
      bgColor: 'bg-green-100',
    },
    {
      name: 'Pending Approvals',
      value: stats?.pendingProviders || 0,
      change: 0,
      icon: ChartBarIcon,
      color: 'text-yellow-600',
      bgColor: 'bg-yellow-100',
    },
    {
      name: 'Active Services',
      value: stats?.activeServices || 0,
      change: stats?.serviceGrowth || 0,
      icon: WrenchScrewdriverIcon,
      color: 'text-purple-600',
      bgColor: 'bg-purple-100',
    },
  ];

  return (
    <Layout>
      <Toaster position="top-right" />
      
      <div className="space-y-6">
        {/* Header */}
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
          <p className="text-gray-600">Welcome to ServeEase Admin</p>
        </div>

        {/* Stats Grid */}
        <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
          {statCards.map((item) => (
            <div
              key={item.name}
              className="relative bg-white pt-5 px-4 pb-12 sm:pt-6 sm:px-6 shadow rounded-lg overflow-hidden"
            >
              <dt>
                <div className={`absolute ${item.bgColor} rounded-md p-3`}>
                  <item.icon className={`h-6 w-6 ${item.color}`} aria-hidden="true" />
                </div>
                <p className="ml-16 text-sm font-medium text-gray-500 truncate">
                  {item.name}
                </p>
              </dt>
              <dd className="ml-16 pb-6 flex items-baseline sm:pb-7">
                <p className="text-2xl font-semibold text-gray-900">
                  {formatNumber(item.value)}
                </p>
                {item.change !== 0 && (
                  <p
                    className={`ml-2 flex items-baseline text-sm font-semibold ${
                      item.change > 0 ? 'text-green-600' : 'text-red-600'
                    }`}
                  >
                    {item.change > 0 ? (
                      <ArrowUpIcon className="self-center flex-shrink-0 h-5 w-5 text-green-500" />
                    ) : (
                      <ArrowDownIcon className="self-center flex-shrink-0 h-5 w-5 text-red-500" />
                    )}
                    <span className="sr-only">
                      {item.change > 0 ? 'Increased' : 'Decreased'} by
                    </span>
                    {Math.abs(item.change)}%
                  </p>
                )}
              </dd>
            </div>
          ))}
        </div>

        {/* Additional Stats */}
        <div className="grid grid-cols-1 gap-5 lg:grid-cols-2">
          <div className="bg-white shadow rounded-lg p-6">
            <h3 className="text-lg font-medium text-gray-900 mb-4">
              Recent Activity
            </h3>
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <span className="text-sm text-gray-600">Total Requests</span>
                <span className="text-sm font-medium text-gray-900">
                  {formatNumber(stats?.totalRequests || 0)}
                </span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm text-gray-600">Completed Requests</span>
                <span className="text-sm font-medium text-gray-900">
                  {formatNumber(stats?.completedRequests || 0)}
                </span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm text-gray-600">Revenue</span>
                <span className="text-sm font-medium text-gray-900">
                  {formatCurrency(stats?.totalRevenue || 0)}
                </span>
              </div>
            </div>
          </div>

          <div className="bg-white shadow rounded-lg p-6">
            <h3 className="text-lg font-medium text-gray-900 mb-4">
              Quick Actions
            </h3>
            <div className="space-y-3">
              <button
                onClick={() => router.push('/providers')}
                className="w-full text-left px-4 py-2 text-sm text-blue-600 hover:bg-blue-50 rounded-md transition-colors"
              >
                Review Pending Providers
              </button>
              <button
                onClick={() => router.push('/users')}
                className="w-full text-left px-4 py-2 text-sm text-blue-600 hover:bg-blue-50 rounded-md transition-colors"
              >
                Manage Users
              </button>
              <button
                onClick={() => router.push('/services')}
                className="w-full text-left px-4 py-2 text-sm text-blue-600 hover:bg-blue-50 rounded-md transition-colors"
              >
                View Services
              </button>
            </div>
          </div>
        </div>
      </div>
    </Layout>
  );
}