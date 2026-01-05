'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Layout from '@/components/Layout';
import { isAuthenticated } from '@/lib/auth';
import { providerAPI } from '@/lib/api';
import { Provider } from '@/lib/types';
import { formatDate } from '@/lib/utils';
import { Table, TableHeader, TableBody, TableRow, TableHead, TableCell } from '@/components/ui/Table';
import Badge from '@/components/ui/Badge';
import Button from '@/components/ui/Button';
import Modal from '@/components/ui/Modal';
import Pagination from '@/components/ui/Pagination';
import toast, { Toaster } from 'react-hot-toast';
import {
  DocumentTextIcon,
  EyeIcon,
  CheckIcon,
  XMarkIcon,
  ArrowDownTrayIcon,
  MagnifyingGlassIcon,
} from '@heroicons/react/24/outline';

interface Document {
  id: string;
  name: string;
  type: string;
  url: string;
  uploadedAt: string;
  status: 'pending' | 'approved' | 'rejected';
  reviewNotes?: string;
}

export default function DocumentsPage() {
  const [providers, setProviders] = useState<Provider[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedProvider, setSelectedProvider] = useState<Provider | null>(null);
  const [selectedDocument, setSelectedDocument] = useState<Document | null>(null);
  const [showModal, setShowModal] = useState(false);
  const [showDocumentModal, setShowDocumentModal] = useState(false);
  const [actionType, setActionType] = useState<'approve' | 'reject'>('approve');
  const [reviewNotes, setReviewNotes] = useState('');
  const [actionLoading, setActionLoading] = useState(false);
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [totalItems, setTotalItems] = useState(0);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
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
        status: 'all',
        page: currentPage,
        limit: 10,
      });
      
      // Filter providers that have documents or certificates
      const providersWithDocs = response.data.providers.filter(provider => 
        (provider.documents && provider.documents.length > 0) ||
        (provider.certificates && provider.certificates.length > 0)
      );
      
      setProviders(providersWithDocs);
      setTotalPages(response.data.pagination.pages);
      setTotalItems(providersWithDocs.length);
    } catch (error) {
      toast.error('Failed to load providers');
      console.error('Providers fetch error:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleDocumentAction = async () => {
    if (!selectedDocument || !selectedProvider) return;

    try {
      setActionLoading(true);
      
      // Here you would call an API to approve/reject the specific document
      // For now, we'll simulate the action
      toast.success(`Document ${actionType}d successfully`);
      
      setShowDocumentModal(false);
      setSelectedDocument(null);
      setReviewNotes('');
      fetchProviders();
    } catch (error) {
      toast.error(`Failed to ${actionType} document`);
      console.error(`Document ${actionType} error:`, error);
    } finally {
      setActionLoading(false);
    }
  };

  const openProviderModal = (provider: Provider) => {
    setSelectedProvider(provider);
    setShowModal(true);
  };

  const openDocumentModal = (document: Document, type: 'approve' | 'reject') => {
    setSelectedDocument(document);
    setActionType(type);
    setReviewNotes('');
    setShowDocumentModal(true);
  };

  const closeModal = () => {
    setShowModal(false);
    setSelectedProvider(null);
  };

  const closeDocumentModal = () => {
    setShowDocumentModal(false);
    setSelectedDocument(null);
    setReviewNotes('');
  };

  const getDocumentsList = (provider: Provider) => {
    const documents: Document[] = [];
    
    // Add certificates for individual providers
    if (provider.certificates) {
      provider.certificates.forEach((cert: any, index: number) => {
        documents.push({
          id: `cert-${index}`,
          name: cert.name || `Certificate ${index + 1}`,
          type: 'Certificate',
          url: cert.url || '#',
          uploadedAt: provider.createdAt,
          status: provider.isApproved ? 'approved' : 'pending',
        });
      });
    }
    
    // Add documents for organization providers
    if (provider.documents) {
      provider.documents.forEach((doc: any, index: number) => {
        documents.push({
          id: `doc-${index}`,
          name: doc.name || `Document ${index + 1}`,
          type: 'Document',
          url: doc.url || '#',
          uploadedAt: provider.createdAt,
          status: provider.isApproved ? 'approved' : 'pending',
        });
      });
    }
    
    return documents;
  };

  const filteredProviders = providers.filter(provider =>
    provider.businessName.toLowerCase().includes(searchTerm.toLowerCase()) ||
    provider.user.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    provider.user.email.toLowerCase().includes(searchTerm.toLowerCase())
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
            <h1 className="text-2xl font-bold text-gray-900">Document Review</h1>
            <p className="mt-1 text-sm text-gray-500">
              Review provider certificates and business documents
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
                placeholder="Search providers..."
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
            <option value="all">All Providers</option>
            <option value="pending">Pending Review</option>
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
                <TableHead>Type</TableHead>
                <TableHead>Documents</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Submitted</TableHead>
                <TableHead>Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filteredProviders.map((provider) => {
                const documents = getDocumentsList(provider);
                return (
                  <TableRow key={provider.id}>
                    <TableCell>
                      <div>
                        <div className="font-medium text-gray-900">{provider.user.name}</div>
                        <div className="text-gray-500">{provider.user.email}</div>
                      </div>
                    </TableCell>
                    <TableCell>
                      <div className="font-medium">{provider.businessName}</div>
                    </TableCell>
                    <TableCell>
                      <Badge status={provider.providerType}>
                        {provider.providerType}
                      </Badge>
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center space-x-2">
                        <DocumentTextIcon className="h-5 w-5 text-gray-400" />
                        <span className="text-sm text-gray-900">{documents.length} files</span>
                      </div>
                    </TableCell>
                    <TableCell>
                      <Badge status={provider.isApproved ? 'approved' : 'pending'}>
                        {provider.isApproved ? 'Approved' : 'Pending'}
                      </Badge>
                    </TableCell>
                    <TableCell>{formatDate(provider.createdAt)}</TableCell>
                    <TableCell>
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => openProviderModal(provider)}
                      >
                        <EyeIcon className="h-4 w-4 mr-1" />
                        Review
                      </Button>
                    </TableCell>
                  </TableRow>
                );
              })}
            </TableBody>
          </Table>

          {filteredProviders.length === 0 && (
            <div className="text-center py-12">
              <DocumentTextIcon className="mx-auto h-12 w-12 text-gray-400" />
              <h3 className="mt-2 text-sm font-medium text-gray-900">No documents found</h3>
              <p className="mt-1 text-sm text-gray-500">
                No providers with documents match your search criteria.
              </p>
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

      {/* Provider Documents Modal */}
      <Modal
        isOpen={showModal}
        onClose={closeModal}
        title="Review Provider Documents"
        size="xl"
      >
        {selectedProvider && (
          <div className="space-y-6">
            {/* Provider Info */}
            <div className="bg-gray-50 p-4 rounded-lg">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700">Provider Name</label>
                  <p className="mt-1 text-sm text-gray-900">{selectedProvider.user.name}</p>
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
              </div>
            </div>

            {/* Documents List */}
            <div>
              <h3 className="text-lg font-medium text-gray-900 mb-4">
                {selectedProvider.providerType === 'individual' ? 'Certificates' : 'Documents'}
              </h3>
              
              <div className="space-y-3">
                {getDocumentsList(selectedProvider).map((document) => (
                  <div key={document.id} className="border border-gray-200 rounded-lg p-4">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center space-x-3">
                        <DocumentTextIcon className="h-8 w-8 text-gray-400" />
                        <div>
                          <h4 className="text-sm font-medium text-gray-900">{document.name}</h4>
                          <p className="text-xs text-gray-500">{document.type}</p>
                          <p className="text-xs text-gray-500">Uploaded: {formatDate(document.uploadedAt)}</p>
                        </div>
                      </div>
                      
                      <div className="flex items-center space-x-2">
                        <Badge status={document.status}>
                          {document.status}
                        </Badge>
                        
                        <div className="flex space-x-1">
                          {document.url !== '#' && (
                            <Button
                              size="sm"
                              variant="outline"
                              onClick={() => window.open(document.url, '_blank')}
                            >
                              <ArrowDownTrayIcon className="h-4 w-4" />
                            </Button>
                          )}
                          
                          {document.status === 'pending' && (
                            <>
                              <Button
                                size="sm"
                                variant="success"
                                onClick={() => openDocumentModal(document, 'approve')}
                              >
                                <CheckIcon className="h-4 w-4" />
                              </Button>
                              <Button
                                size="sm"
                                variant="danger"
                                onClick={() => openDocumentModal(document, 'reject')}
                              >
                                <XMarkIcon className="h-4 w-4" />
                              </Button>
                            </>
                          )}
                        </div>
                      </div>
                    </div>
                    
                    {document.reviewNotes && (
                      <div className="mt-3 p-3 bg-gray-50 rounded">
                        <p className="text-sm text-gray-700">
                          <strong>Review Notes:</strong> {document.reviewNotes}
                        </p>
                      </div>
                    )}
                  </div>
                ))}
              </div>
            </div>

            {/* Provider Notes */}
            {selectedProvider.adminNotes && (
              <div>
                <label className="block text-sm font-medium text-gray-700">Admin Notes</label>
                <p className="mt-1 text-sm text-gray-900 p-3 bg-gray-50 rounded">
                  {selectedProvider.adminNotes}
                </p>
              </div>
            )}
          </div>
        )}
      </Modal>

      {/* Document Action Modal */}
      <Modal
        isOpen={showDocumentModal}
        onClose={closeDocumentModal}
        title={`${actionType === 'approve' ? 'Approve' : 'Reject'} Document`}
        size="md"
      >
        {selectedDocument && (
          <div className="space-y-6">
            <div>
              <h4 className="text-lg font-medium text-gray-900">{selectedDocument.name}</h4>
              <p className="text-sm text-gray-500">{selectedDocument.type}</p>
            </div>

            {actionType === 'reject' && (
              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Reason for Rejection <span className="text-red-500">*</span>
                </label>
                <textarea
                  value={reviewNotes}
                  onChange={(e) => setReviewNotes(e.target.value)}
                  rows={3}
                  className="mt-1 form-textarea"
                  placeholder="Please provide a reason for rejecting this document..."
                  required
                />
              </div>
            )}

            {actionType === 'approve' && (
              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Review Notes (Optional)
                </label>
                <textarea
                  value={reviewNotes}
                  onChange={(e) => setReviewNotes(e.target.value)}
                  rows={3}
                  className="mt-1 form-textarea"
                  placeholder="Optional notes about the document review..."
                />
              </div>
            )}

            <div className="flex justify-end space-x-3">
              <Button variant="outline" onClick={closeDocumentModal}>
                Cancel
              </Button>
              <Button
                variant={actionType === 'approve' ? 'success' : 'danger'}
                onClick={handleDocumentAction}
                loading={actionLoading}
                disabled={actionType === 'reject' && !reviewNotes.trim()}
              >
                {actionType === 'approve' ? 'Approve Document' : 'Reject Document'}
              </Button>
            </div>
          </div>
        )}
      </Modal>
    </Layout>
  );
}