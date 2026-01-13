'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Layout from '@/components/Layout';
import { isAuthenticated } from '@/lib/auth';
import { documentsAPI } from '@/lib/api';
import { formatDate, debounce } from '@/lib/utils';
import toast, { Toaster } from 'react-hot-toast';
import ConfirmDialog from '@/components/ConfirmDialog';
import DetailModal from '@/components/DetailModal';
import DocumentDetailView from '@/components/DocumentDetailView';
import {
  DocumentIcon,
  EyeIcon,
  ArrowDownTrayIcon,
  TrashIcon,
  FolderIcon,
  DocumentTextIcon,
  PhotoIcon,
  MagnifyingGlassIcon,
  CloudArrowUpIcon,
} from '@heroicons/react/24/outline';

interface Document {
  id: string;
  name: string;
  type: 'pdf' | 'image' | 'document' | 'certificate';
  size: number;
  uploadDate: string;
  uploadedBy: {
    name: string;
    email: string;
  };
  category: 'provider_documents' | 'certificates' | 'system_files' | 'reports';
  url: string;
  providerId?: string;
  businessName?: string;
}

export default function DocumentsPage() {
  const [documents, setDocuments] = useState<Document[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<'all' | 'provider_documents' | 'certificates' | 'system_files' | 'reports'>('all');
  const [searchTerm, setSearchTerm] = useState('');
  const [pagination, setPagination] = useState({
    page: 1,
    limit: 20,
    total: 0,
    pages: 0
  });
  const [deleteDialog, setDeleteDialog] = useState<{ isOpen: boolean; documentId: string | null; documentName: string }>({
    isOpen: false,
    documentId: null,
    documentName: ''
  });
  const [viewModal, setViewModal] = useState<{ isOpen: boolean; document: Document | null }>({
    isOpen: false,
    document: null
  });
  const [viewMode, setViewMode] = useState<'list' | 'grid'>('list');
  const router = useRouter();

  useEffect(() => {
    if (!isAuthenticated()) {
      router.push('/login');
      return;
    }

    // Reset pagination when filter changes
    setPagination(prev => ({ ...prev, page: 1 }));
    fetchDocuments();
  }, [router, filter]);

  const fetchDocuments = async () => {
    try {
      setLoading(true);
      
      const params: any = {
        page: pagination.page,
        limit: pagination.limit
      };
      
      if (filter !== 'all') {
        params.category = filter;
      }
      
      const response = await documentsAPI.getAll(params);
      
      if (response.data.success) {
        let fetchedDocuments = response.data.documents.map((doc: any) => ({
          id: doc.id,
          name: doc.name,
          type: doc.type,
          size: doc.size,
          uploadDate: doc.uploadDate,
          uploadedBy: {
            name: doc.uploadedBy.name,
            email: doc.uploadedBy.email
          },
          category: doc.category,
          url: doc.url,
          providerId: doc.providerId,
          businessName: doc.businessName
        }));

        // Apply search filter (client-side for now)
        if (searchTerm) {
          fetchedDocuments = fetchedDocuments.filter((doc: Document) => 
            doc.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
            doc.uploadedBy.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
            (doc.businessName && doc.businessName.toLowerCase().includes(searchTerm.toLowerCase()))
          );
        }
        
        setDocuments(fetchedDocuments);
        setPagination(response.data.pagination);
      } else {
        toast.error(response.data.message || 'Failed to load documents');
      }
    } catch (error: any) {
      const errorMessage = error.response?.data?.message || 'Failed to load documents';
      toast.error(errorMessage);
      console.error('Documents fetch error:', error);
    } finally {
      setLoading(false);
    }
  };

  // Debounced search function
  const debouncedFetchDocuments = debounce(fetchDocuments, 300);

  // Re-fetch when search term changes (debounced)
  useEffect(() => {
    if (searchTerm !== '') {
      debouncedFetchDocuments();
    } else {
      fetchDocuments();
    }
  }, [searchTerm]);

  const handleDownload = (document: Document) => {
    toast.success(`Downloading ${document.name}`);
    // In a real implementation, you would trigger the actual download
    // window.open(document.url, '_blank');
  };

  const handleView = (document: Document) => {
    setViewModal({ isOpen: true, document });
  };

  const handleDelete = (documentId: string, documentName: string) => {
    setDeleteDialog({ isOpen: true, documentId, documentName });
  };

  const confirmDelete = async () => {
    if (!deleteDialog.documentId) return;

    try {
      await documentsAPI.delete(deleteDialog.documentId);
      toast.success('Document deleted successfully');
      fetchDocuments();
    } catch (error: any) {
      const errorMessage = error.response?.data?.message || 'Failed to delete document';
      toast.error(errorMessage);
      console.error('Delete error:', error);
    }
  };

  const getDocumentIcon = (type: string) => {
    switch (type) {
      case 'pdf':
      case 'document':
        return DocumentTextIcon;
      case 'image':
        return PhotoIcon;
      case 'certificate':
        return DocumentIcon;
      default:
        return DocumentIcon;
    }
  };

  const getCategoryBadge = (category: string) => {
    const baseClasses = 'inline-flex items-center px-3 py-1 rounded-full text-xs font-medium';
    switch (category) {
      case 'certificates':
        return `${baseClasses} bg-emerald-100 text-emerald-800 border border-emerald-200`;
      case 'provider_documents':
        return `${baseClasses} bg-blue-100 text-blue-800 border border-blue-200`;
      case 'reports':
        return `${baseClasses} bg-amber-100 text-amber-800 border border-amber-200`;
      case 'system_files':
        return `${baseClasses} bg-purple-100 text-purple-800 border border-purple-200`;
      default:
        return `${baseClasses} bg-gray-100 text-gray-800 border border-gray-200`;
    }
  };

  const getCategoryDisplayName = (category: string) => {
    switch (category) {
      case 'certificates':
        return 'Provider Certificate';
      case 'provider_documents':
        return 'Business License';
      case 'reports':
        return 'System Report';
      case 'system_files':
        return 'System File';
      default:
        return category.replace('_', ' ');
    }
  };

  const formatFileSize = (bytes: number) => {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
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
      
      {/* Confirmation Dialog */}
      <ConfirmDialog
        isOpen={deleteDialog.isOpen}
        onClose={() => setDeleteDialog({ isOpen: false, documentId: null, documentName: '' })}
        onConfirm={confirmDelete}
        title="Delete Document"
        message={`Are you sure you want to delete "${deleteDialog.documentName}"? This action cannot be undone and will permanently remove the document from the system.`}
        confirmText="Delete"
        cancelText="Cancel"
        type="danger"
      />
      
      {/* View Modal */}
      <DetailModal
        isOpen={viewModal.isOpen}
        onClose={() => setViewModal({ isOpen: false, document: null })}
        title={`Document Details - ${viewModal.document?.name || ''}`}
        size="xl"
      >
        {viewModal.document && <DocumentDetailView document={viewModal.document} />}
      </DetailModal>
      
      <div className="space-y-8">
        {/* Enhanced Header */}
        <div className="bg-gradient-to-r from-blue-600 to-blue-700 rounded-xl p-8 text-white">
          <div className="flex justify-between items-start">
            <div>
              <h1 className="text-3xl font-bold mb-2">Document Management</h1>
              <p className="text-blue-100 text-lg">Review provider certificates, licenses, and system reports</p>
              <div className="flex items-center space-x-6 mt-4">
                <div className="flex items-center space-x-2">
                  <FolderIcon className="h-5 w-5 text-blue-200" />
                  <span className="text-blue-100">{documents.length} documents</span>
                </div>
                <div className="flex items-center space-x-2">
                  <CloudArrowUpIcon className="h-5 w-5 text-blue-200" />
                  <span className="text-blue-100">
                    {(documents.reduce((acc, doc) => acc + doc.size, 0) / (1024 * 1024)).toFixed(1)} MB total
                  </span>
                </div>
              </div>
            </div>
            <div className="text-right">
              <p className="text-blue-100 text-sm">Auto-refreshed</p>
              <p className="text-white font-medium">{new Date().toLocaleTimeString()}</p>
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
                placeholder="Search documents..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-200"
              />
            </div>

            {/* View Mode Toggle */}
            <div className="flex items-center space-x-2 bg-gray-100 rounded-lg p-1">
              <button
                onClick={() => setViewMode('list')}
                className={`px-3 py-2 rounded-md text-sm font-medium transition-colors duration-200 ${
                  viewMode === 'list'
                    ? 'bg-white text-gray-900 shadow-sm'
                    : 'text-gray-600 hover:text-gray-900'
                }`}
              >
                List
              </button>
              <button
                onClick={() => setViewMode('grid')}
                className={`px-3 py-2 rounded-md text-sm font-medium transition-colors duration-200 ${
                  viewMode === 'grid'
                    ? 'bg-white text-gray-900 shadow-sm'
                    : 'text-gray-600 hover:text-gray-900'
                }`}
              >
                Grid
              </button>
            </div>
          </div>

          {/* Category Filters */}
          <div className="flex flex-wrap gap-3 mt-6">
            {[
              { key: 'all', label: 'All Documents', count: documents.length },
              { key: 'certificates', label: 'Provider Certificates', count: documents.filter(d => d.category === 'certificates').length },
              { key: 'provider_documents', label: 'Business Licenses', count: documents.filter(d => d.category === 'provider_documents').length },
              { key: 'reports', label: 'System Reports', count: documents.filter(d => d.category === 'reports').length },
              { key: 'system_files', label: 'System Files', count: documents.filter(d => d.category === 'system_files').length }
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

        {/* Enhanced Documents Display */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
          {documents.length === 0 ? (
            <div className="px-6 py-16 text-center">
              <FolderIcon className="mx-auto h-16 w-16 text-gray-300 mb-4" />
              <h3 className="text-lg font-medium text-gray-900 mb-2">No documents found</h3>
              <p className="text-gray-500 mb-6">
                {searchTerm ? 'Try adjusting your search terms' : 'Documents will appear here when providers upload certificates or system generates reports'}
              </p>
            </div>
          ) : (
            <div className="divide-y divide-gray-100">
              {documents.map((document) => {
                const IconComponent = getDocumentIcon(document.type);
                return (
                  <div key={document.id} className="p-6 hover:bg-gray-50 transition-colors duration-200">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center space-x-4 flex-1 min-w-0">
                        <div className="flex-shrink-0">
                          <div className="w-12 h-12 bg-gray-100 rounded-lg flex items-center justify-center">
                            <IconComponent className="h-6 w-6 text-gray-600" />
                          </div>
                        </div>
                        <div className="flex-1 min-w-0">
                          <h3 className="text-sm font-semibold text-gray-900 truncate mb-1">
                            {document.name}
                          </h3>
                          <p className="text-sm text-gray-600 mb-2">
                            Submitted by <span className="font-medium">{document.uploadedBy.name}</span>
                            {document.businessName && (
                              <span className="text-gray-500"> from {document.businessName}</span>
                            )}
                          </p>
                          <div className="flex items-center space-x-4">
                            <span className={getCategoryBadge(document.category)}>
                              {getCategoryDisplayName(document.category)}
                            </span>
                            <span className="text-xs text-gray-500 bg-gray-100 px-2 py-1 rounded">
                              {formatFileSize(document.size)}
                            </span>
                            <span className="text-xs text-gray-500">
                              {formatDate(document.uploadDate)}
                            </span>
                          </div>
                        </div>
                      </div>
                      
                      <div className="flex items-center space-x-2 ml-4">
                        <button
                          onClick={() => handleView(document)}
                          className="p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-all duration-200"
                          title="View Document"
                        >
                          <EyeIcon className="h-5 w-5" />
                        </button>
                        
                        <button
                          onClick={() => handleDownload(document)}
                          className="p-2 text-gray-400 hover:text-green-600 hover:bg-green-50 rounded-lg transition-all duration-200"
                          title="Download Document"
                        >
                          <ArrowDownTrayIcon className="h-5 w-5" />
                        </button>
                        
                        <button
                          onClick={() => handleDelete(document.id, document.name)}
                          className="p-2 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-all duration-200"
                          title="Delete Document"
                        >
                          <TrashIcon className="h-5 w-5" />
                        </button>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </div>
    </Layout>
  );
}