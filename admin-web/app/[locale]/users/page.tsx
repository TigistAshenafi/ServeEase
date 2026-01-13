'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Layout from '@/components/Layout';
import { isAuthenticated } from '@/lib/auth';
import { userAPI } from '@/lib/api';
import { formatDate, formatCurrency, debounce } from '@/lib/utils';
import toast, { Toaster } from 'react-hot-toast';
import ConfirmDialog from '@/components/ConfirmDialog';
import InputDialog from '@/components/InputDialog';
import {
  UserIcon,
  NoSymbolIcon,
  CheckCircleIcon,
  TrashIcon,
  MagnifyingGlassIcon,
  UsersIcon,
  ShieldCheckIcon,
  BuildingOfficeIcon,
} from '@heroicons/react/24/outline';

interface User {
  id: string;
  name: string;
  email: string;
  role: 'seeker' | 'provider' | 'admin';
  status: 'active' | 'suspended' | 'inactive';
  joinDate: string;
  lastActive: string;
  servicesCompleted?: number;
  totalSpent?: number;
}

export default function UsersPage() {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<'all' | 'seeker' | 'provider' | 'admin'>('all');
  const [searchTerm, setSearchTerm] = useState('');
  const [pagination, setPagination] = useState({
    page: 1,
    limit: 20,
    total: 0,
    pages: 0
  });
  const [deleteDialog, setDeleteDialog] = useState<{ isOpen: boolean; userId: string | null }>({
    isOpen: false,
    userId: null
  });
  const [suspendDialog, setSuspendDialog] = useState<{ isOpen: boolean; userId: string | null }>({
    isOpen: false,
    userId: null
  });
  const router = useRouter();

  // Re-fetch when filter changes
  useEffect(() => {
    if (!isAuthenticated()) {
      router.push('/login');
      return;
    }

    // Reset pagination when filter changes
    setPagination(prev => ({ ...prev, page: 1 }));
    fetchUsers();
  }, [router, filter]);

  const fetchUsers = async () => {
    try {
      setLoading(true);
      
      // Fetch users from API
      const params: any = {
        page: pagination.page,
        limit: pagination.limit
      };
      if (filter !== 'all') {
        params.role = filter;
      }
      
      const response = await userAPI.getAll(params);
      
      if (response.data.success) {
        let fetchedUsers = response.data.users.map((user: any) => ({
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
          status: user.suspendedAt ? 'suspended' : (user.isActive ? 'active' : 'inactive'),
          joinDate: user.createdAt,
          lastActive: user.updatedAt,
          servicesCompleted: 0, // TODO: Add this to backend
          totalSpent: 0 // TODO: Add this to backend
        }));

        // Apply search filter (client-side for now)
        if (searchTerm) {
          fetchedUsers = fetchedUsers.filter((user: User) => 
            user.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
            user.email.toLowerCase().includes(searchTerm.toLowerCase())
          );
        }
        
        setUsers(fetchedUsers);
        setPagination(response.data.pagination);
      } else {
        toast.error(response.data.message || 'Failed to load users');
      }
    } catch (error: any) {
      const errorMessage = error.response?.data?.message || 'Failed to load users';
      toast.error(errorMessage);
      console.error('Users fetch error:', error);
    } finally {
      setLoading(false);
    }
  };

  // Debounced search function
  const debouncedFetchUsers = debounce(fetchUsers, 300);

  // Re-fetch when search term changes (debounced)
  useEffect(() => {
    if (searchTerm !== '') {
      debouncedFetchUsers();
    } else {
      fetchUsers();
    }
  }, [searchTerm]);

  const handleSuspend = (userId: string) => {
    setSuspendDialog({ isOpen: true, userId });
  };

  const confirmSuspend = async (reason: string) => {
    if (!suspendDialog.userId) return;
    
    try {
      await userAPI.suspend(suspendDialog.userId, reason);
      toast.success('User suspended successfully');
      fetchUsers();
    } catch (error: any) {
      const errorMessage = error.response?.data?.message || 'Failed to suspend user';
      toast.error(errorMessage);
      console.error('Suspend error:', error);
    }
  };

  const handleDelete = (userId: string) => {
    setDeleteDialog({ isOpen: true, userId });
  };

  const confirmDelete = async () => {
    if (!deleteDialog.userId) return;

    try {
      await userAPI.delete(deleteDialog.userId);
      toast.success('User deleted successfully');
      fetchUsers();
    } catch (error: any) {
      const errorMessage = error.response?.data?.message || 'Failed to delete user';
      toast.error(errorMessage);
      console.error('Delete error:', error);
    }
  };

  const handleActivate = async (userId: string) => {
    try {
      await userAPI.activate(userId);
      toast.success('User activated successfully');
      fetchUsers();
    } catch (error: any) {
      const errorMessage = error.response?.data?.message || 'Failed to activate user';
      toast.error(errorMessage);
      console.error('Activate error:', error);
    }
  };

  const getStatusBadge = (status: string) => {
    const baseClasses = 'inline-flex items-center px-3 py-1 rounded-full text-xs font-medium';
    switch (status) {
      case 'active':
        return `${baseClasses} bg-emerald-100 text-emerald-800 border border-emerald-200`;
      case 'suspended':
        return `${baseClasses} bg-red-100 text-red-800 border border-red-200`;
      case 'inactive':
        return `${baseClasses} bg-gray-100 text-gray-800 border border-gray-200`;
      default:
        return `${baseClasses} bg-gray-100 text-gray-800 border border-gray-200`;
    }
  };

  const getRoleBadge = (role: string) => {
    const baseClasses = 'inline-flex items-center px-3 py-1 rounded-full text-xs font-medium';
    switch (role) {
      case 'admin':
        return `${baseClasses} bg-purple-100 text-purple-800 border border-purple-200`;
      case 'provider':
        return `${baseClasses} bg-blue-100 text-blue-800 border border-blue-200`;
      case 'seeker':
        return `${baseClasses} bg-amber-100 text-amber-800 border border-amber-200`;
      default:
        return `${baseClasses} bg-gray-100 text-gray-800 border border-gray-200`;
    }
  };

  const getRoleIcon = (role: string) => {
    switch (role) {
      case 'admin':
        return <ShieldCheckIcon className="h-6 w-6 text-purple-600" />;
      case 'provider':
        return <BuildingOfficeIcon className="h-6 w-6 text-blue-600" />;
      case 'seeker':
        return <UserIcon className="h-6 w-6 text-amber-600" />;
      default:
        return <UserIcon className="h-6 w-6 text-gray-600" />;
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

  const activeCount = users.filter(u => u.status === 'active').length;
  const seekerCount = users.filter(u => u.role === 'seeker').length;
  const providerCount = users.filter(u => u.role === 'provider').length;

  return (
    <Layout>
      <Toaster position="top-right" />
      
      {/* Confirmation Dialogs */}
      <ConfirmDialog
        isOpen={deleteDialog.isOpen}
        onClose={() => setDeleteDialog({ isOpen: false, userId: null })}
        onConfirm={confirmDelete}
        title="Delete User"
        message="Are you sure you want to delete this user? This action cannot be undone and will permanently remove all user data."
        confirmText="Delete"
        cancelText="Cancel"
        type="danger"
      />

      <InputDialog
        isOpen={suspendDialog.isOpen}
        onClose={() => setSuspendDialog({ isOpen: false, userId: null })}
        onConfirm={confirmSuspend}
        title="Suspend User"
        message="Please provide a reason for suspending this user account:"
        placeholder="Enter suspension reason..."
        confirmText="Suspend"
        cancelText="Cancel"
        required={true}
      />
      
      <div className="space-y-8">
        {/* Enhanced Header */}
        <div className="bg-gradient-to-r from-blue-600 to-blue-700 rounded-xl p-8 text-white">
          <div className="flex justify-between items-start">
            <div>
              <h1 className="text-3xl font-bold mb-2">User Management</h1>
              <p className="text-blue-100 text-lg">Manage users, roles, and account status</p>
              <div className="flex items-center space-x-6 mt-4">
                <div className="flex items-center space-x-2">
                  <UsersIcon className="h-5 w-5 text-amber-300" />
                  <span className="text-blue-100">{seekerCount} seekers</span>
                </div>
                <div className="flex items-center space-x-2">
                  <BuildingOfficeIcon className="h-5 w-5 text-blue-300" />
                  <span className="text-blue-100">{providerCount} providers</span>
                </div>
                <div className="flex items-center space-x-2">
                  <CheckCircleIcon className="h-5 w-5 text-emerald-300" />
                  <span className="text-blue-100">{activeCount} active</span>
                </div>
              </div>
            </div>
            <div className="text-right">
              <p className="text-blue-100 text-sm">Total Users</p>
              <p className="text-white font-bold text-3xl">{users.length}</p>
            </div>
          </div>
        </div>

        {/* Enhanced Search and Filters */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between space-y-4 lg:space-y-0">
            {/* Search */}
            <div className="relative flex-1 max-w-md">
              <MagnifyingGlassIcon className="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
              <input
                type="text"
                placeholder="Search users..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-200"
              />
            </div>
          </div>

          {/* Role Filters */}
          <div className="flex flex-wrap gap-3 mt-6">
            {[
              { key: 'all', label: 'All Users', count: users.length, icon: UsersIcon },
              { key: 'seeker', label: 'Seekers', count: seekerCount, icon: UserIcon },
              { key: 'provider', label: 'Providers', count: providerCount, icon: BuildingOfficeIcon },
              { key: 'admin', label: 'Admins', count: users.filter(u => u.role === 'admin').length, icon: ShieldCheckIcon }
            ].map((filterOption) => (
              <button
                key={filterOption.key}
                onClick={() => setFilter(filterOption.key as any)}
                className={`px-4 py-2 rounded-lg text-sm font-medium transition-all duration-200 flex items-center space-x-2 ${
                  filter === filterOption.key
                    ? 'bg-blue-600 text-white shadow-md'
                    : 'bg-gray-50 text-gray-700 border border-gray-200 hover:bg-gray-100 hover:border-gray-300'
                }`}
              >
                <filterOption.icon className="h-4 w-4" />
                <span>{filterOption.label}</span>
                <span className={`px-2 py-0.5 rounded-full text-xs ${
                  filter === filterOption.key
                    ? 'bg-blue-500 text-white'
                    : 'bg-gray-200 text-gray-600'
                }`}>
                  {filterOption.count}
                </span>
              </button>
            ))}
          </div>
        </div>

        {/* Enhanced Users Display */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
          {users.length === 0 ? (
            <div className="px-6 py-16 text-center">
              <UsersIcon className="mx-auto h-16 w-16 text-gray-300 mb-4" />
              <h3 className="text-lg font-medium text-gray-900 mb-2">No users found</h3>
              <p className="text-gray-500">
                {searchTerm ? 'Try adjusting your search terms' : 'Users will appear here when they register'}
              </p>
            </div>
          ) : (
            <div className="divide-y divide-gray-100">
              {users.map((user) => (
                <div key={user.id} className="p-6 hover:bg-gray-50 transition-colors duration-200">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center space-x-4 flex-1 min-w-0">
                      <div className="flex-shrink-0">
                        <div className="w-12 h-12 bg-gradient-to-br from-gray-100 to-gray-200 rounded-lg flex items-center justify-center border border-gray-200">
                          {getRoleIcon(user.role)}
                        </div>
                      </div>
                      <div className="flex-1 min-w-0">
                        <h3 className="text-sm font-semibold text-gray-900 truncate mb-1">
                          {user.name}
                        </h3>
                        <p className="text-sm text-gray-600 mb-2 truncate">
                          {user.email}
                        </p>
                        <div className="flex items-center space-x-4 flex-wrap">
                          <span className={getRoleBadge(user.role)}>
                            {user.role.charAt(0).toUpperCase() + user.role.slice(1)}
                          </span>
                          <span className={getStatusBadge(user.status)}>
                            {user.status.charAt(0).toUpperCase() + user.status.slice(1)}
                          </span>
                          <span className="text-xs text-gray-500">
                            Joined: {formatDate(user.joinDate)}
                          </span>
                          {user.servicesCompleted !== undefined && (
                            <span className="text-xs text-gray-500 bg-gray-100 px-2 py-1 rounded">
                              {user.servicesCompleted} services
                            </span>
                          )}
                          {user.totalSpent !== undefined && user.totalSpent > 0 && (
                            <span className="text-xs text-gray-500 bg-gray-100 px-2 py-1 rounded">
                              {formatCurrency(user.totalSpent)} spent
                            </span>
                          )}
                        </div>
                      </div>
                    </div>
                    
                    <div className="flex items-center space-x-2 ml-4">
                      {user.status === 'active' && user.role !== 'admin' && (
                        <button
                          onClick={() => handleSuspend(user.id)}
                          className="p-2 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-all duration-200"
                          title="Suspend User"
                        >
                          <NoSymbolIcon className="h-5 w-5" />
                        </button>
                      )}
                      
                      {user.status === 'suspended' && (
                        <button
                          onClick={() => handleActivate(user.id)}
                          className="p-2 text-gray-400 hover:text-emerald-600 hover:bg-emerald-50 rounded-lg transition-all duration-200"
                          title="Activate User"
                        >
                          <CheckCircleIcon className="h-5 w-5" />
                        </button>
                      )}
                      
                      {user.role !== 'admin' && (
                        <button
                          onClick={() => handleDelete(user.id)}
                          className="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg transition-all duration-200"
                          title="Delete User"
                        >
                          <TrashIcon className="h-5 w-5" />
                        </button>
                      )}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </Layout>
  );
}