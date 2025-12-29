'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Layout from '@/components/Layout';
import { isAuthenticated } from '@/lib/auth';
import { serviceAPI } from '@/lib/api';
import { Service } from '@/lib/types';
import { formatDate, formatCurrency, truncateText } from '@/lib/utils';
import { Table, TableHeader, TableBody, TableRow, TableHead, TableCell } from '@/components/ui/Table';
import Badge from '@/components/ui/Badge';
import Button from '@/components/ui/Button';
import Modal from '@/components/ui/Modal';
import Pagination from '@/components/ui/Pagination';
import toast, { Toaster } from 'react-hot-toast';
import {
  EyeIcon,
  CheckIcon,
  XMarkIcon,
  TrashIcon,
  MagnifyingGlassIcon,
} from '@heroicons/react/24/outline';

export default function ServicesPage() {
  const [services, setServices] = useState<Service[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedService, setSelectedService] = useState<Service | null>(null);
  const [showModal, setShowModal] = useState(false);
  const [actionType, setActionType] = useState<'approve' | 'reject' | 'delete' | 'view'>('view');
  const [reason, setReason] = useState('');
  const [actionLoading, setActionLoading] = useState(false);
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [totalItems, setTotalItems] = useState(0);
  const [statusFilter, setStatusFilter] = useState('all');
  const [searchTerm, setSearchTerm] = useState('');
  const router = useRouter();

  useEffect(() => {
    if (!isAuthenticated()) {
      router.push('/login');
      return;
    }

    fetchServices();
  }, [router, currentPage, statusFilter]);

  const fetchServices = async () => {
    try {
      setLoading(true);
      const response = await serviceAPI.getAll({
        page: currentPage,
        limit: 10,
        status: statusFilter === 'all' ? undefined : statusFilter,
      });
      
      setServices(response.data.services);
      setTotalPages(response.data.pagination.pages);
      setTotalItems(response.data.pagination.total);
    } catch (error) {
      toast.error('Failed to load services');
      console.error('Services fetch error:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleAction = async () => {
    if (!selectedService) return;

    try {
      setActionLoading(true);
      
      switch (actionType) {
        case 'approve':
          await serviceAPI.approve(selectedService.id);
          toast.success('Service approved successfully');
          break;
        case 'reject':
          await serviceAPI.reject(selectedService.id, reason);
          toast.success('Service rejected');
          break;
        case 'delete':
          await serviceAPI.delete(selectedService.id);
          toast.success('Service deleted successfully');
          break;
      }
      
      setShowModal(false);
      setSelectedService(null);
      setReason('');
      fetchServices();
    } catch (error) {
      toast.error(`Failed to ${actionType} service`);
      console.error(`Service ${actionType} error:`, error);
    } finally {
      setActionLoading(false);
    }
  };

  const openModal = (service: Service, type: 'approve' | 'reject' | 'delete' | 'view') => {
    setSelectedService(service);
    setActionType(type);
    setReason('');
    setShowModal(true);
  };

  const closeModal = () => {
    setShowModal(false);
    setSelectedService(null);
    setReason('');
  };

  const filteredServices = services.filter(service =>
    service.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
    service.description.toLowerCase().includes(searchTerm.toLowerCase()) ||
    service.provider?.businessName.toLowerCase().includes(searchTerm.toLowerCase())
  );

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
      <div className="space-y-6">
        {/* Header */}
        <div className="flex justify-between items-center">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Service Moderation</h1>
            <p className="mt-1 text-sm text-gray-500">
              Review and moderate platform services
            </p>
          </div>
        </div>

        {/* Filters and Search */}
        <div className="flex flex-col sm:flex-row gap-4">
          <div className="flex-1">
            <div className="relative">
              <MagnifyingGlassIcon className="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
              <input
                type="text"
                placeholder="Search services..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-10 form-input"
              />
            </div>
          </div>
          <select
            value={statusFilter}
            onChange={(e) => {
              setStatusFilter(e.target.value);
              setCurrentPage(1);
            }}
            className="form-select"
          >
            <option value="all">All Services</option>
            <option value="active">Active</option>
            <option value="inactive">Inactive</option>
            <option value="pending">Pending Review</option>
          </select>
        </div>

        {/* Services Table */}
        <div className="card">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Service</TableHead>
                <TableHead>Provider</TableHead>
                <TableHead>Category</TableHead>
                <TableHead>Price</TableHead>
                <TableHead>Duration</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Created</TableHead>
                <TableHead>Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filteredServices.map((service) => (
                <TableRow key={service.id}>
                  <TableCell>
                    <div>
                      <div className="font-medium text-gray-900">{service.title}</div>
                      <div className="text-gray-500 text-xs">
                        {truncateText(service.description, 50)}
                      </div>
                    </div>
                  </TableCell>
                  <TableCell>
                    <div>
                      <div className="font-medium text-gray-900">
                        {service.provider?.businessName}
                      </div>
                      <div className="text-gray-500 text-xs">
                        {service.provider?.user.name}
                      </div>
                    </div>
                  </TableCell>
                  <TableCell>{service.category?.name}</TableCell>
                  <TableCell>{formatCurrency(service.price)}</TableCell>
                  <TableCell>{service.durationHours}h</TableCell>
                  <TableCell>
                    <Badge status={service.isActive ? 'active' : 'inactive'}>
                      {service.isActive ? 'Active' : 'Inactive'}
                    </Badge>
                  </TableCell>
                  <TableCell>{formatDate(service.createdAt)}</TableCell>
                  <TableCell>
                    <div className="flex space-x-2">
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => openModal(service, 'view')}
                      >
                        <EyeIcon className="h-4 w-4" />
                      </Button>
                      {service.isActive && (
                        <Button
                          size="sm"
                          variant="danger"
                          onClick={() => openModal(service, 'reject')}
                        >
                          <XMarkIcon className="h-4 w-4" />
                        </Button>
                      )}
                      {!service.isActive && (
                        <Button
                          size="sm"
                          variant="success"
                          onClick={() => openModal(service, 'approve')}
                        >
                          <CheckIcon className="h-4 w-4" />
                        </Button>
                      )}
                      <Button
                        size="sm"
                        variant="danger"
                        onClick={() => openModal(service, 'delete')}
                      >
                        <TrashIcon className="h-4 w-4" />
                      </Button>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>

          {filteredServices.length === 0 && (
            <div className="text-center py-12">
              <p className="text-gray-500">No services found</p>
            </div>
          )}

          <Pagination
            currentPage={currentPage}
            totalPages={totalPages}
            onPageChange={setCurrentPage}
            totalItems={totalItems}
            itemsPerPage={10}
          />
        </div>
      </div>

      {/* Service Details Modal */}
      <Modal
        isOpen={showModal}
        onClose={closeModal}
        title={
          actionType === 'view' 
            ? 'Service Details' 
            : actionType === 'approve'
            ? 'Approve Service'
            : actionType === 'reject'
            ? 'Reject Service'
            : 'Delete Service'
        }
        size="lg"
      >
        {selectedService && (
          <div className="space-y-6">
            {/* Service Info */}
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700">Title</label>
                <p className="mt-1 text-sm text-gray-900">{selectedService.title}</p>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700">Category</label>
                <p className="mt-1 text-sm text-gray-900">{selectedService.category?.name}</p>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700">Price</label>
                <p className="mt-1 text-sm text-gray-900">{formatCurrency(selectedService.price)}</p>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700">Duration</label>
                <p className="mt-1 text-sm text-gray-900">{selectedService.durationHours} hours</p>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700">Status</label>
                <p className="mt-1 text-sm text-gray-900">
                  {selectedService.isActive ? 'Active' : 'Inactive'}
                </p>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700">Created</label>
                <p className="mt-1 text-sm text-gray-900">{formatDate(selectedService.createdAt)}</p>
              </div>
            </div>

            {/* Description */}
            <div>
              <label className="block text-sm font-medium text-gray-700">Description</label>
              <p className="mt-1 text-sm text-gray-900 p-3 bg-gray-50 rounded">
                {selectedService.description}
              </p>
            </div>

            {/* Provider Info */}
            <div>
              <label className="block text-sm font-medium text-gray-700">Provider Information</label>
              <div className="mt-1 p-3 bg-gray-50 rounded">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <span className="text-sm font-medium text-gray-700">Business Name:</span>
                    <p className="text-sm text-gray-900">{selectedService.provider?.businessName}</p>
                  </div>
                  <div>
                    <span className="text-sm font-medium text-gray-700">Owner:</span>
                    <p className="text-sm text-gray-900">{selectedService.provider?.user.name}</p>
                  </div>
                  <div>
                    <span className="text-sm font-medium text-gray-700">Email:</span>
                    <p className="text-sm text-gray-900">{selectedService.provider?.user.email}</p>
                  </div>
                </div>
              </div>
            </div>

            {/* Action-specific content */}
            {actionType === 'reject' && (
              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Reason for Rejection <span className="text-red-500">*</span>
                </label>
                <textarea
                  value={reason}
                  onChange={(e) => setReason(e.target.value)}
                  rows={3}
                  className="mt-1 form-textarea"
                  placeholder="Please provide a reason for rejecting this service..."
                  required
                />
              </div>
            )}

            {actionType === 'delete' && (
              <div className="bg-red-50 border border-red-200 rounded-md p-4">
                <div className="flex">
                  <div className="ml-3">
                    <h3 className="text-sm font-medium text-red-800">
                      Warning: This action cannot be undone
                    </h3>
                    <div className="mt-2 text-sm text-red-700">
                      <p>
                        Deleting this service will permanently remove it from the platform.
                        Any pending service requests for this service will be cancelled.
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {actionType === 'approve' && (
              <div className="bg-green-50 border border-green-200 rounded-md p-4">
                <div className="flex">
                  <div className="ml-3">
                    <h3 className="text-sm font-medium text-green-800">
                      Approve Service
                    </h3>
                    <div className="mt-2 text-sm text-green-700">
                      <p>
                        This service will be made active and visible to users on the platform.
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* Actions */}
            {actionType !== 'view' && (
              <div className="flex justify-end space-x-3">
                <Button variant="outline" onClick={closeModal}>
                  Cancel
                </Button>
                <Button
                  variant={
                    actionType === 'approve' ? 'success' : 'danger'
                  }
                  onClick={handleAction}
                  loading={actionLoading}
                  disabled={actionType === 'reject' && !reason.trim()}
                >
                  {actionType === 'approve' && 'Approve Service'}
                  {actionType === 'reject' && 'Reject Service'}
                  {actionType === 'delete' && 'Delete Service'}
                </Button>
              </div>
            )}
          </div>
        )}
      </Modal>
    </Layout>
  );
}