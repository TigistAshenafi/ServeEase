'use client';

import { formatDate } from '@/lib/utils';
import {
  UserIcon,
  BuildingOfficeIcon,
  MapPinIcon,
  PhoneIcon,
  EnvelopeIcon,
  CalendarIcon,
  CheckCircleIcon,
  XCircleIcon,
  ClockIcon,
  DocumentIcon,
  AcademicCapIcon,
} from '@heroicons/react/24/outline';

interface Provider {
  id: string;
  businessName: string;
  description?: string;
  category: string;
  location: string;
  phone?: string;
  profileImageUrl?: string;
  providerType: 'individual' | 'organization';
  status: 'pending' | 'approved' | 'rejected';
  approvalDate?: string;
  adminNotes?: string;
  documents?: any;
  certificates?: any;
  user: {
    id?: string;
    name: string;
    email: string;
    emailVerified?: boolean;
    createdAt?: string;
  };
  applicationDate?: string;
  createdAt?: string;
  updatedAt?: string;
  documentsCount?: number;
  rating?: number;
}

interface ProviderDetailViewProps {
  provider: Provider;
}

export default function ProviderDetailView({ provider }: ProviderDetailViewProps) {
  const getStatusBadge = (status: string) => {
    const baseClasses = 'inline-flex items-center px-3 py-1 rounded-full text-sm font-medium';
    switch (status) {
      case 'approved':
        return `${baseClasses} bg-emerald-100 text-emerald-800 border border-emerald-200`;
      case 'rejected':
        return `${baseClasses} bg-red-100 text-red-800 border border-red-200`;
      case 'pending':
        return `${baseClasses} bg-yellow-100 text-yellow-800 border border-yellow-200`;
      default:
        return `${baseClasses} bg-gray-100 text-gray-800 border border-gray-200`;
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'approved':
        return <CheckCircleIcon className="h-5 w-5 text-emerald-600" />;
      case 'rejected':
        return <XCircleIcon className="h-5 w-5 text-red-600" />;
      case 'pending':
        return <ClockIcon className="h-5 w-5 text-yellow-600" />;
      default:
        return <ClockIcon className="h-5 w-5 text-gray-600" />;
    }
  };

  const renderDocuments = (docs: any, type: 'documents' | 'certificates') => {
    if (!docs || typeof docs !== 'object' || Object.keys(docs).length === 0) {
      return (
        <p className="text-sm text-gray-500 italic">
          No {type} uploaded
        </p>
      );
    }

    return (
      <div className="space-y-2">
        {Object.entries(docs).map(([key, doc]: [string, any]) => (
          <div key={key} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
            <div className="flex items-center space-x-3">
              {type === 'certificates' ? (
                <AcademicCapIcon className="h-5 w-5 text-blue-600" />
              ) : (
                <DocumentIcon className="h-5 w-5 text-gray-600" />
              )}
              <div>
                <p className="text-sm font-medium text-gray-900">
                  {doc.name || `${key}.pdf`}
                </p>
                <p className="text-xs text-gray-500">
                  {doc.size ? `${(doc.size / 1024).toFixed(1)} KB` : 'Unknown size'}
                </p>
              </div>
            </div>
            {doc.url && (
              <button
                onClick={() => window.open(doc.url, '_blank')}
                className="text-blue-600 hover:text-blue-800 text-sm font-medium"
              >
                View
              </button>
            )}
          </div>
        ))}
      </div>
    );
  };

  return (
    <div className="space-y-6">
      {/* Provider Header */}
      <div className="flex items-start justify-between">
        <div className="flex items-center space-x-4">
          <div className="w-16 h-16 bg-gradient-to-br from-blue-100 to-blue-200 rounded-full flex items-center justify-center">
            {provider.providerType === 'organization' ? (
              <BuildingOfficeIcon className="h-8 w-8 text-blue-600" />
            ) : (
              <UserIcon className="h-8 w-8 text-blue-600" />
            )}
          </div>
          <div>
            <h3 className="text-xl font-bold text-gray-900">{provider.businessName}</h3>
            <p className="text-sm text-gray-600 capitalize">{provider.providerType} Provider</p>
          </div>
        </div>
        <div className="flex items-center space-x-2">
          {getStatusIcon(provider.status)}
          <span className={getStatusBadge(provider.status)}>
            {provider.status.charAt(0).toUpperCase() + provider.status.slice(1)}
          </span>
        </div>
      </div>

      {/* Basic Information */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="space-y-4">
          <h4 className="text-lg font-semibold text-gray-900">Basic Information</h4>
          
          <div className="space-y-3">
            <div className="flex items-center space-x-3">
              <UserIcon className="h-5 w-5 text-gray-400" />
              <div>
                <p className="text-sm font-medium text-gray-900">Owner Name</p>
                <p className="text-sm text-gray-600">{provider.user.name}</p>
              </div>
            </div>

            <div className="flex items-center space-x-3">
              <EnvelopeIcon className="h-5 w-5 text-gray-400" />
              <div>
                <p className="text-sm font-medium text-gray-900">Email</p>
                <div className="flex items-center space-x-2">
                  <p className="text-sm text-gray-600">{provider.user.email}</p>
                  {provider.user.emailVerified ? (
                    <CheckCircleIcon className="h-4 w-4 text-emerald-500" title="Verified" />
                  ) : (
                    <XCircleIcon className="h-4 w-4 text-red-500" title="Not verified" />
                  )}
                </div>
              </div>
            </div>

            <div className="flex items-center space-x-3">
              <PhoneIcon className="h-5 w-5 text-gray-400" />
              <div>
                <p className="text-sm font-medium text-gray-900">Phone</p>
                <p className="text-sm text-gray-600">{provider.phone || 'Not provided'}</p>
              </div>
            </div>

            <div className="flex items-center space-x-3">
              <MapPinIcon className="h-5 w-5 text-gray-400" />
              <div>
                <p className="text-sm font-medium text-gray-900">Location</p>
                <p className="text-sm text-gray-600">{provider.location || 'Not provided'}</p>
              </div>
            </div>
          </div>
        </div>

        <div className="space-y-4">
          <h4 className="text-lg font-semibold text-gray-900">Service Information</h4>
          
          <div className="space-y-3">
            <div>
              <p className="text-sm font-medium text-gray-900">Category</p>
              <p className="text-sm text-gray-600">{provider.category || 'Not specified'}</p>
            </div>

            <div>
              <p className="text-sm font-medium text-gray-900">Description</p>
              <p className="text-sm text-gray-600">{provider.description || 'No description provided'}</p>
            </div>
          </div>
        </div>
      </div>

      {/* Timeline Information */}
      <div className="space-y-4">
        <h4 className="text-lg font-semibold text-gray-900">Timeline</h4>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="flex items-center space-x-3 p-3 bg-gray-50 rounded-lg">
            <CalendarIcon className="h-5 w-5 text-gray-400" />
            <div>
              <p className="text-sm font-medium text-gray-900">Registered</p>
              <p className="text-sm text-gray-600">{provider.user.createdAt ? formatDate(provider.user.createdAt) : 'Unknown'}</p>
            </div>
          </div>

          <div className="flex items-center space-x-3 p-3 bg-gray-50 rounded-lg">
            <CalendarIcon className="h-5 w-5 text-gray-400" />
            <div>
              <p className="text-sm font-medium text-gray-900">Profile Created</p>
              <p className="text-sm text-gray-600">{provider.createdAt ? formatDate(provider.createdAt) : (provider.applicationDate ? formatDate(provider.applicationDate) : 'Unknown')}</p>
            </div>
          </div>

          {provider.approvalDate && (
            <div className="flex items-center space-x-3 p-3 bg-gray-50 rounded-lg">
              <CheckCircleIcon className="h-5 w-5 text-emerald-500" />
              <div>
                <p className="text-sm font-medium text-gray-900">Approved</p>
                <p className="text-sm text-gray-600">{formatDate(provider.approvalDate)}</p>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Documents Section */}
      <div className="space-y-4">
        <h4 className="text-lg font-semibold text-gray-900">Documents & Certificates</h4>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <h5 className="text-md font-medium text-gray-900 mb-3">Business Documents</h5>
            {renderDocuments(provider.documents, 'documents')}
          </div>
          
          <div>
            <h5 className="text-md font-medium text-gray-900 mb-3">Certificates</h5>
            {renderDocuments(provider.certificates, 'certificates')}
          </div>
        </div>
      </div>

      {/* Admin Notes */}
      {provider.adminNotes && (
        <div className="space-y-4">
          <h4 className="text-lg font-semibold text-gray-900">Admin Notes</h4>
          <div className="p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
            <p className="text-sm text-gray-700">{provider.adminNotes}</p>
          </div>
        </div>
      )}
    </div>
  );
}