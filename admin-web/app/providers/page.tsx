'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Layout from '@/components/Layout';
import { isAuthenticated } from '@/lib/auth';
import { providerAPI } from '@/lib/api';
import { Provider } from '@/lib/types';
import { formatDate, truncateText } from '@/lib/utils';
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
  DocumentTextIcon,
} from '@heroicons/react/24/outline';

export default function ProvidersPage() {
  const [providers, setProviders] = useState<Provider[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedProvider, setSelectedProvider] = useState<Provider | null>(null);
  const [showModal, setShowModal] = useState(false);
  const [actionType, setActionType] = useState<'approve' | 'reject' | 'view'>('view');
  const [adminNotes, setAdminNotes] = useState('');
  const [actionLoading, setActionLoading] = useState(false);
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [totalItems, setTotalItems] = useState(0);
  const [statusFilter, setStatusFilter] = useState('pending');
  const router = useRouter();

  useEffect(() => {
    if (!isAuthenticated()) {
      router.push('/login');
      return;
    }

    fetchProviders();
  }, [router, currentPage, statusFilter]);

  const fetchProviders = async () => {
    try {
      setLoading(true);
      const response = await providerAPI.getAll({
        status: statusFilter,
        page: currentPage,
        limit: 10,
      });
      
      setProviders(response.data.providers);
      setTotalPages(response.data.pagination.pages);
      setTotalItems(response.data.pagination.total);
    } catch (error) {
      toast.error('Failed to load providers');
      console.error('Providers fetch error:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleAction = async () => {
    if (!selectedProvider) return;

    try {
      setActionLoading(true);
      
      if (actionType === 'approve') {
        await providerAPI.approve(selectedProvider.id, adminNotes);
        toast.success('Provider approved successfully');
      } else if (actionType === 'reject') {
        await providerAPI.reject(selectedProvider.id, adminNotes);
        toast.success('Provider rejected');
      }
      
      setShowModal(false);
      setSelectedProvider(null);
      setAdminNotes('');
      fetchProviders();
    } catch (error) {
      toast.error(`Failed to ${actionType} provider`);
      console.error(`Provider ${actionType} error:`, error);
    } finally {
      setActionLoading(false);
    }
  };

  const openModal = (provider: Provider, type: 'approve' | 'reject' | 'view') => {
    setSelectedProvider(provider);
    setActionType(type);
    setAdminNotes(provider.adminNotes || '');
    setShowModal(true);
  };

  const closeModal = () => {
    setShowModal(false);
    setSelectedProvider(null);
    setAdminNotes('');
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
      <div className="space-y-6">
        {/* Header */}
        <div className="flex justify-between items-center">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Provider Approvals</h1>
            <p className="mt-1 text-sm text-gray-500">
              Review and approve provider applications
            </p>
          </div>
        </div>

        {/* Filters */}
        <div className="flex space-x-4">
          <select
            value={statusFilter}
            onChange={(e) => {
              setStatusFilter(e.target.value);
              setCurrentPage(1);
            }}
            className="form-select"
          >
            <option value="all">All Providers</option>
            <option value="pending">Pending Approval</option>
            <option value="approved">Approved</option>
          </select>
        </div>

        {/* Providers Table */}
        <div className="card">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Provider</TableHead>
                <TableHead>Business Name</TableHead>
                <TableHead>Category</TableHead>
                <TableHead>Type</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Applied</TableHead>
                <TableHead>Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {providers.map((provider) => (
                <TableRow key={provider.id}>
                  <TableCell>
                    <div>
                      <div className="font-medium text-gray-900">{provider.user.name}</div>
                      <div className="text-gray-500">{provider.user.email}</div>
                    </div>
                  </TableCell>
                  <TableCell>
                    <div className="font-medium">{provider.businessName}</div>
                    <div className="text-gray-500 text-xs">
                      {truncateText(provider.description, 50)}
                    </div>
                  </TableCell>
                  <TableCell>{provider.category}</TableCell>
                  <TableCell>
                    <Badge status={provider.providerType}>
                      {provider.providerType}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    <Badge status={provider.isApproved ? 'approved' : 'pending'}>
                      {provider.isApproved ? 'Approved' : 'Pending'}
                    </Badge>
                  </TableCell>
                  <TableCell>{formatDate(provider.createdAt)}</TableCell>
                  <TableCell>
                    <div className="flex space-x-2">
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => openModal(provider, 'view')}
                      >
                        <EyeIcon className="h-4 w-4" />
                      </Button>
                      {!provider.isApproved && (
                        <>
                          <Button
                            size="sm"
                            variant="success"
                            onClick={() => openModal(provider, 'approve')}
                          >
                            <CheckIcon className="h-4 w-4" />
                          </Button>
                          <Button
                            size="sm"
                            variant="danger"
                            onClick={() => openModal(provider, 'reject')}
                          >
                            <XMarkIcon className="h-4 w-4" />
                          </Button>
                        </>
                      )}
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>

          {providers.length === 0 && (
            <div className="text-center py-12">
              <p className="text-gray-500">No providers found</p>
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

      {/* Provider Details Modal */}
      <Modal
        isOpen={showModal}
        onClose={closeModal}
        title={
          actionType === 'view' 
            ? 'Provider Details' 
            : actionType === 'approve' 
            ? 'Approve Provider' 
            : 'Reject Provider'
        }
        size="lg"
      >
        {selectedProvider && (
          <div className="space-y-6">
            {/* Provider Info */}
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700">Name</label>
                <p className="mt-1 text-sm text-gray-900">{selectedProvider.user.name}</p>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700">Email</label>
                <p className="mt-1 text-sm text-gray-900">{selectedProvider.user.email}</p>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700">Business Name</label>
                <p className="mt-1 text-sm text-gray-900">{selectedProvider.businessName}</p>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700">Provider Type</label>
                <p className="mt-1 text-sm text-gray-900 capitalize">{selectedProvider.providerType}</p>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700">Category</label>
                <p className="mt-1 text-sm text-gray-900">{selectedProvider.category}</p>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700">Location</label>
                <p className="mt-1 text-sm text-gray-900">{selectedProvider.location}</p>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700">Phone</label>
                <p className="mt-1 text-sm text-gray-900">{selectedProvider.phone}</p>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700">Applied</label>
                <p className="mt-1 text-sm text-gray-900">{formatDate(selectedProvider.createdAt)}</p>
              </div>
            </div>

            {/* Description */}
            <div>
              <label className="block text-sm font-medium text-gray-700">Description</label>
              <p className="mt-1 text-sm text-gray-900">{selectedProvider.description}</p>
            </div>

            {/* Documents/Certificates */}
            {(selectedProvider.documents || selectedProvider.certificates) && (
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  {selectedProvider.providerType === 'individual' ? 'Certificates' : 'Documents'}
                </label>
                <div className="space-y-2">
                  {(selectedProvider.certificates || selectedProvider.documents || []).map((doc: any, index: number) => (
                    <div key={index} className="flex items-center space-x-2 p-2 border border-gray-200 rounded">
                      <DocumentTextIcon className="h-5 w-5 text-gray-400" />
                      <span className="text-sm text-gray-900">{doc.name || `Document ${index + 1}`}</span>
                      {doc.url && (
                        <a
                          href={doc.url}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="text-blue-600 hover:text-blue-800 text-sm"
                        >
                          View
                        </a>
                      )}
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Admin Notes */}
            {actionType !== 'view' && (
              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Admin Notes {actionType === 'reject' && <span className="text-red-500">*</span>}
                </label>
                <textarea
                  value={adminNotes}
                  onChange={(e) => setAdminNotes(e.target.value)}
                  rows={3}
                  className="mt-1 form-textarea"
                  placeholder={
                    actionType === 'approve' 
                      ? 'Optional notes for approval...' 
                      : 'Please provide a reason for rejection...'
                  }
                  required={actionType === 'reject'}
                />
              </div>
            )}

            {/* Existing Admin Notes */}
            {selectedProvider.adminNotes && actionType === 'view' && (
              <div>
                <label className="block text-sm font-medium text-gray-700">Previous Admin Notes</label>
                <p className="mt-1 text-sm text-gray-900 p-3 bg-gray-50 rounded">
                  {selectedProvider.adminNotes}
                </p>
              </div>
            )}

            {/* Actions */}
            {actionType !== 'view' && (
              <div className="flex justify-end space-x-3">
                <Button variant="outline" onClick={closeModal}>
                  Cancel
                </Button>
                <Button
                  variant={actionType === 'approve' ? 'success' : 'danger'}
                  onClick={handleAction}
                  loading={actionLoading}
                  disabled={actionType === 'reject' && !adminNotes.trim()}
                >
                  {actionType === 'approve' ? 'Approve Provider' : 'Reject Provider'}
                </Button>
              </div>
            )}
          </div>
        )}
      </Modal>
    </Layout>
  );
}