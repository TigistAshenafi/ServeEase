'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Layout from '@/components/Layout';
import { isAuthenticated } from '@/lib/auth';
import { providerAPI } from '@/lib/api';
import { formatDate, debounce } from '@/lib/utils';
import toast, { Toaster } from 'react-hot-toast';
import ConfirmDialog from '@/components/ConfirmDialog';
import InputDialog from '@/components/InputDialog';
import DetailModal from '@/components/DetailModal';
import ProviderDetailView from '@/components/ProviderDetailView';
import {
  CheckIcon,
  XMarkIcon,
  EyeIcon,
  BuildingOfficeIcon,
  UserIcon,
  MagnifyingGlassIcon,
  ClockIcon,
  CheckCircleIcon,
  ExclamationTriangleIcon,
} from '@heroicons/react/24/outline';

interface Provider {
  id: string;
  businessName: string;
  providerType: 'individual' | 'organization';
  category: string;
  location: string;
  applicationDate: string;
  status: 'pending' | 'approved' | 'rejected';
  user: {
    name: string;
    email: string;
  };
  documentsCount?: number;
  rating?: number;
}

export default function ProvidersPage() {
  const [providers, setProviders] = useState<Provider[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<'all' | 'pending' | 'approved' | 'rejected'>('all');
  const [searchTerm, setSearchTerm] = useState('');
  const [pagination, setPagination] = useState({
    page: 1,
    limit: 20,
    total: 0,
    pages: 0
  });
  const [rejectDialog, setRejectDialog] = useState<{ isOpen: boolean; providerId: string | null }>({
    isOpen: false,
    providerId: null
  });
  const [viewModal, setViewModal] = useState<{ isOpen: boolean; provider: Provider | null }>({
    isOpen: false,
    provider: null
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
    fetchProviders();
  }, [router, filter]);

  const fetchProviders = async () => {
    try {
      setLoading(true);
      
      // Fetch providers from API
      const params: any = {
        page: pagination.page,
        limit: pagination.limit
      };
      if (filter !== 'all') {
        params.status = filter;
      }
      
      const response = await providerAPI.getAll(params);
      
      if (response.data.success) {
        let fetchedProviders = response.data.providers.map((provider: any) => ({
          id: provider.id,
          businessName: provider.businessName || provider.user?.name || 'Unknown Business',
          providerType: 'individual', // TODO: Add providerType to backend
          category: provider.category || 'General',
          location: provider.location || 'Location not specified',
          applicationDate: provider.createdAt,
          status: provider.status || 'pending',
          user: {
            name: provider.user?.name || 'Unknown User',
            email: provider.user?.email || 'No email'
          },
          documentsCount: 0, // TODO: Add documents count to backend
          rating: 0 // TODO: Add rating system to backend
        }));

        // Apply search filter (client-side for now)
        if (searchTerm) {
          fetchedProviders = fetchedProviders.filter((provider: Provider) => 
            provider.businessName.toLowerCase().includes(searchTerm.toLowerCase()) ||
            provider.user.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
            provider.category.toLowerCase().includes(searchTerm.toLowerCase()) ||
            provider.location.toLowerCase().includes(searchTerm.toLowerCase())
          );
        }
        
        setProviders(fetchedProviders);
        setPagination(response.data.pagination);
      } else {
        toast.error(response.data.message || 'Failed to load providers');
      }
    } catch (error: any) {
      const errorMessage = error.response?.data?.message || 'Failed to load providers';
      toast.error(errorMessage);
      console.error('Providers fetch error:', error);
    } finally {
      setLoading(false);
    }
  };

  // Debounced search function
  const debouncedFetchProviders = debounce(fetchProviders, 300);

  // Re-fetch when search term changes (debounced)
  useEffect(() => {
    if (searchTerm !== '') {
      debouncedFetchProviders();
    } else {
      fetchProviders();
    }
  }, [searchTerm]);

  const handleView = (provider: Provider) => {
    setViewModal({ isOpen: true, provider });
  };

  const handleApprove = async (providerId: string) => {
    try {
      const adminNotes = 'Provider approved by admin';
      await providerAPI.approve(providerId, adminNotes);
      toast.success('Provider approved successfully');
      fetchProviders();
    } catch (error: any) {
      const errorMessage = error.response?.data?.message || 'Failed to approve provider';
      toast.error(errorMessage);
      console.error('Approve error:', error);
    }
  };

  const handleReject = (providerId: string) => {
    setRejectDialog({ isOpen: true, providerId });
  };

  const confirmReject = async (adminNotes: string) => {
    if (!rejectDialog.providerId) return;
    
    try {
      await providerAPI.reject(rejectDialog.providerId, adminNotes);
      toast.success('Provider rejected successfully');
      fetchProviders();
    } catch (error: any) {
      const errorMessage = error.response?.data?.message || 'Failed to reject provider';
      toast.error(errorMessage);
      console.error('Reject error:', error);
    }
  };

  const getStatusBadge = (status: string) => {
    const baseClasses = 'inline-flex items-center px-3 py-1 rounded-full text-xs font-medium';
    switch (status) {
      case 'pending':
        return `${baseClasses} bg-amber-100 text-amber-800 border border-amber-200`;
      case 'approved':
        return `${baseClasses} bg-emerald-100 text-emerald-800 border border-emerald-200`;
      case 'rejected':
        return `${baseClasses} bg-red-100 text-red-800 border border-red-200`;
      default:
        return `${baseClasses} bg-gray-100 text-gray-800 border border-gray-200`;
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'pending':
        return <ClockIcon className="h-4 w-4 text-amber-600" />;
      case 'approved':
        return <CheckCircleIcon className="h-4 w-4 text-emerald-600" />;
      case 'rejected':
        return <ExclamationTriangleIcon className="h-4 w-4 text-red-600" />;
      default:
        return null;
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

  const pendingCount = providers.filter(p => p.status === 'pending').length;
  const approvedCount = providers.filter(p => p.status === 'approved').length;
  const rejectedCount = providers.filter(p => p.status === 'rejected').length;

  return (
    <Layout>
      <Toaster position="top-right" />
      
      {/* Confirmation Dialogs */}
      <InputDialog
        isOpen={rejectDialog.isOpen}
        onClose={() => setRejectDialog({ isOpen: false, providerId: null })}
        onConfirm={confirmReject}
        title="Reject Provider"
        message="Please provide a reason for rejecting this provider application:"
        placeholder="Enter rejection reason..."
        confirmText="Reject"
        cancelText="Cancel"
        required={true}
      />
      
      {/* View Modal */}
      <DetailModal
        isOpen={viewModal.isOpen}
        onClose={() => setViewModal({ isOpen: false, provider: null })}
        title={`Provider Details - ${viewModal.provider?.businessName || ''}`}
        size="xl"
      >
        {viewModal.provider && <ProviderDetailView provider={viewModal.provider} />}
      </DetailModal>
      
      <div className="space-y-8">
        {/* Enhanced Header */}
        <div className="bg-gradient-to-r from-blue-600 to-blue-700 rounded-xl p-8 text-white">
          <div className="flex justify-between items-start">
            <div>
              <h1 className="text-3xl font-bold mb-2">Provider Management</h1>
              <p className="text-blue-100 text-lg">Review and manage service provider applications</p>
              <div className="flex items-center space-x-6 mt-4">
                <div className="flex items-center space-x-2">
                  <ClockIcon className="h-5 w-5 text-amber-300" />
                  <span className="text-blue-100">{pendingCount} pending approval</span>
                </div>
                <div className="flex items-center space-x-2">
                  <CheckCircleIcon className="h-5 w-5 text-emerald-300" />
                  <span className="text-blue-100">{approvedCount} approved</span>
                </div>
              </div>
            </div>
            <div className="text-right">
              <p className="text-blue-100 text-sm">Total Providers</p>
              <p className="text-white font-bold text-3xl">{providers.length}</p>
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
                placeholder="Search providers..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-200"
              />
            </div>
          </div>

          {/* Status Filters */}
          <div className="flex flex-wrap gap-3 mt-6">
            {[
              { key: 'all', label: 'All Providers', count: providers.length, icon: BuildingOfficeIcon },
              { key: 'pending', label: 'Pending Review', count: pendingCount, icon: ClockIcon },
              { key: 'approved', label: 'Approved', count: approvedCount, icon: CheckCircleIcon },
              { key: 'rejected', label: 'Rejected', count: rejectedCount, icon: ExclamationTriangleIcon }
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

        {/* Enhanced Providers Display */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
          {providers.length === 0 ? (
            <div className="px-6 py-16 text-center">
              <BuildingOfficeIcon className="mx-auto h-16 w-16 text-gray-300 mb-4" />
              <h3 className="text-lg font-medium text-gray-900 mb-2">No providers found</h3>
              <p className="text-gray-500">
                {searchTerm ? 'Try adjusting your search terms' : 'Provider applications will appear here when submitted'}
              </p>
            </div>
          ) : (
            <div className="divide-y divide-gray-100">
              {providers.map((provider) => (
                <div key={provider.id} className="p-6 hover:bg-gray-50 transition-colors duration-200">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center space-x-4 flex-1 min-w-0">
                      <div className="flex-shrink-0">
                        <div className="w-12 h-12 bg-gradient-to-br from-blue-100 to-blue-200 rounded-lg flex items-center justify-center border border-blue-200">
                          {provider.providerType === 'organization' ? (
                            <BuildingOfficeIcon className="h-6 w-6 text-blue-600" />
                          ) : (
                            <UserIcon className="h-6 w-6 text-blue-600" />
                          )}
                        </div>
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center space-x-3 mb-1">
                          <h3 className="text-sm font-semibold text-gray-900 truncate">
                            {provider.businessName || provider.user.name}
                          </h3>
                          {getStatusIcon(provider.status)}
                        </div>
                        <p className="text-sm text-gray-600 mb-2">
                          {provider.user.name} • {provider.user.email}
                        </p>
                        <div className="flex items-center space-x-4 flex-wrap">
                          <span className={getStatusBadge(provider.status)}>
                            {provider.status.charAt(0).toUpperCase() + provider.status.slice(1)}
                          </span>
                          <span className="text-xs text-gray-500 bg-gray-100 px-2 py-1 rounded">
                            {provider.category}
                          </span>
                          <span className="text-xs text-gray-500 bg-gray-100 px-2 py-1 rounded">
                            {provider.location}
                          </span>
                          <span className="text-xs text-gray-500">
                            Applied: {formatDate(provider.applicationDate)}
                          </span>
                        </div>
                      </div>
                    </div>
                    
                    <div className="flex items-center space-x-2 ml-4">
                      <button
                        onClick={() => handleView(provider)}
                        className="p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-all duration-200"
                        title="View Details"
                      >
                        <EyeIcon className="h-5 w-5" />
                      </button>
                      
                      {provider.status === 'pending' && (
                        <>
                          <button
                            onClick={() => handleApprove(provider.id)}
                            className="p-2 text-gray-400 hover:text-emerald-600 hover:bg-emerald-50 rounded-lg transition-all duration-200"
                            title="Approve Provider"
                          >
                            <CheckIcon className="h-5 w-5" />
                          </button>
                          <button
                            onClick={() => handleReject(provider.id)}
                            className="p-2 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-all duration-200"
                            title="Reject Provider"
                          >
                            <XMarkIcon className="h-5 w-5" />
                          </button>
                        </>
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