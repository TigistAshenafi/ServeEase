'use client';

import { formatDate } from '@/lib/utils';
import {
  DocumentIcon,
  DocumentTextIcon,
  PhotoIcon,
  UserIcon,
  BuildingOfficeIcon,
  CalendarIcon,
  FolderIcon,
  ArrowDownTrayIcon,
  EyeIcon,
  InformationCircleIcon,
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

interface DocumentDetailViewProps {
  document: Document;
}

export default function DocumentDetailView({ document }: DocumentDetailViewProps) {
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

  const getCategoryInfo = (category: string) => {
    switch (category) {
      case 'certificates':
        return {
          name: 'Provider Certificate',
          description: 'Professional certification or license document',
          color: 'emerald',
          bgColor: 'bg-emerald-50',
          textColor: 'text-emerald-800',
          borderColor: 'border-emerald-200'
        };
      case 'provider_documents':
        return {
          name: 'Business License',
          description: 'Business registration or legal documentation',
          color: 'blue',
          bgColor: 'bg-blue-50',
          textColor: 'text-blue-800',
          borderColor: 'border-blue-200'
        };
      case 'reports':
        return {
          name: 'System Report',
          description: 'System-generated analytics or activity report',
          color: 'amber',
          bgColor: 'bg-amber-50',
          textColor: 'text-amber-800',
          borderColor: 'border-amber-200'
        };
      case 'system_files':
        return {
          name: 'System File',
          description: 'System configuration or administrative file',
          color: 'purple',
          bgColor: 'bg-purple-50',
          textColor: 'text-purple-800',
          borderColor: 'border-purple-200'
        };
      default:
        return {
          name: 'Document',
          description: 'General document file',
          color: 'gray',
          bgColor: 'bg-gray-50',
          textColor: 'text-gray-800',
          borderColor: 'border-gray-200'
        };
    }
  };

  const formatFileSize = (bytes: number) => {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  };

  const getFileExtension = (filename: string) => {
    return filename.split('.').pop()?.toUpperCase() || 'FILE';
  };

  const handleDownload = () => {
    // In a real implementation, this would trigger the actual download
    window.open(document.url, '_blank');
  };

  const handleView = () => {
    // In a real implementation, this would open a document viewer
    window.open(document.url, '_blank');
  };

  const IconComponent = getDocumentIcon(document.type);
  const categoryInfo = getCategoryInfo(document.category);

  return (
    <div className="space-y-6">
      {/* Document Header */}
      <div className="flex items-start space-x-4">
        <div className="w-16 h-16 bg-gradient-to-br from-gray-100 to-gray-200 rounded-lg flex items-center justify-center border border-gray-200">
          <IconComponent className="h-8 w-8 text-gray-600" />
        </div>
        <div className="flex-1 min-w-0">
          <h3 className="text-xl font-bold text-gray-900 truncate">{document.name}</h3>
          <div className="flex items-center space-x-4 mt-2">
            <span className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium ${categoryInfo.bgColor} ${categoryInfo.textColor} ${categoryInfo.borderColor} border`}>
              {categoryInfo.name}
            </span>
            <span className="text-sm text-gray-500 bg-gray-100 px-2 py-1 rounded">
              {getFileExtension(document.name)}
            </span>
          </div>
        </div>
      </div>

      {/* Quick Actions */}
      <div className="flex space-x-3">
        <button
          onClick={handleView}
          className="flex items-center space-x-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors duration-200"
        >
          <EyeIcon className="h-4 w-4" />
          <span>View Document</span>
        </button>
        <button
          onClick={handleDownload}
          className="flex items-center space-x-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors duration-200"
        >
          <ArrowDownTrayIcon className="h-4 w-4" />
          <span>Download</span>
        </button>
      </div>

      {/* Document Information */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="space-y-4">
          <h4 className="text-lg font-semibold text-gray-900">Document Details</h4>
          
          <div className="space-y-3">
            <div className="flex items-center space-x-3">
              <FolderIcon className="h-5 w-5 text-gray-400" />
              <div>
                <p className="text-sm font-medium text-gray-900">File Name</p>
                <p className="text-sm text-gray-600 break-all">{document.name}</p>
              </div>
            </div>

            <div className="flex items-center space-x-3">
              <InformationCircleIcon className="h-5 w-5 text-gray-400" />
              <div>
                <p className="text-sm font-medium text-gray-900">File Size</p>
                <p className="text-sm text-gray-600">{formatFileSize(document.size)}</p>
              </div>
            </div>

            <div className="flex items-center space-x-3">
              <DocumentIcon className="h-5 w-5 text-gray-400" />
              <div>
                <p className="text-sm font-medium text-gray-900">File Type</p>
                <p className="text-sm text-gray-600 capitalize">{document.type}</p>
              </div>
            </div>

            <div className="flex items-center space-x-3">
              <CalendarIcon className="h-5 w-5 text-gray-400" />
              <div>
                <p className="text-sm font-medium text-gray-900">Upload Date</p>
                <p className="text-sm text-gray-600">{formatDate(document.uploadDate)}</p>
              </div>
            </div>
          </div>
        </div>

        <div className="space-y-4">
          <h4 className="text-lg font-semibold text-gray-900">Upload Information</h4>
          
          <div className="space-y-3">
            <div className="flex items-center space-x-3">
              <UserIcon className="h-5 w-5 text-gray-400" />
              <div>
                <p className="text-sm font-medium text-gray-900">Uploaded By</p>
                <p className="text-sm text-gray-600">{document.uploadedBy.name}</p>
                <p className="text-xs text-gray-500">{document.uploadedBy.email}</p>
              </div>
            </div>

            {document.businessName && (
              <div className="flex items-center space-x-3">
                <BuildingOfficeIcon className="h-5 w-5 text-gray-400" />
                <div>
                  <p className="text-sm font-medium text-gray-900">Business</p>
                  <p className="text-sm text-gray-600">{document.businessName}</p>
                </div>
              </div>
            )}

            <div className="flex items-center space-x-3">
              <FolderIcon className="h-5 w-5 text-gray-400" />
              <div>
                <p className="text-sm font-medium text-gray-900">Category</p>
                <p className="text-sm text-gray-600">{categoryInfo.name}</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Category Description */}
      <div className={`p-4 rounded-lg ${categoryInfo.bgColor} ${categoryInfo.borderColor} border`}>
        <div className="flex items-start space-x-3">
          <InformationCircleIcon className={`h-5 w-5 ${categoryInfo.textColor} mt-0.5`} />
          <div>
            <h5 className={`text-sm font-medium ${categoryInfo.textColor}`}>About this document type</h5>
            <p className={`text-sm ${categoryInfo.textColor} opacity-80 mt-1`}>
              {categoryInfo.description}
            </p>
          </div>
        </div>
      </div>

      {/* File Path Information */}
      <div className="space-y-4">
        <h4 className="text-lg font-semibold text-gray-900">File Information</h4>
        <div className="bg-gray-50 p-4 rounded-lg">
          <div className="space-y-2">
            <div>
              <p className="text-sm font-medium text-gray-900">Document ID</p>
              <p className="text-sm text-gray-600 font-mono">{document.id}</p>
            </div>
            <div>
              <p className="text-sm font-medium text-gray-900">File URL</p>
              <p className="text-sm text-gray-600 font-mono break-all">{document.url}</p>
            </div>
            {document.providerId && (
              <div>
                <p className="text-sm font-medium text-gray-900">Provider ID</p>
                <p className="text-sm text-gray-600 font-mono">{document.providerId}</p>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}