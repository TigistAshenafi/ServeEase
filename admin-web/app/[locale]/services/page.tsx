'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Layout from '@/components/Layout';
import { isAuthenticated } from '@/lib/auth';
import { serviceAPI } from '@/lib/api';
import { formatDate, debounce } from '@/lib/utils';
import toast, { Toaster } from 'react-hot-toast';
import ConfirmDialog from '@/components/ConfirmDialog';
import InputDialog from '@/components/InputDialog';
import {
  WrenchScrewdriverIcon,
  CheckIcon,
  XMarkIcon,
  TrashIcon,
  MagnifyingGlassIcon,
  CogIcon,
  CheckCircleIcon,
  ExclamationTriangleIcon,
  TagIcon,
} from '@heroicons/react/24/outline';

interface Service {
  id: string;
  providerId: string;
  categoryId: string;
  title: string;
  description: string;
  isActive: boolean;
  provider: {
    businessName: string;
    user: {
      name: string;
      email: string;
    };
  };
  category: {
    name: string;
  };
  createdAt: string;
  updatedAt: string;
}

export default function ServicesPage() {
  const [services, setServices] = useState<Service[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<'all' | 'active' | 'inactive'>('all');
  const [searchTerm, setSearchTerm] = useState('');
  const [pagination, setPagination] = useState({
    page: 1,
    limit: 20,
    total: 0,
    pages: 0
  });
  const [deleteDialog, setDeleteDialog] = useState<{ isOpen: boolean; serviceId: string | null }>({
    isOpen: false,
    serviceId: null
  });
  const [rejectDialog, setRejectDialog] = useState<{ isOpen: boolean; serviceId: string | null }>({
    isOpen: false,
    serviceId: null
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
    fetchServices();
  }, [router, filter]);

  const fetchServices = async () => {
    try {
      setLoading(true);
      
      // Fetch services from API
      const params: any = {
        page: pagination.page,
        limit: pagination.limit
      };
      if (filter !== 'all') {
        params.status = filter;
      }
      
      const response = await serviceAPI.getAll(params);
      
      if (response.data.success) {
        let fetchedServices = response.data.services.map((service: any) => ({
          id: service.id,
          providerId: service.providerId,
          categoryId: service.categoryId,
          title: service.title,
          description: service.description,
          isActive: service.isActive,
          provider: {
            businessName: service.provider?.businessName || 'Unknown Business',
            user: {
              name: service.provider?.user?.name || 'Unknown Provider',
              email: service.provider?.user?.email || 'No email'
            }
          },
          category: {
            name: service.category?.name || 'Uncategorized'
          },
          createdAt: service.createdAt,
          updatedAt: service.updatedAt
        }));

        // Apply search filter (client-side for now)
        if (searchTerm) {
          fetchedServices = fetchedServices.filter((service: Service) => 
            service.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
            service.description.toLowerCase().includes(searchTerm.toLowerCase()) ||
            service.category.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
            service.provider.businessName.toLowerCase().includes(searchTerm.toLowerCase())
          );
        }
        
        setServices(fetchedServices);
        setPagination(response.data.pagination);
      } else {
        toast.error(response.data.message || 'Failed to load services');
      }
    } catch (error: any) {
      const errorMessage = error.response?.data?.message || 'Failed to load services';
      toast.error(errorMessage);
      console.error('Services fetch error:', error);
    } finally {
      setLoading(false);
    }
  };

  // Debounced search function
  const debouncedFetchServices = debounce(fetchServices, 300);

  // Re-fetch when search term changes (debounced)
  useEffect(() => {
    if (searchTerm !== '') {
      debouncedFetchServices();
    } else {
      fetchServices();
    }
  }, [searchTerm]);

  const handleApprove = async (serviceId: string) => {
    try {
      await serviceAPI.approve(serviceId);
      toast.success('Service approved successfully');
      fetchServices();
    } catch (error: any) {
      const errorMessage = error.response?.data?.message || 'Failed to approve service';
      toast.error(errorMessage);
      console.error('Approve error:', error);
    }
  };

  const handleReject = (serviceId: string) => {
    setRejectDialog({ isOpen: true, serviceId });
  };

  const confirmReject = async (reason: string) => {
    if (!rejectDialog.serviceId) return;
    
    try {
      await serviceAPI.reject(rejectDialog.serviceId, reason || 'Service rejected by admin');
      toast.success('Service rejected successfully');
      fetchServices();
    } catch (error: any) {
      const errorMessage = error.response?.data?.message || 'Failed to reject service';
      toast.error(errorMessage);
      console.error('Reject error:', error);
    }
  };

  const handleDelete = (serviceId: string) => {
    setDeleteDialog({ isOpen: true, serviceId });
  };

  const confirmDelete = async () => {
    if (!deleteDialog.serviceId) return;

    try {
      await serviceAPI.delete(deleteDialog.serviceId);
      toast.success('Service deleted successfully');
      fetchServices();
    } catch (error: any) {
      const errorMessage = error.response?.data?.message || 'Failed to delete service';
      toast.error(errorMessage);
      console.error('Delete error:', error);
    }
  };

  const getStatusBadge = (isActive: boolean) => {
    const baseClasses = 'inline-flex items-center px-3 py-1 rounded-full text-xs font-medium';
    if (isActive) {
      return `${baseClasses} bg-emerald-100 text-emerald-800 border border-emerald-200`;
    } else {
      return `${baseClasses} bg-red-100 text-red-800 border border-red-200`;
    }
  };

  const getStatusIcon = (isActive: boolean) => {
    if (isActive) {
      return <CheckCircleIcon className="h-4 w-4 text-emerald-600" />;
    } else {
      return <ExclamationTriangleIcon className="h-4 w-4 text-red-600" />;
    }
  };

  const getCategoryIcon = (categoryName: string) => {
    // Return appropriate icon based on category
    switch (categoryName.toLowerCase()) {
      case 'beauty & wellness':
        return <TagIcon className="h-6 w-6 text-pink-600" />;
      case 'cleaning':
        return <CogIcon className="h-6 w-6 text-blue-600" />;
      case 'home repair':
        return <WrenchScrewdriverIcon className="h-6 w-6 text-orange-600" />;
      default:
        return <CogIcon className="h-6 w-6 text-gray-600" />;
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

  const activeCount = services.filter(s => s.isActive).length;
  const inactiveCount = services.filter(s => s.isActive === false).length;

  return (
    <Layout>
      <Toaster position="top-right" />
      
      {/* Confirmation Dialogs */}
      <ConfirmDialog
        isOpen={deleteDialog.isOpen}
        onClose={() => setDeleteDialog({ isOpen: false, serviceId: null })}
        onConfirm={confirmDelete}
        title="Delete Service"
        message="Are you sure you want to delete this service? This action cannot be undone and will permanently remove the service from the platform."
        confirmText="Delete"
        cancelText="Cancel"
        type="danger"
      />

      <InputDialog
        isOpen={rejectDialog.isOpen}
        onClose={() => setRejectDialog({ isOpen: false, serviceId: null })}
        onConfirm={confirmReject}
        title="Reject Service"
        message="Please provide a reason for rejecting this service (optional):"
        placeholder="Enter rejection reason..."
        confirmText="Reject"
        cancelText="Cancel"
        required={false}
      />
      
      <div className="space-y-8">
        {/* Enhanced Header */}
        <div className="bg-gradient-to-r from-blue-600 to-blue-700 rounded-xl p-8 text-white">
          <div className="flex justify-between items-start">
            <div>
              <h1 className="text-3xl font-bold mb-2">Service Management</h1>
              <p className="text-blue-100 text-lg">Manage services from approved providers</p>
              <div className="flex items-center space-x-6 mt-4">
                <div className="flex items-center space-x-2">
                  <CheckCircleIcon className="h-5 w-5 text-emerald-300" />
                  <span className="text-blue-100">{activeCount} active</span>
                </div>
                <div className="flex items-center space-x-2">
                  <ExclamationTriangleIcon className="h-5 w-5 text-red-300" />
                  <span className="text-blue-100">{inactiveCount} inactive</span>
                </div>
              </div>
            </div>
            <div className="text-right">
              <p className="text-blue-100 text-sm">Total Services</p>
              <p className="text-white font-bold text-3xl">{services.length}</p>
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
                placeholder="Search services..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-200"
              />
            </div>
          </div>

          {/* Status Filters */}
          <div className="flex flex-wrap gap-3 mt-6">
            {[
              { key: 'all', label: 'All Services', count: services.length, icon: CogIcon },
              { key: 'active', label: 'Active', count: activeCount, icon: CheckCircleIcon },
              { key: 'inactive', label: 'Inactive', count: inactiveCount, icon: ExclamationTriangleIcon }
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

        {/* Enhanced Services Display */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
          {services.length === 0 ? (
            <div className="px-6 py-16 text-center">
              <CogIcon className="mx-auto h-16 w-16 text-gray-300 mb-4" />
              <h3 className="text-lg font-medium text-gray-900 mb-2">No services found</h3>
              <p className="text-gray-500">
                {searchTerm ? 'Try adjusting your search terms' : 'Services from approved providers will appear here'}
              </p>
            </div>
          ) : (
            <div className="divide-y divide-gray-100">
              {services.map((service) => (
                <div key={service.id} className="p-6 hover:bg-gray-50 transition-colors duration-200">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center space-x-4 flex-1 min-w-0">
                      <div className="flex-shrink-0">
                        <div className="w-12 h-12 bg-gradient-to-br from-gray-100 to-gray-200 rounded-lg flex items-center justify-center border border-gray-200">
                          {getCategoryIcon(service.category.name)}
                        </div>
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center space-x-3 mb-1">
                          <h3 className="text-sm font-semibold text-gray-900 truncate">
                            {service.title}
                          </h3>
                          {getStatusIcon(service.isActive)}
                        </div>
                        <p className="text-sm text-gray-600 mb-2 line-clamp-2">
                          {service.description}
                        </p>
                        <div className="flex items-center space-x-4 flex-wrap">
                          <span className={getStatusBadge(service.isActive)}>
                            {service.isActive ? 'Active' : 'Inactive'}
                          </span>
                          <span className="text-xs text-gray-500 bg-gray-100 px-2 py-1 rounded">
                            {service.category.name}
                          </span>
                          <span className="text-xs text-gray-500 bg-emerald-100 px-2 py-1 rounded text-emerald-800">
                            Approved Provider
                          </span>
                          <span className="text-xs text-gray-500">
                            by {service.provider.businessName}
                          </span>
                          <span className="text-xs text-gray-500">
                            Created: {formatDate(service.createdAt)}
                          </span>
                        </div>
                      </div>
                    </div>
                    
                    <div className="flex items-center space-x-2 ml-4">
                      {!service.isActive && (
                        <button
                          onClick={() => handleApprove(service.id)}
                          className="p-2 text-gray-400 hover:text-emerald-600 hover:bg-emerald-50 rounded-lg transition-all duration-200"
                          title="Approve Service"
                        >
                          <CheckIcon className="h-5 w-5" />
                        </button>
                      )}
                      
                      {service.isActive && (
                        <button
                          onClick={() => handleReject(service.id)}
                          className="p-2 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-all duration-200"
                          title="Deactivate Service"
                        >
                          <XMarkIcon className="h-5 w-5" />
                        </button>
                      )}
                      
                      <button
                        onClick={() => handleDelete(service.id)}
                        className="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg transition-all duration-200"
                        title="Delete Service"
                      >
                        <TrashIcon className="h-5 w-5" />
                      </button>
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