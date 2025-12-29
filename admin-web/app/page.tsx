'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
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
      toast.error('Failed to load dashboard statistics');
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
          <p className="mt-1 text-sm text-gray-500">
            Welcome to the ServeEase admin panel. Here's an overview of your platform.
          </p>
        </div>

        {/* Stats Grid */}
        <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
          {statCards.map((stat) => (
            <div key={stat.name} className="stat-card">
              <div className="stat-card-body">
                <div className="flex items-center">
                  <div className="flex-shrink-0">
                    <div className={`p-3 rounded-md ${stat.bgColor}`}>
                      <stat.icon className={`h-6 w-6 ${stat.color}`} />
                    </div>
                  </div>
                  <div className="ml-5 w-0 flex-1">
                    <dl>
                      <dt className="text-sm font-medium text-gray-500 truncate">
                        {stat.name}
                      </dt>
                      <dd className="flex items-baseline">
                        <div className="text-2xl font-semibold text-gray-900">
                          {formatNumber(stat.value)}
                        </div>
                        {stat.change !== 0 && (
                          <div className={`ml-2 flex items-baseline text-sm font-semibold ${
                            stat.change > 0 ? 'text-green-600' : 'text-red-600'
                          }`}>
                            {stat.change > 0 ? (
                              <ArrowUpIcon className="self-center flex-shrink-0 h-4 w-4" />
                            ) : (
                              <ArrowDownIcon className="self-center flex-shrink-0 h-4 w-4" />
                            )}
                            <span className="sr-only">
                              {stat.change > 0 ? 'Increased' : 'Decreased'} by
                            </span>
                            {Math.abs(stat.change)}%
                          </div>
                        )}
                      </dd>
                    </dl>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Additional Stats */}
        <div className="grid grid-cols-1 gap-5 lg:grid-cols-2">
          <div className="card">
            <div className="card-header">
              <h3 className="text-lg font-medium text-gray-900">Service Requests</h3>
            </div>
            <div className="card-body">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <div className="text-2xl font-bold text-gray-900">
                    {formatNumber(stats?.totalRequests || 0)}
                  </div>
                  <div className="text-sm text-gray-500">Total Requests</div>
                </div>
                <div>
                  <div className="text-2xl font-bold text-green-600">
                    {formatNumber(stats?.completedRequests || 0)}
                  </div>
                  <div className="text-sm text-gray-500">Completed</div>
                </div>
              </div>
              <div className="mt-4">
                <div className="text-sm text-gray-500">
                  Completion Rate: {stats?.totalRequests ? 
                    Math.round((stats.completedRequests / stats.totalRequests) * 100) : 0}%
                </div>
              </div>
            </div>
          </div>

          <div className="card">
            <div className="card-header">
              <h3 className="text-lg font-medium text-gray-900">Platform Revenue</h3>
            </div>
            <div className="card-body">
              <div className="text-3xl font-bold text-gray-900">
                {formatCurrency(stats?.revenue || 0)}
              </div>
              <div className="text-sm text-gray-500 mt-1">Total Revenue</div>
              <div className="mt-4">
                <div className="text-sm text-gray-500">
                  Average per completed request: {stats?.completedRequests ? 
                    formatCurrency((stats.revenue || 0) / stats.completedRequests) : '$0'}
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Quick Actions */}
        <div className="card">
          <div className="card-header">
            <h3 className="text-lg font-medium text-gray-900">Quick Actions</h3>
          </div>
          <div className="card-body">
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
              <button
                onClick={() => router.push('/providers')}
                className="p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors"
              >
                <BuildingOfficeIcon className="h-8 w-8 text-blue-600 mx-auto mb-2" />
                <div className="text-sm font-medium text-gray-900">Review Providers</div>
                <div className="text-xs text-gray-500">{stats?.pendingProviders || 0} pending</div>
              </button>
              
              <button
                onClick={() => router.push('/users')}
                className="p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors"
              >
                <UsersIcon className="h-8 w-8 text-green-600 mx-auto mb-2" />
                <div className="text-sm font-medium text-gray-900">Manage Users</div>
                <div className="text-xs text-gray-500">{stats?.totalUsers || 0} total users</div>
              </button>
              
              <button
                onClick={() => router.push('/services')}
                className="p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors"
              >
                <WrenchScrewdriverIcon className="h-8 w-8 text-purple-600 mx-auto mb-2" />
                <div className="text-sm font-medium text-gray-900">Moderate Services</div>
                <div className="text-xs text-gray-500">{stats?.totalServices || 0} total services</div>
              </button>
              
              <button
                onClick={() => router.push('/reports')}
                className="p-4 border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors"
              >
                <ChartBarIcon className="h-8 w-8 text-orange-600 mx-auto mb-2" />
                <div className="text-sm font-medium text-gray-900">View Reports</div>
                <div className="text-xs text-gray-500">Analytics & insights</div>
              </button>
            </div>
          </div>
        </div>
      </div>
    </Layout>
  );
}